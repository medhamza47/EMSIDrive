package ma.emsi.emsidrive.schedule.service;

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
    private final ScheduleAnalyzer analyzer;
    private final Semaphore capacity = new Semaphore(2);
    private final Set<UUID> running = new HashSet<>();
    public ScheduleAnalysisService(ScheduleDocumentReader reader, ScheduleAnalyzer analyzer) {
        this.reader = reader; this.analyzer = analyzer;
    }

    public AnalysisResponse analyze(UUID user, MultipartFile file, String group) {
        if (group.length() > 120) throw ApiException.badRequest("VALIDATION_ERROR", "Group is too long");
        acquire(user);
        try { return analyzer.analyze(reader.read(file), group.strip()); }
        finally { release(user); }
    }
    private synchronized void acquire(UUID user) {
        if (running.contains(user) || !capacity.tryAcquire()) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "SCHEDULE_ANALYSIS_BUSY", "Try again later");
        }
        running.add(user);
    }
    private synchronized void release(UUID user) { running.remove(user); capacity.release(); }
}
