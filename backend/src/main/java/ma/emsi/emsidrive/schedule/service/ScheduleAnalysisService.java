package ma.emsi.emsidrive.schedule.service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.Semaphore;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.AnalysisResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ScheduleAnalysisService {
    private final ScheduleDocumentReader reader;
    private final GroqScheduleAnalyzer analyzer;
    private final Semaphore capacity = new Semaphore(2);
    private final Map<UUID, List<Instant>> attempts = new HashMap<>();
    private final Set<UUID> running = new HashSet<>();
    public ScheduleAnalysisService(ScheduleDocumentReader reader, GroqScheduleAnalyzer analyzer) {
        this.reader = reader; this.analyzer = analyzer;
    }

    public AnalysisResponse analyze(UUID user, MultipartFile file, String group) {
        if (group.length() > 120) throw ApiException.badRequest("VALIDATION_ERROR", "Group is too long");
        acquire(user);
        try { return analyzer.analyze(reader.read(file), group.strip()); }
        finally { release(user); }
    }
    private synchronized void acquire(UUID user) {
        Instant now = Instant.now();
        attempts.values().forEach(list -> list.removeIf(time -> time.isBefore(now.minusSeconds(86400))));
        attempts.entrySet().removeIf(entry -> entry.getValue().isEmpty());
        var list = attempts.getOrDefault(user, new ArrayList<>());
        if (running.contains(user) || list.size() >= 30 || attempts.size() >= 10_000
                || list.stream().filter(t -> t.isAfter(now.minusSeconds(60))).count() >= 3 || !capacity.tryAcquire()) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "SCHEDULE_AI_RATE_LIMIT", "Try again later");
        }
        list.add(now); attempts.put(user, list); running.add(user);
    }
    private synchronized void release(UUID user) { running.remove(user); capacity.release(); }
}
