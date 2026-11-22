package ma.emsi.emsidrive.admin;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Kind;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReportService {
    private final JdbcTemplate jdbc;
    public ReportService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional
    public Map<String, Object> submit(UUID reporter, UUID submission, ReportController.ReportInput input) {
        UUID target;
        UUID offer = null, request = null;
        if (input.bookingId() != null && input.listingId() == null && input.kind() == null) {
            var rows = jdbc.queryForList("""
                    SELECT o.driver_id, b.passenger_id, o.id AS offer FROM bookings b
                    JOIN ride_offers o ON o.id = b.ride_offer_id
                    WHERE b.id = ? AND (o.driver_id = ? OR b.passenger_id = ?)
                    """, input.bookingId(), reporter, reporter);
            if (rows.isEmpty()) throw ApiException.notFound("TRIP_NOT_FOUND", "Trip not found");
            var row = rows.get(0);
            target = (UUID) row.get(reporter.equals(row.get("driver_id")) ? "passenger_id" : "driver_id");
            offer = (UUID) row.get("offer");
        } else if (input.bookingId() == null && input.listingId() != null && input.kind() != null) {
            boolean isOffer = input.kind() == Kind.OFFER;
            String table = isOffer ? "ride_offers" : "ride_requests";
            String owner = isOffer ? "driver_id" : "passenger_id";
            var rows = jdbc.queryForList("SELECT " + owner + " AS owner FROM " + table + " WHERE id = ? AND marketplace", input.listingId());
            if (rows.isEmpty()) throw ApiException.notFound("LISTING_NOT_FOUND", "Listing not found");
            target = (UUID) rows.get(0).get("owner");
            if (isOffer) offer = input.listingId(); else request = input.listingId();
        } else throw ApiException.badRequest("REPORT_CONTEXT_REQUIRED", "Choose a trip or a listing");
        if (target.equals(reporter)) throw ApiException.badRequest("SELF_REPORT", "You cannot report yourself");
        jdbc.update("""
                INSERT INTO reports(reporter_id, reported_user_id, ride_offer_id, ride_request_id, booking_id,
                                    category, description, submission_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (reporter_id, submission_id) DO NOTHING
                """, reporter, target, offer, request, input.bookingId(), input.category().name(), input.description().strip(), submission);
        var row = jdbc.queryForMap("SELECT * FROM reports WHERE reporter_id = ? AND submission_id = ?", reporter, submission);
        if (!Objects.equals(row.get("booking_id"), input.bookingId()) || !Objects.equals(row.get("ride_offer_id"), offer)
                || !Objects.equals(row.get("ride_request_id"), request) || !row.get("category").equals(input.category().name())
                || !row.get("description").equals(input.description().strip()))
            throw ApiException.conflict("REPORT_ALREADY_SUBMITTED", "This submission was already used");
        return Map.of("id", row.get("id"), "status", row.get("status"));
    }

    public List<Map<String, Object>> mine(UUID user) {
        // Moderator notes and reporter identities are never disclosed to another student.
        return jdbc.queryForList("""
                SELECT id, category, status, extract(epoch from created_at)*1000 AS created
                FROM reports WHERE reporter_id = ? ORDER BY created_at DESC, id LIMIT 100
                """, user);
    }
}
