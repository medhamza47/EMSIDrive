package ma.emsi.emsidrive.admin;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.admin.entity.ReportStatus;
import ma.emsi.emsidrive.common.exception.ApiException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ModerationService {
    private final JdbcTemplate jdbc;
    private static final int PAGE_SIZE = 20;
    private static final String USER_FIELDS = "id, email, full_name, role, enabled, updated_at::text AS revision, "
            + "extract(epoch from created_at)*1000 AS created";
    private static final String RIDES = """
            (SELECT o.id, 'OFFER' AS kind, u.full_name AS author, o.origin_label, o.destination_label,
                    o.departure_time, o.status, o.available_seats AS seats
             FROM ride_offers o JOIN users u ON u.id = o.driver_id
             UNION ALL
             SELECT r.id, 'REQUEST' AS kind, u.full_name AS author, r.origin_label, r.destination_label,
                    r.departure_time, r.status, r.seats_needed AS seats
             FROM ride_requests r JOIN users u ON u.id = r.passenger_id) rides
            """;

    public ModerationService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> dashboard() {
        return jdbc.queryForMap("""
                SELECT (SELECT count(*) FROM users WHERE role = 'STUDENT') AS users,
                       (SELECT count(*) FROM users WHERE NOT enabled) AS suspended,
                       (SELECT count(*) FROM ride_offers) AS offers,
                       (SELECT count(*) FROM ride_requests) AS requests,
                       (SELECT count(*) FROM bookings) AS bookings,
                       (SELECT count(*) FROM ride_offers WHERE status = 'COMPLETED') AS completed,
                       (SELECT count(*) FROM reports WHERE status IN ('OPEN','UNDER_REVIEW')) AS reports
                """);
    }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> users(String search, Boolean enabled, int page) {
        if (search.length() > 180) throw ApiException.badRequest("INVALID_SEARCH", "Search is too long");
        var args = new ArrayList<Object>();
        args.add(search.strip()); args.add(search.strip());
        String where = " WHERE (position(lower(?) in lower(full_name)) > 0 OR position(lower(?) in lower(email)) > 0)";
        if (enabled != null) { where += " AND enabled = ?"; args.add(enabled); }
        return page("SELECT " + USER_FIELDS + " FROM users" + where,
                "SELECT count(*) FROM users" + where, "created DESC, id", args, page);
    }

    public Map<String, Object> user(UUID id) {
        var result = jdbc.queryForList("SELECT " + USER_FIELDS + " FROM users WHERE id = ?", id);
        if (result.isEmpty()) throw ApiException.notFound("USER_NOT_FOUND", "Account not found");
        var user = result.get(0);
        user.putAll(jdbc.queryForMap("""
                SELECT (SELECT count(*) FROM ride_offers WHERE driver_id = ?) AS offers,
                       (SELECT count(*) FROM ride_requests WHERE passenger_id = ?) AS requests,
                       (SELECT count(*) FROM reports WHERE reported_user_id = ?) AS reports
                """, id, id, id));
        return user;
    }

    @Transactional
    public void access(UUID actor, UUID id, ModerationController.AccountDecision input) {
        var rows = jdbc.queryForList("SELECT role, enabled, updated_at::text AS revision FROM users WHERE id = ? FOR UPDATE", id);
        if (rows.isEmpty()) throw ApiException.notFound("USER_NOT_FOUND", "Account not found");
        var user = rows.get(0);
        if (actor.equals(id) || "ADMIN".equals(user.get("role")))
            throw ApiException.forbidden("ADMIN_PROTECTED", "Administrator accounts cannot be suspended here");
        if (!input.revision().equals(user.get("revision"))) throw stale();
        if (input.enabled().equals(user.get("enabled"))) return;
        jdbc.update("""
                UPDATE users SET enabled = ?, updated_at = clock_timestamp(),
                access_invalidated_at = CASE WHEN ? THEN access_invalidated_at ELSE clock_timestamp() END WHERE id = ?
                """, input.enabled(), input.enabled(), id);
        if (!input.enabled()) {
            jdbc.update("UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = ? AND revoked_at IS NULL", id);
            jdbc.update("UPDATE biometric_devices SET revoked_at = now() WHERE user_id = ? AND revoked_at IS NULL", id);
            jdbc.update("DELETE FROM push_devices WHERE user_id = ?", id);
        }
        audit(actor, input.enabled() ? "ACCOUNT_REACTIVATED" : "ACCOUNT_SUSPENDED", id, input.reason().strip());
    }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> rides(String kind, String status, String campus, LocalDate date, int page) {
        if (!List.of("", "OFFER", "REQUEST").contains(kind) || !List.of("", "TARGA", "CENTRE").contains(campus)
                || !List.of("", "OPEN", "FULL", "ONGOING", "COMPLETED", "CANCELLED", "PENDING", "MATCHED", "EXPIRED").contains(status))
            throw ApiException.badRequest("INVALID_FILTER", "Invalid ride filter");
        var args = new ArrayList<Object>();
        String where = " WHERE true";
        if (!kind.isEmpty()) { where += " AND kind = ?"; args.add(kind); }
        if (!status.isEmpty()) { where += " AND status = ?"; args.add(status); }
        if (!campus.isEmpty()) {
            where += " AND (origin_label = ? OR destination_label = ?)";
            String label = campus.equals("TARGA") ? "EMSI Marrakech Targa" : "EMSI Marrakech Centre";
            args.add(label); args.add(label);
        }
        if (date != null) {
            where += " AND (departure_time AT TIME ZONE 'Africa/Casablanca')::date = ?"; args.add(date);
        }
        return page("SELECT id, kind, author, origin_label, destination_label, status, seats, "
                        + "extract(epoch from departure_time)*1000 AS departure FROM " + RIDES + where,
                "SELECT count(*) FROM " + RIDES + where, "departure DESC, id", args, page);
    }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> reports(ReportStatus status, int page) {
        String where = status == null ? "" : " WHERE r.status = ?";
        var args = new ArrayList<Object>();
        if (status != null) args.add(status.name());
        return page("""
                SELECT r.id, r.category, r.description, r.status, r.revision, r.resolution_note,
                       r.reported_user_id, r.booking_id, r.ride_offer_id, r.ride_request_id,
                       extract(epoch from r.created_at)*1000 AS created,
                       reporter.full_name AS reporter, target.full_name AS reported_user
                FROM reports r JOIN users reporter ON reporter.id = r.reporter_id
                LEFT JOIN users target ON target.id = r.reported_user_id
                """ + where, "SELECT count(*) FROM reports r" + where, "created DESC, id", args, page);
    }

    @Transactional
    public void resolve(UUID actor, UUID id, ModerationController.ReportDecision input) {
        var rows = jdbc.queryForList("SELECT revision, reporter_id, reported_user_id FROM reports WHERE id = ? FOR UPDATE", id);
        if (rows.isEmpty()) throw ApiException.notFound("REPORT_NOT_FOUND", "Report not found");
        var row = rows.get(0);
        if (actor.equals(row.get("reporter_id")) || actor.equals(row.get("reported_user_id")))
            throw ApiException.forbidden("REPORT_CONFLICT", "Another administrator must review this report");
        if (input.revision() != ((Number) row.get("revision")).intValue()) throw stale();
        boolean closed = input.status() == ReportStatus.RESOLVED || input.status() == ReportStatus.DISMISSED;
        jdbc.update("""
                UPDATE reports SET status = ?, resolution_note = ?, revision = revision + 1,
                    resolved_at = CASE WHEN ? THEN now() ELSE NULL END, updated_at = now() WHERE id = ?
                """, input.status().name(), input.reason().strip(), closed, id);
        audit(actor, "REPORT_" + input.status().name(), id, input.reason().strip());
    }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> audit(int page) {
        return page("""
                SELECT a.id, u.full_name AS actor, a.action, a.target_id, a.reason,
                       extract(epoch from a.created_at)*1000 AS created
                FROM admin_actions a JOIN users u ON u.id = a.actor_id
                """, "SELECT count(*) FROM admin_actions", "created DESC, id DESC", List.of(), page);
    }

    private Map<String, Object> page(String select, String count, String order, List<Object> args, int page) {
        if (page < 0 || page > 100000) throw ApiException.badRequest("INVALID_PAGE", "Invalid page");
        Long total = jdbc.queryForObject(count, Long.class, args.toArray());
        var values = new ArrayList<>(args);
        values.add(PAGE_SIZE); values.add(page * PAGE_SIZE);
        return Map.of("items", jdbc.queryForList(select + " ORDER BY " + order + " LIMIT ? OFFSET ?", values.toArray()),
                "total", total, "page", page, "size", PAGE_SIZE);
    }

    private void audit(UUID actor, String action, UUID target, String reason) {
        jdbc.update("INSERT INTO admin_actions(actor_id, action, target_id, reason) VALUES (?, ?, ?, ?)", actor, action, target, reason);
    }

    private ApiException stale() { return ApiException.conflict("STALE_REVISION", "This item changed. Reload before trying again"); }
}
