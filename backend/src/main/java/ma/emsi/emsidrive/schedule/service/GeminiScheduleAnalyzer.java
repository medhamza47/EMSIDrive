package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.*;
import java.time.Duration;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.AnalysisResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/** Gemini's compatible vision endpoint; credentials stay exclusively on the server. */
@Service
public class GeminiScheduleAnalyzer extends VisionScheduleAnalyzer {
    private final ObjectMapper mapper;
    private final String apiKey, endpoint;
    private record Candidate(String key, String model, String endpoint, boolean groq) {}
    private final List<Candidate> candidates;
    private final Duration attemptTimeout;

    public GeminiScheduleAnalyzer(ObjectMapper mapper, String apiKey, String model, String endpoint) {
        this(mapper, apiKey, model, endpoint, "", 20);
    }

    public GeminiScheduleAnalyzer(ObjectMapper mapper,
            @Value("${app.schedule.gemini-api-key:}") String apiKey,
            @Value("${app.schedule.gemini-model:gemini-3.8-flash}") String model,
            @Value("${app.schedule.gemini-url:https://generativelanguage.googleapis.com/v1beta/openai/chat/completions}") String endpoint,
            @Value("${app.schedule.gemini-fallback-models:gemini-3.5-flash-lite,gemini-3.1-flash-lite}") String fallbackModels,
            @Value("${app.schedule.gemini-attempt-seconds:20}") int attemptSeconds) {
        this(mapper, apiKey, model, endpoint, fallbackModels, attemptSeconds, "", "qwen/qwen3.8-27b", "https://api.groq.com/openai/v1/chat/completions");
    }

    @Autowired
    public GeminiScheduleAnalyzer(ObjectMapper mapper,
            @Value("${app.schedule.gemini-api-key:}") String apiKey,
            @Value("${app.schedule.gemini-model:gemini-3.8-flash}") String model,
            @Value("${app.schedule.gemini-url:https://generativelanguage.googleapis.com/v1beta/openai/chat/completions}") String endpoint,
            @Value("${app.schedule.gemini-fallback-models:gemini-3.5-flash-lite,gemini-3.1-flash-lite}") String fallbackModels,
            @Value("${app.schedule.gemini-attempt-seconds:20}") int attemptSeconds,
            @Value("${app.schedule.groq-api-key:}") String groqKey,
            @Value("${app.schedule.groq-model:qwen/qwen3.8-27b}") String groqModel,
            @Value("${app.schedule.groq-url:https://api.groq.com/openai/v1/chat/completions}") String groqEndpoint) {
        super(mapper, apiKey, model, endpoint);
        this.mapper = mapper; this.apiKey = apiKey; this.endpoint = endpoint;
        var ordered = new LinkedHashSet<String>(); ordered.add(model);
        for (String fallback : fallbackModels.split(",")) if (!fallback.isBlank()) ordered.add(fallback.strip());
        if (ordered.size() > 3 || ordered.stream().anyMatch(m -> !m.matches("[A-Za-z0-9._-]+")) || attemptSeconds < 1 || attemptSeconds > 120)
            throw new IllegalArgumentException("Invalid Gemini model fallback configuration");
        var configured = new ArrayList<Candidate>();
        if (!apiKey.isBlank()) configured.add(new Candidate(apiKey, model, endpoint, false));
        if (!groqKey.isBlank()) {
            if (!groqModel.matches("[A-Za-z0-9._/-]+")) throw new IllegalArgumentException("Invalid Groq model");
            configured.add(new Candidate(groqKey, groqModel, groqEndpoint, true));
        }
        if (!apiKey.isBlank()) for (String fallback : ordered) {
            if (!fallback.equals(model) && configured.size() < 3)
                configured.add(new Candidate(apiKey, fallback, endpoint, false));
        }
        this.candidates = List.copyOf(configured); this.attemptTimeout = Duration.ofSeconds(attemptSeconds);
    }

    @Override protected boolean combineCellBatches() { return true; }

    @Override protected Map<String, Object> requestOptions() {
        return Map.of("reasoning_effort", "low");
    }

    @Override public AnalysisResponse analyze(ScheduleDocumentReader.Document document, String group) {
        ApiException last = null;
        if (candidates.isEmpty()) throw new ApiException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,
                "SCHEDULE_AI_NOT_CONFIGURED", "Schedule analysis is not configured");
        for (Candidate candidate : candidates) {
            try {
                long deadline = System.nanoTime() + attemptTimeout.toNanos();
                var result = new VisionScheduleAnalyzer(mapper, candidate.key(), candidate.model(), candidate.endpoint()) {
                    @Override protected boolean combineCellBatches() { return true; }
                    @Override protected int maxBatchImages() { return candidate.groq() ? 3 : Integer.MAX_VALUE; }
                    @Override protected Map<String, Object> requestOptions() {
                        return candidate.groq() ? Map.of("reasoning_effort", "none", "reasoning_format", "hidden")
                                : Map.of("reasoning_effort", "low");
                    }
                    @Override protected Duration responseTimeout() {
                        long remaining = deadline - System.nanoTime();
                        if (remaining <= 0) throw new ApiException(org.springframework.http.HttpStatus.GATEWAY_TIMEOUT,
                                "SCHEDULE_AI_TIMEOUT", "Schedule analysis timed out");
                        return Duration.ofNanos(remaining);
                    }
                    @Override protected boolean waitForRateLimit() { return false; }
                }.analyze(document, group);
                if (result.slots().stream().noneMatch(s -> s.weekday() != null && s.startTime() != null && s.endTime() != null
                        && s.startTime().compareTo(s.endTime()) < 0))
                    throw new ApiException(org.springframework.http.HttpStatus.BAD_GATEWAY, "SCHEDULE_AI_INVALID", "No usable session times");
                return result;
            } catch (ApiException ex) {
                if (Thread.currentThread().isInterrupted() || !Set.of("SCHEDULE_AI_RATE_LIMIT", "SCHEDULE_AI_UNAVAILABLE", "SCHEDULE_AI_TIMEOUT", "SCHEDULE_AI_INVALID").contains(ex.getCode())) throw ex;
                last = ex;
            }
        }
        throw last;
    }
}
