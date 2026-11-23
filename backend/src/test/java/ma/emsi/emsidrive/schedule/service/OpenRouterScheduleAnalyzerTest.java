package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class OpenRouterScheduleAnalyzerTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private final ScheduleDocumentReader.Document document = new ScheduleDocumentReader.Document(
            ScheduleSource.IMAGE, List.of("data:image/png;base64,AA=="));

    @Test void sendsParticleModelImageAndServerCredentialAndValidatesResponse() throws Exception {
        var body = new AtomicReference<String>();
        var authorization = new AtomicReference<String>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            body.set(new String(exchange.getRequestBody().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8));
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
            String content = """
                    {"isTimetable":true,"ambiguous":false,"name":null,"warnings":[],"columns":[],
                    "courses":[[null,null,1,null,false,null,null,true,"08:30","11:45"]]}
                    """;
            var response = mapper.writeValueAsBytes(Map.of("choices", List.of(Map.of("finish_reason", "stop",
                    "message", Map.of("content", content)))));
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        try {
            var analyzer = new OpenRouterScheduleAnalyzer(mapper, "server-test-key", "particle-ai/particle-1:free",
                    "http://127.0.0.1:" + server.getAddress().getPort(), 2);
            assertThat(analyzer.enabled()).isTrue();
            var result = analyzer.analyze(document, "G1");
            assertThat(result.slots()).hasSize(1);
            assertThat(result.slots().get(0).startTime()).isEqualTo("08:30");
            assertThat(result.slots().get(0).endTime()).isEqualTo("11:45");
            assertThat(authorization.get()).isEqualTo("Bearer server-test-key");
            var request = mapper.readTree(body.get());
            assertThat(request.path("model").asText()).isEqualTo("particle-ai/particle-1:free");
            assertThat(request.path("messages").get(0).path("content").get(1).path("image_url").path("url").asText())
                    .isEqualTo(document.images().get(0));
            server.removeContext("/");
            server.createContext("/", exchange -> { exchange.sendResponseHeaders(429, -1); exchange.close(); });
            assertThatThrownBy(() -> analyzer.analyze(document, "G1"))
                    .isInstanceOfSatisfying(ApiException.class, ex -> {
                        assertThat(ex.getCode()).isEqualTo("SCHEDULE_AI_RATE_LIMIT");
                        assertThat(ex.getMessage()).doesNotContain("server-test-key");
                    });
        } finally { server.stop(0); }
    }

    @Test void missingKeyDisablesOpenRouter() {
        var analyzer = new OpenRouterScheduleAnalyzer(mapper, "", "particle-ai/particle-1:free",
                "http://127.0.0.1:1", 2);
        assertThat(analyzer.enabled()).isFalse();
        assertThatThrownBy(() -> analyzer.analyze(document, ""))
                .isInstanceOfSatisfying(ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("SCHEDULE_AI_NOT_CONFIGURED"));
    }
}
