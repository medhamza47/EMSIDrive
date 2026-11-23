package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.*;
import java.util.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class TimetableCellTranscriptionTest {
    final ObjectMapper mapper=new ObjectMapper();
    final TimetableGridDetector.Line line=new TimetableGridDetector.Line(100,0,0,600,600);
    final TimetableGridDetector.Row row=new TimetableGridDetector.Row(1,line,line,List.of(new TimetableGridDetector.Cell("b1",1,2),new TimetableGridDetector.Cell("b2",3,3)));
    final TimetableGridDetector.Grid grid=new TimetableGridDetector.Grid(List.of(0,100,200,300),List.of(row),0,100);
    final TimetableGridDetector.Batch batch=new TimetableGridDetector.Batch("",List.of(row));
    final String valid="""
        {"columns":[["08h30","10h00"],["10h15","11h45"],["12h00","13h30"]],
         "weekdays":{"1":"Lundi"},"cells":{"b1":["Deep Learning","TARGA","LI8",null,null,false],"b2":null}}
        """;
    @Test void serverBindsCourseToMeasuredMergedSpanAndNormalizesFrenchTimes() throws Exception {
        var root=new TimetableCellTranscription(mapper).normalize(mapper.readTree(valid),grid,batch);
        var parsed=new GroqScheduleAnalyzer(mapper,"unused","vision","http://localhost").parse(root.toString(),new ScheduleDocumentReader.Document(ma.emsi.emsidrive.schedule.entity.ScheduleSource.IMAGE,List.of()));
        assertThat(parsed.slots()).hasSize(1);assertThat(parsed.slots().get(0).startTime()).isEqualTo("08:30");
        assertThat(parsed.slots().get(0).endTime()).isEqualTo("11:45");
    }
    @Test void rejectsInventedMissingOrMisplacedCardIdentifiers() throws Exception {
        for(var json:List.of(valid.replace("\"b2\":null","\"b3\":null"),valid.replace(",\"b2\":null",""),valid.replace("\"1\":\"Lundi\"","\"2\":\"Lundi\""))) {
            assertThatThrownBy(()->new TimetableCellTranscription(mapper).normalize(mapper.readTree(json),grid,batch)).isInstanceOf(ApiException.class);
        }
    }
    @Test void preservesExplicitHoursWithoutForcingThreeHours() throws Exception {
        var root=new TimetableCellTranscription(mapper).normalize(mapper.readTree(valid.replace("null,null,false","\"09h00\",\"11h00\",false")),grid,batch);
        assertThat(root.path("slots").get(0).path("startTime").asText()).isEqualTo("09:00");
        assertThat(root.path("slots").get(0).path("timeEvidence").path("source").asText()).isEqualTo("EXPLICIT");
    }

    @Test void fridayPrintedRowHoursOverrideGenericHeadersAndPreserveTheMeasuredSpan() throws Exception {
        var input = (com.fasterxml.jackson.databind.node.ObjectNode) mapper.readTree(valid.replace("Lundi", "Vendredi"));
        input.set("columns", mapper.readTree("[[\"13:00\",\"14:30\"],[\"14:30\",\"16:00\"],[\"16:00\",\"17:30\"]]"));
        input.putObject("rowColumns").set("1", mapper.readTree("[[\"15:00\",\"16:30\"],[\"16:30\",\"18:00\"],[\"18:00\",\"19:30\"]]"));
        var normalized = new TimetableCellTranscription(mapper).normalize(input, grid, batch);
        var analyzer = new GroqScheduleAnalyzer(mapper, "unused", "vision", "http://localhost");
        var document = new ScheduleDocumentReader.Document(ma.emsi.emsidrive.schedule.entity.ScheduleSource.IMAGE, List.of());
        var friday = analyzer.parse(normalized.toString(), document).slots().get(0);
        assertThat(friday.startTime()).isEqualTo("15:00");
        assertThat(friday.endTime()).isEqualTo("18:00");
        assertThat(friday.needsReview()).isFalse();
        input.remove("rowColumns");
        var uncertain = analyzer.parse(new TimetableCellTranscription(mapper).normalize(input, grid, batch).toString(), document);
        assertThat(uncertain.slots().get(0).startTime()).isEqualTo("13:00");
        assertThat(uncertain.slots().get(0).needsReview()).isTrue();
        assertThat(uncertain.warnings()).anyMatch(w -> w.contains("vendredi"));
    }
}
