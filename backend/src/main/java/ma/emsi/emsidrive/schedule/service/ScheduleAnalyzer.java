package ma.emsi.emsidrive.schedule.service;

import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.AnalysisResponse;
import org.springframework.stereotype.Service;

/** Shared provider selection for immediate and background imports. */
@Service
public class ScheduleAnalyzer {
    private final OpenRouterScheduleAnalyzer openRouter;
    private final PaddleScheduleAnalyzer paddle;
    private final GeminiScheduleAnalyzer gemini;

    public ScheduleAnalyzer(OpenRouterScheduleAnalyzer openRouter, PaddleScheduleAnalyzer paddle,
                            GeminiScheduleAnalyzer gemini) {
        this.openRouter = openRouter;
        this.paddle = paddle;
        this.gemini = gemini;
    }

    public AnalysisResponse analyze(ScheduleDocumentReader.Document document, String group) {
        if (openRouter.enabled()) return openRouter.analyze(document, group);
        if (paddle.enabled()) return paddle.analyze(document, group);
        return gemini.analyze(document, group);
    }
}
