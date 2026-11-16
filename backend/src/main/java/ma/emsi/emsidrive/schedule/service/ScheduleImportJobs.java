package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Timestamp;
import java.util.*;
import java.util.concurrent.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.web.multipart.MultipartFile;

/** Durable, owner-scoped imports. Documents exist only while waiting/running; results expire after a day. */
@Service
public class ScheduleImportJobs {
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;
    private final ScheduleDocumentReader reader;
    private final GeminiScheduleAnalyzer analyzer;
    private final TransactionTemplate transactions;
    private final boolean enabled;
    private final ExecutorService workers = Executors.newFixedThreadPool(2);
    private final Map<UUID, UUID> active = new ConcurrentHashMap<>();
    private final Map<UUID, Thread> threads = new ConcurrentHashMap<>();
    private final Semaphore preparation = new Semaphore(2);
    private long nextCleanup;
    private volatile boolean stopping;

    public ScheduleImportJobs(JdbcTemplate jdbc, ObjectMapper mapper, ScheduleDocumentReader reader,
                              GeminiScheduleAnalyzer analyzer, PlatformTransactionManager manager,
                              @Value("${app.schedule.jobs-enabled:true}") boolean enabled) {
        this.jdbc = jdbc; this.mapper = mapper; this.reader = reader; this.analyzer = analyzer;
        this.transactions = new TransactionTemplate(manager); this.enabled = enabled;
    }

