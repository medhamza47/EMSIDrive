package ma.emsi.emsidrive.schedule.service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.ride.marketplace.MarrakechArea;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.*;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Explicit, repeatable development fixtures that use the real booking flow. */
@Service
@Profile("dev")
public class DemoRideService {
    private final JdbcTemplate jdbc;
    private final ScheduleService schedules;
    private final ScheduleMatchingService matching;
    private final MarrakechArea area;
    private final PasswordEncoder passwords;

    public DemoRideService(JdbcTemplate jdbc, ScheduleService schedules, ScheduleMatchingService matching,
                           MarrakechArea area, PasswordEncoder passwords) {
        this.jdbc = jdbc; this.schedules = schedules; this.matching = matching; this.area = area; this.passwords = passwords;
    }

    @Transactional
    public List<UUID> seed(UUID owner) {
        jdbc.queryForObject("SELECT id FROM users WHERE id=? FOR UPDATE", UUID.class, owner);
        var schedule = schedules.current(owner);
        var preferences = matching.preferences(owner);
        if (preferences == null) throw ApiException.badRequest("SCHEDULE_TRAVEL_REQUIRED", "Choose a city point first");
        var now = ZonedDateTime.now(ScheduleService.ZONE);
        ZonedDateTime departure = null;
        boolean toCampus = true;
        for (int offset = 0; offset < 7 && departure == null; offset++) {
            var date = now.toLocalDate().plusDays(offset);
            if (date.isBefore(schedule.validFrom()) || date.isAfter(schedule.validUntil())) continue;
            var slots = schedule.slots().stream().filter(s -> s.weekday() == date.getDayOfWeek().getValue()).toList();
            if (slots.isEmpty()) continue;
            var arrival = slots.stream().map(s -> s.startTime()).min(Comparator.naturalOrder()).orElseThrow();
            var leaving = slots.stream().map(s -> s.endTime()).max(Comparator.naturalOrder()).orElseThrow();
            var outbound = date.atTime(arrival).atZone(ScheduleService.ZONE)
                    .minusMinutes(preferences.commuteMinutes() + preferences.marginMinutes() + 10);
            if (outbound.toLocalDate().equals(date) && outbound.isAfter(now.plusMinutes(5))) {
                departure = outbound;
            } else {
                var inbound = date.atTime(leaving).atZone(ScheduleService.ZONE).plusMinutes(10);
                if (inbound.toLocalDate().equals(date) && inbound.isAfter(now.plusMinutes(5))) { departure = inbound; toCampus = false; }
            }
        }
        if (departure == null) throw ApiException.badRequest("SCHEDULE_DEMO_NO_DAY", "No upcoming attendance day in the next seven days");
        var campusPoint = preferences.campus() == Campus.TARGA ? new Point(new BigDecimal("31.6529961"), new BigDecimal("-8.0603932"))
                : new Point(new BigDecimal("31.6535903"), new BigDecimal("-8.0214513"));
        String campus = "EMSI Marrakech " + (preferences.campus() == Campus.TARGA ? "Targa" : "Centre");
        String[] names = {"Amine · TEST", "Salma · TEST", "Yassine · TEST"};
        var ids = new ArrayList<UUID>();
        for (int index = 0; index < 3; index++) {
            UUID driver = id("driver", owner, index), offer = id("offer", owner, index);
            jdbc.update("""
                    INSERT INTO users(id,email,password_hash,full_name,role,enabled) VALUES (?,?,?,?,'STUDENT',true)
                    ON CONFLICT(id) DO NOTHING
                    """, driver, "demo-" + driver + "@example.invalid", passwords.encode(UUID.randomUUID().toString()), names[index]);
            double radius = Math.min(350, preferences.radiusMeters() * .35);
            double angle = index * 2 * Math.PI / 3;
            var point = new Point(BigDecimal.valueOf(preferences.point().latitude().doubleValue() + Math.cos(angle) * radius / 111000),
                    BigDecimal.valueOf(preferences.point().longitude().doubleValue() + Math.sin(angle) * radius / 94500));
            if (!area.contains(point)) point = preferences.point();
            var origin = toCampus ? point : campusPoint;
            var destination = toCampus ? campusPoint : point;
            jdbc.update("""
                    INSERT INTO ride_offers(id,driver_id,origin_label,destination_label,origin_latitude,origin_longitude,
                        destination_latitude,destination_longitude,departure_time,available_seats,vehicle_preference,notes,marketplace)
                    VALUES (?,?,?,?,?,?,?,?,?,?, 'CAR','[TEST] Offre fictive pour tester la réservation.',true)
                    ON CONFLICT(id) DO UPDATE SET origin_label=excluded.origin_label,destination_label=excluded.destination_label,
                        origin_latitude=excluded.origin_latitude,origin_longitude=excluded.origin_longitude,
                        destination_latitude=excluded.destination_latitude,destination_longitude=excluded.destination_longitude,
                        departure_time=excluded.departure_time
                    WHERE NOT EXISTS(SELECT 1 FROM bookings b WHERE b.ride_offer_id=ride_offers.id)
                    """, offer, driver, toCampus ? "Marrakech" : campus, toCampus ? campus : "Marrakech",
                    origin.latitude(), origin.longitude(), destination.latitude(), destination.longitude(), departure.toOffsetDateTime(), index + 1);
            ids.add(offer);
        }
        return ids;
    }

    private UUID id(String kind, UUID owner, int index) {
        return UUID.nameUUIDFromBytes(("emsidrive-demo-" + kind + ":" + owner + ":" + index).getBytes(StandardCharsets.UTF_8));
    }
}
