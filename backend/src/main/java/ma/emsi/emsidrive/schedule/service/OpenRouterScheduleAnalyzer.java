package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/** OpenRouter vision analysis; only the backend receives the API key. */
@Service
public class OpenRouterScheduleAnalyzer extends VisionScheduleAnalyzer {
    private final boolean enabled;
    private final Duration timeout;

    public OpenRouterScheduleAnalyzer(ObjectMapper mapper,
            @Value("${app.schedule.openrouter-api-key:}") String apiKey,
            @Value("${app.schedule.openrouter-model:particle-ai/particle-1:free}") String model,
            @Value("${app.schedule.openrouter-url:https://openrouter.ai/api/v1/chat/completions}") String endpoint,
            @Value("${app.schedule.openrouter-timeout-seconds:120}") int timeoutSeconds) {
        super(mapper, apiKey, model, endpoint);
        if (timeoutSeconds < 1 || timeoutSeconds > 300) {
            throw new IllegalArgumentException("Invalid OpenRouter timeout");
        }
        enabled = !apiKey.isBlank();
        timeout = Duration.ofSeconds(timeoutSeconds);
    }

    public boolean enabled() { return enabled; }
    @Override protected boolean combineCellBatches() { return true; }
    @Override protected Duration responseTimeout() { return timeout; }
    @Override protected boolean waitForRateLimit() { return false; }
    @Override protected Map<String, Object> requestOptions() {
        // Reserve the output budget for the timetable JSON.
        return Map.of("reasoning", Map.of("effort", "low", "exclude", true));
    }
}
