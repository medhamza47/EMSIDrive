package ma.emsi.emsidrive.schedule.service;

import java.sql.Date;
import java.sql.Time;
import java.time.*;
import java.util.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplace;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Campus;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Kind;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ScheduleService {
    static final ZoneId ZONE = ZoneId.of("Africa/Casablanca");
    private final JdbcTemplate jdbc;
    private final RideMarketplace marketplace;
    public ScheduleService(JdbcTemplate jdbc, RideMarketplace marketplace) {
        this.jdbc = jdbc; this.marketplace = marketplace;
    }

    @Transactional(readOnly = true, isolation = org.springframework.transaction.annotation.Isolation.REPEATABLE_READ)
    public ScheduleResponse current(UUID user) {
        var rows = jdbc.queryForList("SELECT * FROM schedules WHERE user_id = ? AND active", user);
        if (rows.isEmpty()) throw ApiException.notFound("SCHEDULE_NOT_FOUND", "No confirmed timetable");
        var row = rows.get(0);
        UUID id = (UUID) row.get("id");
        var slots = jdbc.query("SELECT * FROM schedule_slots WHERE schedule_id = ? ORDER BY weekday, start_time, id",
                (rs, i) -> new Slot(rs.getString("label"), rs.getString("location"), rs.getInt("weekday"),
                        rs.getTime("start_time").toLocalTime(), rs.getTime("end_time").toLocalTime(),
                        Campus.valueOf(rs.getString("campus"))), id);
        return new ScheduleResponse(id, (String) row.get("name"), ScheduleSource.valueOf((String) row.get("source")),
                ((Date) row.get("valid_from")).toLocalDate(), ((Date) row.get("valid_until")).toLocalDate(),
                ((Number) row.get("revision")).intValue(), slots);
    }

    @Transactional
    public ScheduleResponse save(UUID user, SaveRequest request) {
        validate(request);
        lockUser(user);
        var existing = jdbc.queryForList("SELECT id, revision FROM schedules WHERE user_id = ? AND active", user);
        int revision = existing.isEmpty() ? 0 : ((Number) existing.get(0).get("revision")).intValue();
        if (revision != request.revision()) throw ApiException.conflict("SCHEDULE_CHANGED", "Reload the current timetable before saving");
        UUID id = existing.isEmpty() ? UUID.randomUUID() : (UUID) existing.get(0).get("id");
        if (existing.isEmpty()) {
            jdbc.update("""
                    INSERT INTO schedules (id, user_id, name, source, valid_from, valid_until, revision, active)
                    VALUES (?, ?, ?, ?, ?, ?, 1, TRUE)
                    """, id, user, request.name().strip(), request.source().name(), request.validFrom(), request.validUntil());
        } else {
            jdbc.update("""
                    UPDATE schedules SET name = ?, source = ?, valid_from = ?, valid_until = ?,
                    revision = revision + 1, updated_at = now() WHERE id = ?
                    """, request.name().strip(), request.source().name(), request.validFrom(), request.validUntil(), id);
            jdbc.update("DELETE FROM schedule_slots WHERE schedule_id = ?", id);
        }
        for (Slot slot : request.slots()) {
            jdbc.update("""
                    INSERT INTO schedule_slots (schedule_id, label, location, weekday, start_time, end_time, campus)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, id, slot.label().strip(), slot.location(), slot.weekday(), Time.valueOf(slot.startTime()),
                    Time.valueOf(slot.endTime()), slot.campus().name());
        }
        return current(user);
    }

    static void validate(SaveRequest request) {
        if (!Boolean.TRUE.equals(request.confirmed())) throw ApiException.badRequest("SCHEDULE_CONFIRM_REQUIRED", "Confirm the extracted timetable");
        if (request.validUntil().isBefore(request.validFrom())
                || request.validUntil().isAfter(request.validFrom().plusYears(1))) {
            throw ApiException.badRequest("SCHEDULE_DATES_INVALID", "Validity must be ordered and no longer than one year");
        }
        var sorted = request.slots().stream().sorted(Comparator.comparing(Slot::weekday).thenComparing(Slot::startTime)).toList();
        Slot previous = null;
        for (Slot slot : sorted) {
            if (!slot.endTime().isAfter(slot.startTime()) || slot.startTime().getSecond() != 0 || slot.endTime().getSecond() != 0
                    || slot.startTime().getNano() != 0 || slot.endTime().getNano() != 0) {
                throw ApiException.badRequest("SCHEDULE_TIMES_INVALID", "Course times must be ordered and use whole minutes");
            }
            if (previous != null && previous.weekday().equals(slot.weekday()) && slot.startTime().isBefore(previous.endTime())) {
                throw ApiException.badRequest("SCHEDULE_OVERLAP", "Courses overlap on the same day");
            }
            previous = slot;
        }
    }

    @Transactional
    public void delete(UUID user) {
        lockUser(user);
        jdbc.update("DELETE FROM schedules WHERE user_id = ?", user);
    }

    private void lockUser(UUID user) {
        if (jdbc.queryForList("SELECT id FROM users WHERE id = ? FOR UPDATE", user).isEmpty()) {
            throw ApiException.notFound("USER_NOT_FOUND", "User not found");
        }
    }

    @Transactional(readOnly = true, isolation = org.springframework.transaction.annotation.Isolation.REPEATABLE_READ)
    public List<Suggestion> suggestions(UUID user, int commuteMinutes, int marginMinutes) {
        var schedule = current(user);
        var now = Instant.now();
        var candidates = jdbc.queryForList("""
                SELECT o.id, o.departure_time, o.origin_label, o.destination_label
                FROM ride_offers o JOIN users u ON u.id = o.driver_id
                WHERE o.marketplace AND o.status = 'OPEN' AND o.available_seats > 0
                  AND u.enabled AND o.driver_id <> ? AND o.departure_time > ? AND o.departure_time < ?
                  AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.ride_offer_id = o.id
                    AND b.passenger_id = ? AND b.status = 'CONFIRMED')
                ORDER BY o.departure_time, o.id
                """, user, OffsetDateTime.ofInstant(now, ZoneOffset.UTC),
                OffsetDateTime.ofInstant(now.plus(Duration.ofDays(7)), ZoneOffset.UTC), user);
        var result = new ArrayList<Suggestion>();
        for (var row : candidates) {
            Instant instant = ((java.sql.Timestamp) row.get("departure_time")).toInstant();
            var departure = instant.atZone(ZONE);
            LocalDate date = departure.toLocalDate();
            if (date.isBefore(schedule.validFrom()) || date.isAfter(schedule.validUntil())) continue;
            var day = schedule.slots().stream().filter(s -> s.weekday() == date.getDayOfWeek().getValue())
                    .sorted(Comparator.comparing(Slot::startTime)).toList();
            if (day.isEmpty()) continue;
            Slot first = day.get(0), last = day.get(day.size() - 1);
            boolean toCampus = campusLabel(first.campus()).equals(row.get("destination_label"));
            boolean fromCampus = campusLabel(last.campus()).equals(row.get("origin_label"));
            if (!toCampus && !fromCampus) continue;
            LocalTime course = toCampus ? first.startTime() : last.endTime();
            long gap = Duration.between(departure, date.atTime(course).atZone(ZONE)).toMinutes();
            if (!matches(toCampus, gap, commuteMinutes, marginMinutes)) continue;
            result.add(new Suggestion(marketplace.listing(user, Kind.OFFER, (UUID) row.get("id")), date,
                    toCampus, course, (int) gap));
            if (result.size() == 50) break;
        }
        return result;
    }

    static boolean matches(boolean toCampus, long gap, int commute, int margin) {
        // Outbound uses the student's travel estimate, not a claimed routing ETA.
        return toCampus ? gap >= commute + margin && gap <= commute + margin + 60 : gap <= 0 && gap >= -60;
    }
    private String campusLabel(Campus campus) { return "EMSI Marrakech " + (campus == Campus.TARGA ? "Targa" : "Centre"); }
}
