package ma.emsi.emsidrive.schedule.service;

import java.util.List;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class ScheduleAnalyzerTest {
    @Test void configuredOpenRouterIsUsedWithoutSendingDocumentsToOtherProvidersOnFailure() {
        var openRouter = mock(OpenRouterScheduleAnalyzer.class);
        var paddle = mock(PaddleScheduleAnalyzer.class);
        var gemini = mock(GeminiScheduleAnalyzer.class);
        var document = new ScheduleDocumentReader.Document(ScheduleSource.IMAGE, List.of("image"));
        when(openRouter.enabled()).thenReturn(true);
        when(openRouter.analyze(document, "G1")).thenThrow(ApiException.badRequest("SCHEDULE_NOT_TIMETABLE", "Invalid"));
        var analyzer = new ScheduleAnalyzer(openRouter, paddle, gemini);
        assertThatThrownBy(() -> analyzer.analyze(document, "G1")).isInstanceOf(ApiException.class);
        verify(openRouter).analyze(document, "G1");
        verifyNoInteractions(paddle, gemini);
    }
}
