package ma.emsi.emsidrive.schedule.service;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jsoup.Jsoup;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.assertj.core.api.Assertions.*;
class PaddleScheduleAnalyzerTest {
    final PaddleScheduleAnalyzer parser=new PaddleScheduleAnalyzer(new ObjectMapper(),"");
    final String head="<table><tr><th rowspan='2'>Jours</th><th>Seance 1</th><th>Seance 2</th><th>Seance 3</th></tr><tr><th>08h30 a 10h00</th><th>10h15 a 11h45</th><th>12h00 a 13h30</th></tr>";
    @Test void preservesMergedTimesAndDoesNotExtendIntoEmptyCells() {
        var table=Jsoup.parse(head+"<tr><td>Lundi</td><td colspan='2'>Cours</td><td></td></tr><tr><td>Mardi</td><td></td><td>Cours</td><td></td></tr></table>").selectFirst("table");
        var slots=parser.parseTable(table);
        assertThat(slots).hasSize(2);
        assertThat(slots.get(0).startTime()).isEqualTo("08:30");assertThat(slots.get(0).endTime()).isEqualTo("11:45");
        assertThat(slots.get(1).startTime()).isEqualTo("10:15");assertThat(slots.get(1).endTime()).isEqualTo("11:45");
        assertThat(slots.get(0).label()).isNull();assertThat(slots.get(0).location()).isNull();
    }
    @Test void printedTimesOverrideHeaderAndPauseIsIgnored() {
        var slots=parser.parseTable(Jsoup.parse(head+"<tr><td>Vendredi</td><td>Pause</td><td colspan='2'>Cours 15h00 a 18h15</td></tr></table>").selectFirst("table"));
        assertThat(slots).hasSize(1);assertThat(slots.get(0).weekday()).isEqualTo(5);
        assertThat(slots.get(0).startTime()).isEqualTo("15:00");assertThat(slots.get(0).endTime()).isEqualTo("18:15");
    }
    @Test void refusesUnreadableHeadersInsteadOfAssumingStandardEmsiTimes() {
        assertThat(parser.parseTable(Jsoup.parse("<table><tr><td>Lundi</td><td>Cours</td></tr></table>").selectFirst("table"))).isEmpty();
    }
    @Test void refusesMultipleTimetables() {
        var table=Jsoup.parse(head+"<tr><td>Lundi</td><td>Cours</td></tr></table>").selectFirst("table");
        var document=new ScheduleDocumentReader.Document(ma.emsi.emsidrive.schedule.entity.ScheduleSource.IMAGE,List.of());
        assertThatThrownBy(()->parser.parseTables(List.of(table,table),document,"G1")).hasMessageContaining("Crop");
    }
}
