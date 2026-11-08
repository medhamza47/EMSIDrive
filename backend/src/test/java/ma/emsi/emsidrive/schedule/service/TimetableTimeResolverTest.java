package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class TimetableTimeResolverTest {
    final ObjectMapper mapper = new ObjectMapper();
    final String headers = """
        [{"index":1,"startTime":"08:30","endTime":"10:00"},
         {"index":2,"startTime":"10:00","endTime":"11:30"},
         {"index":3,"startTime":"12:00","endTime":"13:30"}]
        """;
    TimetableTimeResolver.Times resolve(String columns, String source, int first, int last, boolean certain) throws Exception {
        var row = mapper.readTree("""
            {"startTime":"08:30","endTime":"10:00","timeEvidence":
             {"source":"%s","startColumn":%d,"endColumn":%d,"spanCertain":%s}}
            """.formatted(source, first, last, certain));
        return new TimetableTimeResolver(mapper.readTree(columns)).resolve(row);
    }
    @Test void singleSessionStaysNinetyMinutes() throws Exception {
        assertThat(resolve(headers,"HEADERS",1,1,true)).isEqualTo(new TimetableTimeResolver.Times("08:30","10:00",false));
    }
    @Test void doubleSessionUsesLastColumnEvenWhenModelCopiedFirstEndTime() throws Exception {
        assertThat(resolve(headers,"HEADERS",1,2,true)).isEqualTo(new TimetableTimeResolver.Times("08:30","11:30",false));
    }
    @Test void preservesRealHeaderEndIncludingBreakRatherThanAddingThreeHours() throws Exception {
        var withBreak = headers.replace("\"10:00\",\"endTime\":\"11:30\"", "\"10:15\",\"endTime\":\"11:45\"");
        assertThat(resolve(withBreak,"HEADERS",1,2,true).end()).isEqualTo("11:45");
    }
    @Test void explicitCellHoursOverrideMergedColumnSpan() throws Exception {
        assertThat(resolve(headers,"EXPLICIT",1,2,true).end()).isEqualTo("10:00");
    }
    @Test void uncertainMissingOrInvalidSpanNeverDefaultsToFirstHalf() throws Exception {
        for (var times : java.util.List.of(resolve(headers,"HEADERS",1,2,false), resolve(headers,"UNCERTAIN",1,2,true),
                resolve(headers,"HEADERS",1,8,true), resolve(headers,"HEADERS",2,1,true), resolve("[]","HEADERS",1,2,true))) {
            assertThat(times.needsReview()).isTrue(); assertThat(times.end()).isNull();
        }
        var row = mapper.readTree("{\"startTime\":\"08:30\",\"endTime\":\"10:00\"}");
        assertThat(new TimetableTimeResolver(mapper.readTree(headers)).resolve(row).needsReview()).isTrue();
    }
    @Test void rejectsDuplicateOrOverlappingHeaderColumns() throws Exception {
        for (var invalid : java.util.List.of(headers.replace("\"index\":2","\"index\":1"), headers.replace("\"10:00\",\"endTime\":\"11:30\"","\"09:00\",\"endTime\":\"11:30\""))) {
            assertThat(resolve(invalid,"HEADERS",1,2,true).end()).isNull();
        }
    }
}
