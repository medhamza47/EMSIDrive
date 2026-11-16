package ma.emsi.emsidrive.ride.marketplace;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Kind;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.ListingInput;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Point;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Vehicle;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.TripState;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.LiveLocation;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RideMarketplace {
    private static final String TRIP_COLUMNS = """
            b.id, b.ride_offer_id, b.ride_request_id, b.passenger_id, o.driver_id, o.driver_id = ? AS is_driver,
            CASE WHEN b.passenger_id = ? THEN driver.full_name ELSE passenger.full_name END AS partner,
            CASE WHEN b.status='CONFIRMED' THEN
                CASE WHEN o.driver_id = ? THEN passenger.phone_number ELSE driver.phone_number END
                END AS partner_phone,
            o.origin_label, o.destination_label, o.origin_latitude, o.origin_longitude,
            o.destination_latitude, o.destination_longitude,
            extract(epoch FROM o.departure_time) * 1000 AS departure,
            b.tracking_state, extract(epoch FROM b.tracking_updated_at)*1000 AS state_updated_at,
            extract(epoch FROM b.live_captured_at)*1000 AS live_updated_at,
            b.live_accuracy, b.live_heading,
            CASE WHEN b.status='CONFIRMED' AND b.live_at > now() - interval '30 seconds'
                AND b.live_captured_at > now() - interval '30 seconds' THEN b.live_latitude END AS live_latitude,
            CASE WHEN b.status='CONFIRMED' AND b.live_at > now() - interval '30 seconds'
                AND b.live_captured_at > now() - interval '30 seconds' THEN b.live_longitude END AS live_longitude
            """;
    private static final String TRIP_FROM = """
            FROM bookings b JOIN ride_offers o ON o.id = b.ride_offer_id
            JOIN users driver ON driver.id = o.driver_id
            JOIN users passenger ON passenger.id = b.passenger_id
            WHERE o.marketplace AND b.status IN ('CONFIRMED','COMPLETED','CANCELLED')
              AND (o.driver_id = ? OR b.passenger_id = ?)
            """;

    private final JdbcTemplate jdbc;
    private final MarrakechArea area;

    public RideMarketplace(JdbcTemplate jdbc, MarrakechArea area) {
        this.jdbc = jdbc;
        this.area = area;
    }

    public UUID publish(UUID user, ListingInput input) {
        if (!area.contains(input.point())) {
            throw ApiException.badRequest("OUTSIDE_MARRAKECH", "City point is outside Marrakech");
        }
        if (input.vehicle() == Vehicle.MOTO && input.seats() != 1) {
            throw ApiException.badRequest("INVALID_SEAT_COUNT", "A motorcycle has one passenger seat");
        }
        String campus = "EMSI Marrakech " + switch (input.campus()) {
            case TARGA -> "Targa";
            case CENTRE -> "Centre";
        };
        Point campusPoint = switch (input.campus()) {
            case TARGA -> new Point(new BigDecimal("31.6529961"), new BigDecimal("-8.0603932"));
            case CENTRE -> new Point(new BigDecimal("31.6535903"), new BigDecimal("-8.0214513"));
        };
        Point origin = input.toCampus() ? input.point() : campusPoint;
        Point destination = input.toCampus() ? campusPoint : input.point();
        Kind kind = input.kind();
        return jdbc.queryForObject("""
                INSERT INTO %s (%s, origin_label, destination_label, origin_latitude, origin_longitude,
                    destination_latitude, destination_longitude, departure_time, %s,
                    vehicle_preference, notes, marketplace)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE) RETURNING id
                """.formatted(table(kind), owner(kind), seats(kind)), UUID.class, user,
                input.toCampus() ? "Marrakech" : campus, input.toCampus() ? campus : "Marrakech",
                origin.latitude(), origin.longitude(), destination.latitude(), destination.longitude(),
                input.departure(), input.seats(), input.vehicle().name(), input.notes());
    }

    public List<Map<String, Object>> listings(UUID user, Kind kind) {
        return jdbc.queryForList(listingQuery(kind) + """
                AND r.status = ? AND r.departure_time > now()
                AND r.%s > 0
                AND NOT EXISTS (SELECT 1 FROM bookings b
                    WHERE b.ride_offer_id = r.id AND b.passenger_id = ? AND b.status = 'CONFIRMED')
                ORDER BY r.departure_time, r.id LIMIT 100
                """.formatted(seats(kind)), user, user, openStatus(kind), user);
    }

    public Map<String, Object> listing(UUID user, Kind kind, UUID id) {
        return first(jdbc.queryForList(listingQuery(kind) + " AND r.id = ?", user, user, id));
    }

    private String listingQuery(Kind kind) {
        return """
                SELECT r.id, u.full_name AS author, r.%1$s = ? AS own, r.%2$s AS seats,
                    r.origin_label, r.destination_label, r.notes, r.vehicle_preference,
                    extract(epoch FROM r.departure_time) * 1000 AS departure,
                    CASE WHEN r.origin_label = 'Marrakech' THEN round(r.origin_latitude, 3)
                         ELSE r.origin_latitude END AS origin_latitude,
                    CASE WHEN r.origin_label = 'Marrakech' THEN round(r.origin_longitude, 3)
                         ELSE r.origin_longitude END AS origin_longitude,
                    CASE WHEN r.destination_label = 'Marrakech' THEN round(r.destination_latitude, 3)
                         ELSE r.destination_latitude END AS destination_latitude,
                    CASE WHEN r.destination_label = 'Marrakech' THEN round(r.destination_longitude, 3)
                         ELSE r.destination_longitude END AS destination_longitude,
                    (r.%1$s <> ? AND r.status = '%3$s' AND r.%2$s > 0
                        AND r.departure_time > now()) AS can_accept
                FROM %4$s r JOIN users u ON u.id = r.%1$s WHERE r.marketplace
                """.formatted(owner(kind), seats(kind), openStatus(kind), table(kind));
    }

    @Transactional
    public UUID accept(UUID user, Kind kind, UUID id) {
        var row = first(jdbc.queryForList("""
                SELECT %s AS owner, %s AS seats, status, departure_time > now() AS upcoming
                FROM %s WHERE id = ? AND marketplace FOR UPDATE
                """.formatted(owner(kind), seats(kind), table(kind)), id));
        UUID owner = (UUID) row.get("owner");
        if (user.equals(owner)) {
            throw ApiException.conflict("OWN_LISTING", "Cannot accept your own listing");
        }
        String existingQuery = kind == Kind.OFFER
                ? "SELECT id FROM bookings WHERE ride_offer_id = ? AND passenger_id = ? AND status = 'CONFIRMED'"
                : """
                  SELECT b.id FROM bookings b JOIN ride_offers o ON o.id = b.ride_offer_id
                  WHERE b.ride_request_id = ? AND o.driver_id = ? AND b.status = 'CONFIRMED'
                  """;
        var existing = jdbc.queryForList(existingQuery, UUID.class, id, user);
        if (!existing.isEmpty()) {
            return existing.get(0);
        }
        int available = ((Number) row.get("seats")).intValue();
        if (!openStatus(kind).equals(row.get("status")) || available < 1 || !Boolean.TRUE.equals(row.get("upcoming"))) {
            throw ApiException.conflict("LISTING_UNAVAILABLE", "Listing is no longer available");
        }

        UUID offer = id;
        UUID request = null;
        UUID passenger = user;
        int booked = 1;
        if (kind == Kind.REQUEST) {
            request = id;
            passenger = owner;
            booked = available;
            offer = jdbc.queryForObject("""
                    INSERT INTO ride_offers (driver_id, origin_label, origin_latitude, origin_longitude,
                        destination_label, destination_latitude, destination_longitude, departure_time,
                        available_seats, status, marketplace)
                    SELECT ?, origin_label, origin_latitude, origin_longitude, destination_label,
                        destination_latitude, destination_longitude, departure_time, 0, 'FULL', TRUE
                    FROM ride_requests WHERE id = ? RETURNING id
                    """, UUID.class, user, id);
            jdbc.update("UPDATE ride_requests SET status = 'MATCHED', updated_at = now() WHERE id = ?", id);
        } else {
            jdbc.update("""
                    UPDATE ride_offers SET available_seats = available_seats - 1, updated_at = now(),
                        status = CASE WHEN available_seats = 1 THEN 'FULL' ELSE 'OPEN' END
                    WHERE id = ?
                    """, id);
        }

        var inserted = jdbc.queryForList("""
                INSERT INTO bookings (ride_offer_id, passenger_id, ride_request_id, seats_booked, status)
                VALUES (?, ?, ?, ?, 'CONFIRMED')
                ON CONFLICT(ride_offer_id,passenger_id) DO UPDATE SET status='CONFIRMED',tracking_state='CONFIRMED',
                    tracking_updated_at=now(),booked_at=now(),cancelled_at=NULL,updated_at=now()
                WHERE bookings.status='CANCELLED' RETURNING id
                """, UUID.class, offer, passenger, request, booked);
        if (inserted.isEmpty()) throw ApiException.conflict("BOOKING_CLOSED", "This booking cannot be reopened");
        UUID booking = inserted.get(0);
        jdbc.update("""
                INSERT INTO notifications (user_id, type, title, body, reference_type, reference_id)
                SELECT ?, 'BOOKING', ?, full_name, 'BOOKING', ? FROM users WHERE id = ?
                """, owner, kind == Kind.REQUEST ? "REQUEST_ACCEPTED" : "OFFER_ACCEPTED", booking, user);
        notify(user, booking, "BOOKING_CONFIRMED", owner);
        return booking;
    }

    public List<Map<String, Object>> trips(UUID user) {
        return jdbc.queryForList("SELECT " + TRIP_COLUMNS + TRIP_FROM +
                " ORDER BY CASE WHEN b.status='CONFIRMED' THEN 0 ELSE 1 END, o.departure_time, b.id LIMIT 100", user, user, user, user, user);
    }

    public Map<String, Object> trip(UUID user, UUID id) {
        return first(jdbc.queryForList("SELECT " + TRIP_COLUMNS + TRIP_FROM + " AND b.id = ?",
                user, user, user, user, user, id));
    }

    public List<Map<String, Object>> messages(UUID user, UUID id, long after) {
        trip(user, id);
        if (after <= 0) {
            return jdbc.queryForList("""
                    SELECT * FROM (SELECT id, body, sender_id = ? AS mine,
                        extract(epoch FROM created_at) * 1000 AS sent
                        FROM ride_messages WHERE booking_id = ? ORDER BY id DESC LIMIT 100) recent
                    ORDER BY id
                    """, user, id);
        }
        return jdbc.queryForList("""
                SELECT id, body, sender_id = ? AS mine, extract(epoch FROM created_at) * 1000 AS sent
                FROM ride_messages WHERE booking_id = ? AND id > ? ORDER BY id LIMIT 100
                """, user, id, after);
    }

    @Transactional
    public void send(UUID user, UUID id, String body) {
        first(jdbc.queryForList("SELECT b.id " + TRIP_FROM + " AND b.id = ? FOR UPDATE OF b", user, user, id));
        jdbc.update("INSERT INTO ride_messages (booking_id, sender_id, body) VALUES (?, ?, ?)",
                id, user, body.strip());
        var ride = trip(user, id);
        notify((UUID) ride.get(Boolean.TRUE.equals(ride.get("is_driver")) ? "passenger_id" : "driver_id"),
                id, "RIDE_MESSAGE", user);
    }

    public void location(UUID user, UUID id, LiveLocation point) {
        var ride = trip(user, id);
        if (!Boolean.TRUE.equals(ride.get("is_driver"))) {
            throw ApiException.forbidden("DRIVER_REQUIRED", "Only the driver can share a location");
        }
        if (point == null) {
            jdbc.update("UPDATE bookings SET live_latitude=NULL,live_longitude=NULL,live_at=NULL,live_captured_at=NULL,live_accuracy=NULL,live_heading=NULL WHERE ride_offer_id=?", ride.get("ride_offer_id"));
        } else {
            var now = Instant.now();
            if (point.capturedAt().isBefore(now.minusSeconds(30)) || point.capturedAt().isAfter(now.plusSeconds(10)))
                throw ApiException.badRequest("LOCATION_STALE", "A recent GPS fix is required");
            if (java.util.Set.of("COMPLETED", "CANCELLED").contains(ride.get("tracking_state")))
                throw ApiException.conflict("TRIP_CLOSED", "Trip is no longer active");
            jdbc.update("""
                    UPDATE bookings SET live_latitude=?,live_longitude=?,live_at=now(),live_captured_at=?,live_accuracy=?,live_heading=?
                    WHERE ride_offer_id=? AND status='CONFIRMED' AND (live_captured_at IS NULL OR live_captured_at<=?)
                    """, point.latitude(), point.longitude(), java.sql.Timestamp.from(point.capturedAt()), point.accuracy(), point.heading(),
                    ride.get("ride_offer_id"), java.sql.Timestamp.from(point.capturedAt()));
        }
    }

    @Transactional
    public Map<String, Object> transition(UUID user, UUID id, TripState next) {
        var initial = trip(user, id);
        jdbc.queryForObject("SELECT id FROM ride_offers WHERE id=? FOR UPDATE", UUID.class, initial.get("ride_offer_id"));
        var locked = first(jdbc.queryForList("SELECT * FROM bookings WHERE id=? FOR UPDATE", id));
        TripState current = TripState.valueOf((String) locked.get("tracking_state"));
        if (next == current) return trip(user, id);
        boolean driver = Boolean.TRUE.equals(initial.get("is_driver"));
        if (!driver && next != TripState.CANCELLED) throw ApiException.forbidden("DRIVER_REQUIRED", "Only the driver updates trip progress");
        boolean allowed = switch (current) {
            case CONFIRMED -> next == TripState.EN_ROUTE || next == TripState.CANCELLED;
            case EN_ROUTE -> next == TripState.ARRIVED || next == TripState.CANCELLED;
            case ARRIVED -> next == TripState.IN_PROGRESS || next == TripState.CANCELLED;
            case IN_PROGRESS -> next == TripState.COMPLETED;
            default -> false;
        };
        if (!allowed) throw ApiException.conflict("TRIP_STATE_INVALID", "Invalid trip transition");
        boolean terminal = next == TripState.COMPLETED || next == TripState.CANCELLED;
        jdbc.update("UPDATE bookings SET tracking_state=?,tracking_updated_at=now(),status=?,updated_at=now(),cancelled_at=CASE WHEN ? THEN now() ELSE cancelled_at END WHERE id=?",
                next.name(), terminal ? next.name() : "CONFIRMED", next == TripState.CANCELLED, id);
        if (terminal) jdbc.update("UPDATE bookings SET live_latitude=NULL,live_longitude=NULL,live_at=NULL,live_captured_at=NULL,live_accuracy=NULL,live_heading=NULL WHERE id=?", id);
        if (next == TripState.CANCELLED) {
            if (locked.get("ride_request_id") == null) {
                jdbc.update("UPDATE ride_offers SET available_seats=available_seats+?,status=CASE WHEN status='FULL' THEN 'OPEN' ELSE status END,updated_at=now() WHERE id=?",
                        locked.get("seats_booked"), locked.get("ride_offer_id"));
            } else {
                jdbc.update("UPDATE ride_offers SET status='CANCELLED' WHERE id=?", locked.get("ride_offer_id"));
                jdbc.update("UPDATE ride_requests SET status='PENDING' WHERE id=?", locked.get("ride_request_id"));
            }
        }
        UUID recipient = (UUID) initial.get(driver ? "passenger_id" : "driver_id");
        notify(recipient, id, "RIDE_" + next.name(), user);
        if (driver) {
            // A shared offer has one physical journey: keep its passengers in sync.
            var others = jdbc.queryForList("SELECT id FROM bookings WHERE ride_offer_id=? AND id<>? AND status='CONFIRMED' AND tracking_state<>?",
                    UUID.class, locked.get("ride_offer_id"), id, next.name());
            for (UUID other : others) transition(user, other, next);
            if (next == TripState.EN_ROUTE || next == TripState.COMPLETED || next == TripState.CANCELLED) {
                jdbc.update("UPDATE ride_offers SET status=?,updated_at=now() WHERE id=?",
                        next == TripState.EN_ROUTE ? "ONGOING" : next.name(), locked.get("ride_offer_id"));
            }
        }
        return trip(user, id);
    }

    private void notify(UUID recipient, UUID booking, String title, UUID actor) {
        jdbc.update("""
                INSERT INTO notifications(user_id,type,title,body,reference_type,reference_id)
                SELECT ?,'RIDE_UPDATE',?,full_name,'BOOKING',? FROM users WHERE id=?
                """, recipient, title, booking, actor);
    }

    public List<Map<String, Object>> notifications(UUID user) {
        return jdbc.queryForList("""
                SELECT id, title, body, reference_id AS booking_id, read_at IS NOT NULL AS seen,
                    extract(epoch FROM created_at)*1000 AS created_at
                FROM notifications WHERE user_id = ? AND reference_type = 'BOOKING'
                    AND title IN ('REQUEST_ACCEPTED','OFFER_ACCEPTED','BOOKING_CONFIRMED','RIDE_EN_ROUTE','RIDE_ARRIVED',
                        'RIDE_IN_PROGRESS','RIDE_COMPLETED','RIDE_CANCELLED','RIDE_MESSAGE')
                ORDER BY created_at DESC LIMIT 100
                """, user);
    }

    public void read(UUID user, UUID id) {
        jdbc.update("UPDATE notifications SET read_at = now() WHERE user_id = ? AND id = ? AND read_at IS NULL", user, id);
    }

    private static Map<String, Object> first(List<Map<String, Object>> rows) {
        if (rows.isEmpty()) {
            throw ApiException.notFound("RIDE_NOT_FOUND", "Ride not found");
        }
        return rows.get(0);
    }

    private static String table(Kind kind) {
        return kind == Kind.OFFER ? "ride_offers" : "ride_requests";
    }

    private static String owner(Kind kind) {
        return kind == Kind.OFFER ? "driver_id" : "passenger_id";
    }

    private static String seats(Kind kind) {
        return kind == Kind.OFFER ? "available_seats" : "seats_needed";
    }

    private static String openStatus(Kind kind) {
        return kind == Kind.OFFER ? "OPEN" : "PENDING";
    }
}
