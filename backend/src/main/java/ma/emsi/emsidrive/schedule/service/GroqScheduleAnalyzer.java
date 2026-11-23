package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;

/** Legacy adapter for regression fixtures; not registered as a Spring service. */
public class GroqScheduleAnalyzer extends VisionScheduleAnalyzer {
    public GroqScheduleAnalyzer(ObjectMapper mapper, String apiKey, String model, String endpoint) {
        super(mapper, apiKey, model, endpoint);
    }
}
