package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class GroqScheduleAnalyzerTest {
    final ObjectMapper mapper = new ObjectMapper();
    final ScheduleDocumentReader.Document document = new ScheduleDocumentReader.Document(ScheduleSource.IMAGE, List.of("data:image/jpeg;base64,AA=="));
    final GroqScheduleAnalyzer analyzer = new GroqScheduleAnalyzer(mapper, "unused", "vision", "http://localhost");
    final String valid = """
        {"isTimetable":true,"ambiguous":false,"name":"G1","warnings":[],"slots":[
        {"label":"ERP","location":"LI8","weekday":5,"startTime":"08:30","endTime":"10:00","campus":"CENTRE","needsReview":false,
         "timeEvidence":{"source":"EXPLICIT","spanCertain":true}}]}
        """;
    @Test void keepsReadableFieldsAndMarksMissingOrInvalidFieldsForReview() {
        var result = analyzer.parse(valid, document);
        assertThat(result.slots().get(0).needsReview()).isFalse();
        assertThat(result.slots().get(0).startTime()).isEqualTo("08:30");
        result = analyzer.parse(valid.replace("\"CENTRE\"", "null").replace("\"08:30\"", "\"28:30\""), document);
        assertThat(result.slots().get(0).needsReview()).isTrue();
        assertThat(result.slots().get(0).campus()).isNull();
        assertThat(result.slots().get(0).startTime()).isNull();
    }
    @Test void rejectsAmbiguousNonTimetableAndMalformedOutput() {
        for (String json : List.of("not json", "[]", "{}", valid.replace("\"label\":\"ERP\"", "\"label\":\"Deep Learning\",\"label\":\"ERP\""), valid.replace("\"ambiguous\":false", "\"ambiguous\":true"), valid.replace("\"isTimetable\":true", "\"isTimetable\":false"))) {
            assertThatThrownBy(() -> analyzer.parse(json, document)).isInstanceOf(ApiException.class);
        }
    }
    @Test void parsingRecalculatesTheWholeMergedCellAndKeepsUncertainEndsUnknown() throws Exception {
        var root = (com.fasterxml.jackson.databind.node.ObjectNode) mapper.readTree(valid);
        root.set("timeColumns", mapper.readTree("""
            [{"index":1,"startTime":"08:30","endTime":"10:00"},
             {"index":2,"startTime":"10:15","endTime":"11:45"}]
            """));
        var slot = (com.fasterxml.jackson.databind.node.ObjectNode) root.path("slots").get(0);
        slot.set("timeEvidence",mapper.readTree("{\"source\":\"HEADERS\",\"startColumn\":1,\"endColumn\":2,\"spanCertain\":true}"));
        var parsed = analyzer.parse(mapper.writeValueAsString(root),document);
        assertThat(parsed.slots().get(0).endTime()).isEqualTo("11:45");
        assertThat(parsed.slots().get(0).needsReview()).isFalse();
        ((com.fasterxml.jackson.databind.node.ObjectNode) slot.path("timeEvidence")).put("spanCertain",false);
        parsed = analyzer.parse(mapper.writeValueAsString(root),document);
        assertThat(parsed.slots().get(0).endTime()).isNull();
        assertThat(parsed.slots().get(0).needsReview()).isTrue();
        assertThat(parsed.warnings()).isNotEmpty();
    }
    @Test void sendsImagesAndJsonModeAndHandlesProviderFailuresWithoutLeakingDetails() throws Exception {
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        var captured = new AtomicReference<String>();
        server.createContext("/", exchange -> {
            captured.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            var response = mapper.writeValueAsBytes(java.util.Map.of("choices", List.of(java.util.Map.of("finish_reason","stop","message",java.util.Map.of("content",valid)))));
            exchange.sendResponseHeaders(200, response.length); exchange.getResponseBody().write(response); exchange.close();
        });
        server.start();
        try {
            var client = new GroqScheduleAnalyzer(mapper,"test-key","vision","http://127.0.0.1:" + server.getAddress().getPort());
            assertThat(client.analyze(document, "G1").slots()).hasSize(1);
            var sent = mapper.readTree(captured.get());
            assertThat(sent.path("response_format").path("type").asText()).isEqualTo("json_object");
            assertThat(sent.path("messages").get(0).path("content").get(1).path("image_url").path("url").asText()).startsWith("data:image/jpeg");
            server.removeContext("/");
            server.createContext("/", e -> { e.sendResponseHeaders(429, -1); e.close(); });
            assertThatThrownBy(() -> client.analyze(document,"G1")).isInstanceOfSatisfying(ApiException.class, e -> {
                assertThat(e.getCode()).isEqualTo("SCHEDULE_AI_RATE_LIMIT"); assertThat(e.getMessage()).doesNotContain("test-key");
            });
        } finally { server.stop(0); }
    }

    @Test void measuredCellsSurviveBatchedTranscriptionAndOneShortProviderRateLimit() throws Exception {
        var output=new java.io.ByteArrayOutputStream();
        javax.imageio.ImageIO.write(TimetableGridDetectorTest.photographedGrid(),"png",output);
        var photo=new ScheduleDocumentReader.Document(ScheduleSource.IMAGE,List.of("data:image/png;base64,"+java.util.Base64.getEncoder().encodeToString(output.toByteArray())));
        var plan=new TimetableGridDetector().prepare(photo.images()).orElseThrow();
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        var calls=new java.util.concurrent.atomic.AtomicInteger();
        server.createContext("/",exchange->{
            int call=calls.getAndIncrement();
            if(call==0){exchange.getResponseHeaders().add("Retry-After","0.01");exchange.sendResponseHeaders(429,-1);exchange.close();return;}
            int batch=call-1;
            var result=mapper.createObjectNode();
            result.set("columns",mapper.readTree("[[\"08:30\",\"10:00\"],[\"10:15\",\"11:45\"],[\"12:00\",\"13:30\"],[\"13:45\",\"15:15\"],[\"15:30\",\"17:00\"],[\"17:15\",\"18:45\"]]"));
            var days=result.putObject("weekdays");var cells=result.putObject("cells");
            String[] labels={"Lundi","Mardi","Mercredi","Jeudi","Vendredi","Samedi"};
            for(var row:plan.batches().get(batch).rows()) {
                days.put(String.valueOf(row.index()),labels[row.index()-1]);
                for(var cell:row.cells()) {
                    if(cell.first()==1 && java.util.Set.of(1,5,6).contains(row.index()))
                        cells.set(cell.id(),mapper.valueToTree(java.util.Arrays.asList(row.index()==5?"ERP":"Double session","TARGA","LI8",null,null,false)));
                    else cells.putNull(cell.id());
                }
            }
            var payload=mapper.writeValueAsBytes(java.util.Map.of("choices",List.of(java.util.Map.of("finish_reason","stop","message",java.util.Map.of("content",result.toString())))));
            exchange.sendResponseHeaders(200,payload.length);exchange.getResponseBody().write(payload);exchange.close();
        });
        server.start();
        try {
            var client=new GroqScheduleAnalyzer(mapper,"unused","vision","http://127.0.0.1:"+server.getAddress().getPort());
            var result=client.analyze(photo,"G1");
            assertThat(calls.get()).isEqualTo(3);assertThat(result.slots()).hasSize(3);
            assertThat(result.slots()).extracting(s->s.endTime()).containsExactly("11:45","10:00","11:45");
        } finally {server.stop(0);}
    }
}
