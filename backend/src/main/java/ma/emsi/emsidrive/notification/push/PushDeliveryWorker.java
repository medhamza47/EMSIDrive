package ma.emsi.emsidrive.notification.push;

import java.util.UUID;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

@Component
@ConditionalOnProperty(name = "app.push.enabled", havingValue = "true")
public class PushDeliveryWorker {
    private final JdbcTemplate jdbc;
    private final TransactionTemplate transaction;
    private final PushSender sender;

    public PushDeliveryWorker(JdbcTemplate jdbc, PlatformTransactionManager manager, PushSender sender) {
        this.jdbc = jdbc;
        this.transaction = new TransactionTemplate(manager);
        this.sender = sender;
    }

    @Scheduled(fixedDelayString = "${app.push.poll-ms:5000}")
    public void dispatch() {
        // Bound retries and discard stale/account-switched deliveries.
        jdbc.update("""
                UPDATE push_deliveries q SET finished_at = now() FROM notifications n, push_devices d
                WHERE q.notification_id = n.id AND q.device_token = d.token AND q.finished_at IS NULL
                  AND (q.attempts >= 5 OR n.created_at < now() - interval '1 hour'
                    OR q.generation <> d.generation OR n.user_id <> d.user_id
                    OR n.read_at IS NOT NULL
                    OR NOT EXISTS (SELECT 1 FROM refresh_tokens r WHERE r.token_hash = d.session_hash
                        AND r.revoked_at IS NULL AND r.expires_at > now()))
                """);
        for (int i = 0; i < 5; i++) {
            Boolean sent = transaction.execute(status -> deliverOne());
            if (!Boolean.TRUE.equals(sent)) return;
        }
    }

    private boolean deliverOne() {
        var rows = jdbc.queryForList("""
                SELECT q.id, q.attempts, d.token, n.id AS notice, n.user_id, n.reference_id, n.title
                FROM push_deliveries q JOIN notifications n ON n.id = q.notification_id
                JOIN push_devices d ON d.token = q.device_token
                JOIN refresh_tokens r ON r.token_hash = d.session_hash
                WHERE q.finished_at IS NULL AND q.available_at <= now() AND q.attempts < 5
                  AND q.generation = d.generation AND n.user_id = d.user_id AND n.read_at IS NULL
                  AND n.created_at > now() - interval '1 hour'
                  AND r.revoked_at IS NULL AND r.expires_at > now()
                ORDER BY q.id LIMIT 1 FOR UPDATE OF q, d SKIP LOCKED
                """);
        if (rows.isEmpty()) return false;
        var row = rows.get(0);
        PushSender.Result result;
        try {
            result = sender.send((String) row.get("token"), (UUID) row.get("notice"),
                    (UUID) row.get("user_id"), (UUID) row.get("reference_id"), (String) row.get("title"));
        } catch (RuntimeException error) {
            result = PushSender.Result.RETRY;
        }
        if (result == PushSender.Result.UNREGISTERED) {
            jdbc.update("DELETE FROM push_devices WHERE token = ?", row.get("token"));
        } else if (result == PushSender.Result.SENT) {
            jdbc.update("UPDATE push_deliveries SET finished_at = now(), attempts = attempts + 1 WHERE id = ?", row.get("id"));
        } else {
            long delay = 30L << ((Number) row.get("attempts")).intValue();
            jdbc.update("""
                    UPDATE push_deliveries SET attempts = attempts + 1,
                        available_at = now() + (? * interval '1 second') WHERE id = ?
                    """, delay, row.get("id"));
        }
        return true;
    }
}
