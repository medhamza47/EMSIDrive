package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class GeminiScheduleAnalyzerTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private final ScheduleDocumentReader.Document document = new ScheduleDocumentReader.Document(
            ScheduleSource.IMAGE, List.of("data:image/png;base64,AA=="));

    @Test void switchesProvidersWithoutSharingCredentialsAndFallsBackAgainWhenGroqFails() throws Exception {
        var requests = new java.util.ArrayList<String>();
        var failGroq = new java.util.concurrent.atomic.AtomicBoolean(false);
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            String provider = exchange.getRequestURI().getPath();
            var body = mapper.readTree(exchange.getRequestBody());
            requests.add(provider + ":" + body.path("model").asText() + ":" + exchange.getRequestHeaders().getFirst("Authorization"));
            if ((provider.equals("/gemini") && body.path("model").asText().equals("primary"))
                    || (provider.equals("/groq") && failGroq.get())) {
                exchange.sendResponseHeaders(429, -1); exchange.close(); return;
            }
            if (provider.equals("/groq")) {
                assertThat(body.path("reasoning_effort").asText()).isEqualTo("none");
                assertThat(body.path("reasoning_format").asText()).isEqualTo("hidden");
            }
            String content = """
                    {"isTimetable":true,"ambiguous":false,"name":null,"warnings":[],"columns":[],
                     "courses":[[null,null,1,null,false,null,null,true,"08:30","11:45"]]}
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of("choices", List.of(Map.of("finish_reason", "stop", "message", Map.of("content", content)))));
            exchange.sendResponseHeaders(200, response.length); exchange.getResponseBody().write(response); exchange.close();
        });
        server.start();
        try {
            String base = "http://127.0.0.1:" + server.getAddress().getPort();
            var analyzer = new GeminiScheduleAnalyzer(mapper, "gemini-test", "primary", base + "/gemini", "backup,third", 2,
                    "groq-test", "qwen/qwen3.8-27b", base + "/groq");
            assertThat(analyzer.analyze(document, "G1").slots().get(0).endTime()).isEqualTo("11:45");
            assertThat(requests).containsExactly("/gemini:primary:Bearer gemini-test", "/groq:qwen/qwen3.8-27b:Bearer groq-test");
            requests.clear(); failGroq.set(true);
            assertThat(analyzer.analyze(document, "G1").slots()).hasSize(1);
            assertThat(requests).containsExactly("/gemini:primary:Bearer gemini-test", "/groq:qwen/qwen3.8-27b:Bearer groq-test", "/gemini:backup:Bearer gemini-test");
            requests.clear(); failGroq.set(false);
            var groqOnly = new GeminiScheduleAnalyzer(mapper, "", "primary", base + "/gemini", "", 2,
                    "groq-test", "qwen/qwen3.8-27b", base + "/groq");
            assertThat(groqOnly.analyze(document, "G1").slots()).hasSize(1);
            assertThat(requests).containsExactly("/groq:qwen/qwen3.8-27b:Bearer groq-test");
        } finally { server.stop(0); }
    }

    @Test void missingKeyFailsClearlyWithoutContactingAProvider() {
        var analyzer = new GeminiScheduleAnalyzer(mapper, "", "gemini-3.8-flash", "http://127.0.0.1:1");
        assertThatThrownBy(() -> analyzer.analyze(document, "G1"))
                .isInstanceOfSatisfying(ApiException.class, ex -> assertThat(ex.getCode()).isEqualTo("SCHEDULE_AI_NOT_CONFIGURED"));
    }

    @Test void sendsImageAndCredentialsAndReturnsOnlySessionTimes() throws Exception {
        var body = new AtomicReference<String>(); var authorization = new AtomicReference<String>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            body.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
            String content = """
                    {"isTimetable":true,"ambiguous":false,"name":"G1","warnings":[],
                     "columns":[["08:30","10:00"],["10:15","11:45"]],
                     "courses":[["Ignored subject","Ignored room",1,"TARGA",false,1,2,true,null,null]]}
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of("choices", List.of(Map.of("finish_reason", "stop",
                    "message", Map.of("content", content)))));
            exchange.sendResponseHeaders(200, response.length); exchange.getResponseBody().write(response); exchange.close();
        });
        server.start();
        try {
            var analyzer = new GeminiScheduleAnalyzer(mapper, "test-key", "gemini-3.8-flash",
                    "http://127.0.0.1:" + server.getAddress().getPort());
            var result = analyzer.analyze(document, "G1");
            var slot = result.slots().get(0);
            assertThat(slot.startTime()).isEqualTo("08:30"); assertThat(slot.endTime()).isEqualTo("11:45");
            assertThat(slot.label()).isNull(); assertThat(slot.location()).isNull(); assertThat(slot.campus()).isNull();
            assertThat(authorization.get()).isEqualTo("Bearer test-key");
            var sent = mapper.readTree(body.get());
            assertThat(sent.path("model").asText()).isEqualTo("gemini-3.8-flash");
            assertThat(sent.path("reasoning_effort").asText()).isEqualTo("low");
            assertThat(sent.path("response_format").path("type").asText()).isEqualTo("json_object");
            assertThat(sent.path("messages").get(0).path("content").get(1).path("image_url").path("url").asText())
                    .isEqualTo(document.images().get(0));
            server.removeContext("/");
            server.createContext("/", exchange -> { exchange.sendResponseHeaders(429, -1); exchange.close(); });
            assertThatThrownBy(() -> analyzer.analyze(document, "G1"))
                    .isInstanceOfSatisfying(ApiException.class, ex -> {
                        assertThat(ex.getCode()).isEqualTo("SCHEDULE_AI_RATE_LIMIT");
                        assertThat(ex.getMessage()).doesNotContain("test-key");
                    });
        } finally { server.stop(0); }
    }

    @Test void combinesMeasuredCellImagesIntoOneCallWithoutLosingMergedDurations() throws Exception {
        var output = new java.io.ByteArrayOutputStream();
        javax.imageio.ImageIO.write(TimetableGridDetectorTest.photographedGrid(), "png", output);
        var photo = new ScheduleDocumentReader.Document(ScheduleSource.IMAGE,
                List.of("data:image/png;base64," + java.util.Base64.getEncoder().encodeToString(output.toByteArray())));
        var plan = new TimetableGridDetector().prepare(photo.images()).orElseThrow();
        var calls = new java.util.concurrent.atomic.AtomicInteger();
        var captured = new AtomicReference<String>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            calls.incrementAndGet();
            captured.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            var result = mapper.createObjectNode();
            result.set("columns", mapper.readTree("[[\"08:30\",\"10:00\"],[\"10:15\",\"11:45\"],[\"12:00\",\"13:30\"],[\"13:45\",\"15:15\"],[\"15:30\",\"17:00\"],[\"17:15\",\"18:45\"]]"));
            var days = result.putObject("weekdays"); var cells = result.putObject("cells");
            String[] labels = {"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"};
            for (var row : plan.grid().rows()) {
                days.put(String.valueOf(row.index()), labels[row.index() - 1]);
                for (var cell : row.cells()) {
                    if (cell.first() == 1 && java.util.Set.of(1, 5, 6).contains(row.index()))
                        cells.set(cell.id(), mapper.valueToTree(java.util.Arrays.asList(null, null, null, null, null, false)));
                    else cells.putNull(cell.id());
                }
            }
            var payload = mapper.writeValueAsBytes(Map.of("choices", List.of(Map.of("finish_reason", "stop", "message", Map.of("content", result.toString())))));
            exchange.sendResponseHeaders(200, payload.length); exchange.getResponseBody().write(payload); exchange.close();
        });
        server.start();
        try {
            var analyzer = new GeminiScheduleAnalyzer(mapper, "test-key", "gemini-3.8-flash", "http://127.0.0.1:" + server.getAddress().getPort());
            var result = analyzer.analyze(photo, "G1");
            assertThat(calls.get()).isEqualTo(1);
            assertThat(mapper.readTree(captured.get()).path("messages").get(0).path("content").size()).isEqualTo(1 + plan.batches().size());
            assertThat(result.slots()).extracting(s -> s.endTime()).containsExactly("11:45", "10:00", "11:45");
            assertThat(result.slots()).allSatisfy(s -> assertThat(s.needsReview()).isFalse());
        } finally { server.stop(0); }
    }

    @Test void switchesModelsImmediatelyOnQuotaAndMalformedOutput() throws Exception {
        var models = new java.util.ArrayList<String>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            var request = mapper.readTree(exchange.getRequestBody()); models.add(request.path("model").asText());
            if (models.size() == 1) {
                exchange.getResponseHeaders().add("Retry-After", "60"); exchange.sendResponseHeaders(429, -1); exchange.close(); return;
            }
            String content = models.size() == 2 ? "invalid json" : """
                    {"isTimetable":true,"ambiguous":false,"name":null,"warnings":[],"columns":[],
                     "courses":[[null,null,1,null,false,null,null,true,"08:30","11:45"]]}
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of("choices", List.of(Map.of("finish_reason", "stop", "message", Map.of("content", content)))));
            exchange.sendResponseHeaders(200, response.length); exchange.getResponseBody().write(response); exchange.close();
        });
        server.start();
        try {
            var analyzer = new GeminiScheduleAnalyzer(mapper, "test-key", "first-model", "http://127.0.0.1:" + server.getAddress().getPort(), "second-model,third-model", 1);
            long start = System.nanoTime();
            assertThat(analyzer.analyze(document, "G1").slots().get(0).endTime()).isEqualTo("11:45");
            assertThat(models).containsExactly("first-model", "second-model", "third-model");
            assertThat(java.time.Duration.ofNanos(System.nanoTime() - start)).isLessThan(java.time.Duration.ofSeconds(10));
        } finally { server.stop(0); }
    }

    @Test void aSlowModelTimesOutAndTheNextModelIsUsed() throws Exception {
        var models = java.util.Collections.synchronizedList(new java.util.ArrayList<String>());
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        var executor = java.util.concurrent.Executors.newCachedThreadPool(); server.setExecutor(executor);
        server.createContext("/", exchange -> {
            try {
                String model = mapper.readTree(exchange.getRequestBody()).path("model").asText(); models.add(model);
                if (model.equals("slow-model")) Thread.sleep(1800);
                String content = """
                        {"isTimetable":true,"ambiguous":false,"name":null,"warnings":[],"columns":[],
                         "courses":[[null,null,1,null,false,null,null,true,"08:30","11:45"]]}
                        """;
                byte[] response = mapper.writeValueAsBytes(Map.of("choices",List.of(Map.of("finish_reason","stop","message",Map.of("content",content)))));
                exchange.sendResponseHeaders(200,response.length); exchange.getResponseBody().write(response);
            } catch (InterruptedException ex) { Thread.currentThread().interrupt(); }
            catch (java.io.IOException ignored) { /* The timed-out caller has closed this response. */ }
            finally { exchange.close(); }
        });
        server.start();
        try {
            var analyzer = new GeminiScheduleAnalyzer(mapper,"test-key","slow-model","http://127.0.0.1:"+server.getAddress().getPort(),"backup-model",1);
            assertThat(analyzer.analyze(document,"G1").slots().get(0).endTime()).isEqualTo("11:45");
            assertThat(models).containsExactly("slow-model","backup-model");
        } finally { server.stop(0); executor.shutdownNow(); }
    }

    @Test void validJsonWithNoUsableHoursAlsoTriggersTheBackupModel() throws Exception {
        var calls = new java.util.concurrent.atomic.AtomicInteger();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        server.createContext("/", exchange -> {
            boolean first = calls.incrementAndGet() == 1;
            String content = "{\"isTimetable\":true,\"ambiguous\":false,\"name\":null,\"warnings\":[],\"columns\":[],\"courses\":[[null,null,1,null,false,null,null,true,\"08:30\"," + (first ? "null" : "\"11:45\"") + "]]}";
            byte[] response = mapper.writeValueAsBytes(Map.of("choices",List.of(Map.of("finish_reason","stop","message",Map.of("content",content)))));
            exchange.sendResponseHeaders(200,response.length); exchange.getResponseBody().write(response); exchange.close();
        });
        server.start();
        try {
            var analyzer = new GeminiScheduleAnalyzer(mapper,"test-key","first-model","http://127.0.0.1:"+server.getAddress().getPort(),"backup-model",1);
            assertThat(analyzer.analyze(document,"G1").slots().get(0).endTime()).isEqualTo("11:45");
            assertThat(calls.get()).isEqualTo(2);
        } finally { server.stop(0); }
    }
}