    public AnalysisJob submit(UUID user, MultipartFile file, String group, int revision) {
        if (group.length() > 120 || revision < 0) throw ApiException.badRequest("VALIDATION_ERROR", "Invalid import fields");
        if (file.isEmpty() || file.getSize() > 8 * 1024 * 1024) throw ApiException.badRequest("SCHEDULE_FILE_SIZE", "Invalid file size");
        final String hash;
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            digest.update(java.nio.ByteBuffer.allocate(8).putLong(file.getSize()).array());
            digest.update(file.getBytes());
            hash = HexFormat.of().formatHex(digest.digest((group.strip() + "\n" + revision).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) { throw ApiException.badRequest("SCHEDULE_FILE_INVALID", "Unable to read document"); }
        var cached = jdbc.queryForList("SELECT id FROM schedule_import_jobs WHERE user_id=? AND document_hash=? AND status IN ('QUEUED','PROCESSING','SUCCEEDED') AND created_at>now()-interval '1 day' ORDER BY created_at DESC LIMIT 1", user, hash);
        if (!cached.isEmpty()) return get(user, (UUID) cached.get(0).get("id"));
        if (!jdbc.queryForList("SELECT id FROM schedule_import_jobs WHERE user_id=? AND status IN ('QUEUED','PROCESSING')", user).isEmpty())
            throw ApiException.conflict("SCHEDULE_IMPORT_RUNNING", "An import is already running");
        if (!preparation.tryAcquire()) throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "SCHEDULE_ANALYSIS_BUSY", "Document preparation is busy");
        final String payload;
        try {
            payload = mapper.writeValueAsString(reader.read(file));
            if (payload.length() > 32_000_000) throw ApiException.badRequest("SCHEDULE_FILE_SIZE", "Normalized document too large");
        } catch (ApiException ex) { throw ex; }
        catch (Exception ex) { throw ApiException.badRequest("SCHEDULE_FILE_INVALID", "Unable to read document"); }
        finally { preparation.release(); }
        UUID id = transactions.execute(status -> {
            if (jdbc.queryForList("SELECT id FROM users WHERE id = ? FOR UPDATE", user).isEmpty())
                throw ApiException.notFound("USER_NOT_FOUND", "User not found");
            var existing = jdbc.queryForList("""
                    SELECT id FROM schedule_import_jobs WHERE user_id = ? AND document_hash = ?
                    AND status IN ('QUEUED','PROCESSING','SUCCEEDED') AND created_at > now() - interval '1 day'
                    ORDER BY created_at DESC LIMIT 1
                    """, user, hash);
            if (!existing.isEmpty()) return (UUID) existing.get(0).get("id");
            if (!jdbc.queryForList("SELECT id FROM schedule_import_jobs WHERE user_id = ? AND status IN ('QUEUED','PROCESSING')", user).isEmpty())
                throw ApiException.conflict("SCHEDULE_IMPORT_RUNNING", "An import is already running");
            // Serialize queue admission across instances to keep retained uploads bounded.
            jdbc.execute("SELECT pg_advisory_xact_lock(731086)");
            if (jdbc.queryForObject("SELECT count(*) FROM schedule_import_jobs WHERE status IN ('QUEUED','PROCESSING')", Integer.class) >= 50)
                throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "SCHEDULE_ANALYSIS_BUSY", "Import queue is full");
            UUID created = UUID.randomUUID();
            jdbc.update("INSERT INTO schedule_import_jobs(id,user_id,status,document_hash,group_name,revision,payload) VALUES (?,?,'QUEUED',?,?,?,?)",
                    created, user, hash, group.strip(), revision, payload);
            return created;
        });
        return get(user, id);
    }

    public AnalysisJob get(UUID user, UUID id) {
        var rows = jdbc.queryForList("SELECT * FROM schedule_import_jobs WHERE id = ? AND user_id = ?", id, user);
        if (rows.isEmpty()) throw ApiException.notFound("SCHEDULE_IMPORT_NOT_FOUND", "Import not found");
        return response(rows.get(0));
    }

    public AnalysisJob latest(UUID user) {
        var rows = jdbc.queryForList("""
                SELECT * FROM schedule_import_jobs WHERE user_id = ? AND status NOT IN ('DISMISSED','CANCELLED')
                AND created_at > now() - interval '1 day' ORDER BY created_at DESC LIMIT 1
                """, user);
        return rows.isEmpty() ? null : response(rows.get(0));
    }

    public void dismiss(UUID user, UUID id) {
        get(user, id);
        jdbc.update("""
                UPDATE schedule_import_jobs SET status = CASE WHEN status IN ('QUEUED','PROCESSING') THEN 'CANCELLED' ELSE 'DISMISSED' END,
                payload = NULL, result = NULL, lease_token = NULL, lease_until = NULL, updated_at = now()
                WHERE id = ? AND user_id = ?
                """, id, user);
        Thread running = threads.get(id);
        if (running != null) running.interrupt();
    }

    private AnalysisJob response(Map<String, Object> row) {
        try {
            String result = (String) row.get("result");
            return new AnalysisJob((UUID) row.get("id"), (String) row.get("status"), ((Number) row.get("revision")).intValue(),
                    result == null ? null : mapper.readValue(result, AnalysisResponse.class),
                    (String) row.get("error_code"), ((Timestamp) row.get("created_at")).toInstant());
        } catch (Exception ex) { throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "SCHEDULE_AI_INVALID", "Invalid import result"); }
    }

    @Scheduled(fixedDelay = 1000, initialDelay = 1500)
    public void dispatch() {
        if (!enabled || stopping) return;
        for (var entry : active.entrySet()) jdbc.update("UPDATE schedule_import_jobs SET lease_until = now() + interval '60 seconds' WHERE id = ? AND lease_token = ? AND status = 'PROCESSING'",
                entry.getKey(), entry.getValue());
        // Expire retained results and purge original document payloads even after a crashed worker.
        if (System.nanoTime() >= nextCleanup) {
            jdbc.update("DELETE FROM schedule_import_jobs WHERE created_at < now() - interval '1 day'");
            nextCleanup = System.nanoTime() + TimeUnit.MINUTES.toNanos(1);
        }
        while (active.size() < 2) {
            UUID token = UUID.randomUUID();
            var claimed = jdbc.queryForList("""
                    UPDATE schedule_import_jobs SET status = 'PROCESSING', lease_token = ?, lease_until = now() + interval '60 seconds', updated_at = now()
                    WHERE id = (SELECT id FROM schedule_import_jobs
                        WHERE status = 'QUEUED' OR (status = 'PROCESSING' AND lease_until < now())
                        ORDER BY created_at FOR UPDATE SKIP LOCKED LIMIT 1)
                    RETURNING id, payload, group_name
                    """, token);
            if (claimed.isEmpty()) break;
            var row = claimed.get(0); UUID id = (UUID) row.get("id");
            active.put(id, token);
            workers.submit(() -> process(id, token, (String) row.get("payload"), (String) row.get("group_name")));
        }
    }

    private void process(UUID id, UUID token, String payload, String group) {
        threads.put(id, Thread.currentThread());
        try {
            var document = mapper.readValue(payload, ScheduleDocumentReader.Document.class);
            var result = analyzer.analyze(document, group);
            jdbc.update("""
                    UPDATE schedule_import_jobs SET status = 'SUCCEEDED', payload = NULL, result = ?, lease_token = NULL,
                    lease_until = NULL, updated_at = now() WHERE id = ? AND lease_token = ? AND status = 'PROCESSING'
                    """, mapper.writeValueAsString(result), id, token);
        } catch (Exception ex) {
            if (stopping) {
                Thread.interrupted();
                jdbc.update("UPDATE schedule_import_jobs SET status='QUEUED',lease_token=NULL,lease_until=NULL,updated_at=now() WHERE id=? AND lease_token=? AND status='PROCESSING'", id, token);
                return;
            }
            String code = ex instanceof ApiException api ? api.getCode() : "SCHEDULE_AI_UNAVAILABLE";
            jdbc.update("""
                    UPDATE schedule_import_jobs SET status = 'FAILED', payload = NULL, error_code = ?, lease_token = NULL,
                    lease_until = NULL, updated_at = now() WHERE id = ? AND lease_token = ? AND status = 'PROCESSING'
                    """, code, id, token);
        } finally {
            threads.remove(id); active.remove(id, token); Thread.interrupted();
        }
    }

    @PreDestroy void stop() { stopping = true; workers.shutdownNow(); }
}
