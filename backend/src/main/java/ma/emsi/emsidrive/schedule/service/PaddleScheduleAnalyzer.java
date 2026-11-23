package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.*;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.*;
import java.util.regex.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Element;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

/** Reads table structure from PaddleOCR-VL; never invents the EMSI header times. */
@Component
public class PaddleScheduleAnalyzer {
    private final ObjectMapper mapper;
    private final String url;
    private final HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
    private static final Pattern TIME = Pattern.compile("(?<!\\d)([0-2]?\\d)\\s*[:hH]\\s*([0-5]\\d)(?!\\d)");
    public PaddleScheduleAnalyzer(ObjectMapper mapper, @Value("${app.schedule.paddle-url:${PADDLE_OCR_URL:}}") String url) {
        this.mapper=mapper; this.url=url;
    }
    public boolean enabled() { return !url.isBlank(); }
    public AnalysisResponse analyze(ScheduleDocumentReader.Document document, String group) {
        var tables = new ArrayList<Element>();
        try {
            for (String image : document.images()) {
                String encoded = image.substring(image.indexOf(',')+1);
                var request = HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofMinutes(10))
                    .header("Content-Type","application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(Map.of("file",encoded,"fileType",1,"visualize",false,"returnMarkdownImages",false)))).build();
                var response=client.send(request,HttpResponse.BodyHandlers.ofString());
                if(response.statusCode()!=200) throw unavailable();
                var root=mapper.readTree(response.body());
                if(root.path("errorCode").asInt(0)!=0) throw unavailable();
                for(var page:root.path("result").path("layoutParsingResults"))
                    for(var block:page.path("prunedResult").path("parsing_res_list"))
                        if("table".equals(block.path("block_label").asText()))
                            tables.addAll(Jsoup.parse(block.path("block_content").asText()).select("table"));
            }
            return parseTables(tables,document,group);
        } catch(InterruptedException ex) { Thread.currentThread().interrupt(); throw unavailable(); }
        catch(java.io.IOException ex) { throw unavailable(); }
    }
    AnalysisResponse parseTables(List<Element> tables, ScheduleDocumentReader.Document document, String group) {
        var candidates=new ArrayList<List<DraftSlot>>();
        for(var table:tables) { var slots=parseTable(table); if(!slots.isEmpty()) candidates.add(slots); }
        if(candidates.isEmpty()) throw ApiException.badRequest("SCHEDULE_NOT_TIMETABLE","No readable timetable; crop one table with visible headers");
        if(candidates.size()!=1) throw ApiException.badRequest("SCHEDULE_AMBIGUOUS","Crop the photo to exactly one timetable");
        return new AnalysisResponse(document.source(),group,candidates.get(0),List.of("PaddleOCR-VL: verify all times against the original, especially hidden or reflective cells."));
    }
    record Cell(String text,int first,int last) {}
    List<DraftSlot> parseTable(Element table) {
        var rows=new ArrayList<List<Cell>>(); var occupied=new HashMap<Integer,Integer>();
        for(var tr:table.select("tr")) {
            var row=new ArrayList<Cell>(); int col=0;
            for(var td:tr.children()) {
                if(!Set.of("td","th").contains(td.tagName()))continue;
                while(occupied.getOrDefault(col,0)>0)col++;
                int span=span(td,"colspan"),height=span(td,"rowspan");
                row.add(new Cell(td.text(),col,col+span-1));
                if(height>1) for(int c=col;c<col+span;c++) occupied.put(c,height);
                col+=span; if(col>32)return List.of();
            }
            rows.add(row); occupied.replaceAll((k,v)->Math.max(0,v-1));
        }
        var headers=new HashMap<Integer,List<String>>();
        for(var row:rows) {
            if(row.stream().anyMatch(c->day(c.text())!=null))break;
            for(var c:row) { var t=times(c.text()); if(c.first()==c.last()&&t.size()==2&&t.get(0).compareTo(t.get(1))<0)headers.put(c.first(),t); }
        }
        if(headers.isEmpty())return List.of();
        var slots=new ArrayList<DraftSlot>();
        for(var row:rows) {
            var label=row.stream().filter(c->day(c.text())!=null).findFirst(); if(label.isEmpty())continue;
            for(var c:row) {
                if(c.first()<=label.get().last()||c.text().isBlank()||c.text().matches("(?i)^(pause|repos|libre|vacances|[-–]+)$"))continue;
                var explicit=times(c.text());String start=null,end=null;
                if(explicit.size()==2&&explicit.get(0).compareTo(explicit.get(1))<0) { start=explicit.get(0);end=explicit.get(1); }
                else { if(headers.containsKey(c.first()))start=headers.get(c.first()).get(0);if(headers.containsKey(c.last()))end=headers.get(c.last()).get(1); }
                if(start!=null||end!=null)slots.add(new DraftSlot(null,null,day(label.get().text()),start,end,null,true));
            }
        }
        if(slots.size()>80)return List.of();
        slots.sort(Comparator.comparing(DraftSlot::weekday).thenComparing(DraftSlot::startTime,Comparator.nullsLast(Comparator.naturalOrder())));
        return slots;
    }
    private static int span(Element e,String name) { try{return Math.max(1,Math.min(32,Integer.parseInt(e.attr(name))));}catch(NumberFormatException ex){return 1;} }
    private static List<String> times(String text) {
        var values=new ArrayList<String>();var m=TIME.matcher(text);
        while(m.find()) {int h=Integer.parseInt(m.group(1));if(h<24)values.add(String.format(Locale.ROOT,"%02d:%s",h,m.group(2)));}return values;
    }
    private static Integer day(String text) {
        String s=text.strip().toLowerCase(Locale.ROOT);String[] days={"lundi","mardi","mercredi","jeudi","vendredi","samedi","dimanche"};
        String[] en={"monday","tuesday","wednesday","thursday","friday","saturday","sunday"};
        for(int i=0;i<7;i++)if(s.matches("^("+days[i]+"|"+en[i]+")\\b.*"))return i+1;return null;
    }
    private static ApiException unavailable(){return new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"SCHEDULE_AI_UNAVAILABLE","PaddleOCR service is not ready");}
}
