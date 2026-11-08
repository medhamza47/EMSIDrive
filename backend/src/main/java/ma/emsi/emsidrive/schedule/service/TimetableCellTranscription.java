package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.*;
import java.time.LocalTime;
import java.util.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import org.springframework.http.HttpStatus;

/** Binds OCR text to measured cells. Model-generated durations/column positions are never used. */
final class TimetableCellTranscription {
    private final ObjectMapper mapper;
    TimetableCellTranscription(ObjectMapper mapper) { this.mapper=mapper; }

    ObjectNode normalize(JsonNode result, TimetableGridDetector.Grid grid, TimetableGridDetector.Batch batch) {
        if (result.path("ambiguous").asBoolean(false)) throw ApiException.badRequest("SCHEDULE_AMBIGUOUS","Select one timetable");
        var columns=result.path("columns");
        if (!columns.isArray() || columns.size()!=grid.borders().size()-1) throw invalid();
        var root=mapper.createObjectNode();root.put("isTimetable",true);root.put("ambiguous",false);root.set("name",result.path("name"));
        var headers=root.putArray("timeColumns");
        for(int i=0;i<columns.size();i++) {
            if(!columns.get(i).isArray() || columns.get(i).size()!=2)throw invalid();
            var header=headers.addObject();header.put("index",i+1);
            header.put("startTime",time(columns.get(i).get(0)));header.put("endTime",time(columns.get(i).get(1)));
        }
        var slots=root.putArray("slots");var days=result.path("weekdays");var cells=result.path("cells");
        if(!days.isObject() || !cells.isObject())throw invalid();
        var expectedDays=new HashSet<String>();batch.rows().forEach(r->expectedDays.add(String.valueOf(r.index())));
        var actualDays=new HashSet<String>();days.fieldNames().forEachRemaining(actualDays::add);
        var expectedCells=new HashSet<String>();batch.rows().forEach(r->r.cells().forEach(c->expectedCells.add(c.id())));
        var actualCells=new HashSet<String>();cells.fieldNames().forEachRemaining(actualCells::add);
        if(!expectedDays.equals(actualDays) || !expectedCells.equals(actualCells))throw invalid();
        for(var physical:batch.rows()) {
            Integer day=weekday(days.get(String.valueOf(physical.index())));
            for(var cell:physical.cells()) {
                var value=cells.get(cell.id());
                if(value.isNull())continue;
                if(!value.isArray() || value.size()!=6)throw invalid();
                var slot=slots.addObject();slot.set("label",value.get(0));slot.set("location",value.get(2));
                slot.put("weekday",day);
                slot.put("campus",value.get(1).isTextual()?value.get(1).asText().strip().toUpperCase(Locale.ROOT):null);
                String start=time(value.get(3)),end=time(value.get(4));
                slot.put("startTime",start);slot.put("endTime",end);
                slot.put("needsReview",!value.get(5).isBoolean() || value.get(5).asBoolean(true));
                var evidence=slot.putObject("timeEvidence");
                boolean explicit=start!=null || end!=null;
                evidence.put("source",explicit?"EXPLICIT":"HEADERS");
                evidence.put("spanCertain",!explicit || (start!=null && end!=null));
                evidence.put("startColumn",cell.first());evidence.put("endColumn",cell.last());
            }
        }
        return root;
    }

    static Integer weekday(JsonNode value) {
        if(value==null)return null;
        if(value.isIntegralNumber())return value.asInt()>=1 && value.asInt()<=7?value.asInt():null;
        return switch(value.asText().strip().toLowerCase(Locale.ROOT)) {
            case "lundi","monday" -> 1;case "mardi","tuesday" -> 2;case "mercredi","wednesday" -> 3;
            case "jeudi","thursday" -> 4;case "vendredi","friday" -> 5;case "samedi","saturday" -> 6;
            case "dimanche","sunday" -> 7;default -> null;
        };
    }

    static String time(JsonNode value) {
        if(value==null || !value.isTextual())return null;
        String text=value.asText().strip().toLowerCase(Locale.ROOT).replace('h',':').replace(" ","");
        if(!text.matches("\\d{1,2}:\\d{2}"))return null;
        var parts=text.split(":");
        try{return LocalTime.of(Integer.parseInt(parts[0]),Integer.parseInt(parts[1])).toString();}
        catch(RuntimeException ex){return null;}
    }
    static ApiException invalid(){return new ApiException(HttpStatus.BAD_GATEWAY,"SCHEDULE_AI_INVALID","Timetable cell transcription is incomplete or inconsistent");}
}
