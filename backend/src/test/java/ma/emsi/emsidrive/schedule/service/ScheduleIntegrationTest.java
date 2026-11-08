package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.util.LinkedMultiValueMap;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Campus;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {"logging.level.root=WARN", "logging.level.ma.emsi=WARN", "logging.level.org.springframework=WARN"})
class ScheduleIntegrationTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");
    @DynamicPropertySource static void properties(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl); r.add("spring.datasource.username", POSTGRES::getUsername); r.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @Autowired TestRestTemplate client;
    @MockitoBean GroqScheduleAnalyzer analyzer;

    @Test void authenticatesAndIsolatesSchedulesValidatesEditsAndMatchesOnlyRealOffers() {
        String passenger = register(), other = register(), driver = register();
        var day = LocalDate.now(ScheduleService.ZONE).plusDays(1);
        var slot = new HashMap<String,Object>(Map.of("label","ERP", "weekday",day.getDayOfWeek().getValue(), "startTime","10:00", "endTime","11:30", "campus","TARGA"));
        var save = new HashMap<String,Object>(Map.of("name","Mon groupe", "source","MANUAL", "validFrom",day.toString(), "validUntil",day.plusDays(30).toString(), "confirmed",true, "revision",0, "slots",List.of(slot)));
        call(HttpMethod.GET,"/schedules/current",null,null,HttpStatus.UNAUTHORIZED);
        call(HttpMethod.GET,"/schedules/current",passenger,null,HttpStatus.NOT_FOUND);
        save.put("confirmed",false); call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.BAD_REQUEST); save.put("confirmed",true);
        slot.put("campus",null); call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.BAD_REQUEST); slot.put("campus","TARGA");
        save.put("slots",List.of(slot,slot));
        assertThat(call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.BAD_REQUEST).path("code").asText()).isEqualTo("SCHEDULE_OVERLAP");
        save.put("slots",List.of(slot));
        var saved = call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.OK);
        assertThat(saved.path("revision").asInt()).isEqualTo(1);
        assertThat(saved.path("slots").get(0).path("startTime").asText()).isEqualTo("10:00:00");
        call(HttpMethod.GET,"/schedules/current",other,null,HttpStatus.NOT_FOUND);
        call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.CONFLICT);
        save.put("revision",1); save.put("name","Updated");
        assertThat(call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.OK).path("revision").asInt()).isEqualTo(2);
        assertThat(call(HttpMethod.GET,"/schedules/suggestions",passenger,null,HttpStatus.OK)).isEmpty();
        call(HttpMethod.GET,"/schedules/suggestions?commuteMinutes=0",passenger,null,HttpStatus.BAD_REQUEST);
        String outbound = offer(driver,day,"09:00","TARGA",true);
        String returning = offer(driver,day,"11:45","TARGA",false);
        offer(driver,day,"09:00","CENTRE",true);
        offer(driver,day,"09:45","TARGA",true);
        offer(driver,day,"11:00","TARGA",false);
        offer(driver,day.plusDays(1),"09:00","TARGA",true);
        offer(passenger,day,"09:00","TARGA",true);
        var suggestions = call(HttpMethod.GET,"/schedules/suggestions",passenger,null,HttpStatus.OK);
        assertThat(suggestions.size()).isEqualTo(2);
        assertThat(suggestions.get(0).path("listing").path("id").asText()).isEqualTo(outbound);
        assertThat(suggestions.get(1).path("listing").path("id").asText()).isEqualTo(returning);
        assertThat(suggestions.get(0).path("toCampus").asBoolean()).isTrue();
        call(HttpMethod.POST,"/marketplace/listings/OFFER/" + outbound + "/accept",passenger,null,HttpStatus.OK);
        assertThat(call(HttpMethod.GET,"/schedules/suggestions",passenger,null,HttpStatus.OK).size()).isEqualTo(1);
        call(HttpMethod.DELETE,"/schedules/current",other,null,HttpStatus.NO_CONTENT);
        call(HttpMethod.GET,"/schedules/current",passenger,null,HttpStatus.OK);
        call(HttpMethod.DELETE,"/schedules/current",passenger,null,HttpStatus.NO_CONTENT);
        call(HttpMethod.GET,"/schedules/current",passenger,null,HttpStatus.NOT_FOUND);
    }
    @Test void analyzesActualMultipartImageWithoutAutomaticallySavingIt() throws Exception {
        String token = register();
        var image = new java.awt.image.BufferedImage(100,100,java.awt.image.BufferedImage.TYPE_INT_RGB);
        var out = new java.io.ByteArrayOutputStream(); javax.imageio.ImageIO.write(image,"png",out);
        when(analyzer.analyze(any(),eq("G1"))).thenReturn(new AnalysisResponse(ScheduleSource.IMAGE,"G1",List.of(new DraftSlot("ERP",null,1,"08:30","10:00",Campus.CENTRE,false)),List.of()));
        var form = new LinkedMultiValueMap<String,Object>();
        form.add("file",new ByteArrayResource(out.toByteArray()) { @Override public String getFilename() { return "timetable.png"; } }); form.add("group","G1");
        var headers = new HttpHeaders(); headers.setBearerAuth(token); headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        var response = client.exchange("/api/v1/schedules/analyze",HttpMethod.POST,new HttpEntity<>(form,headers),JsonNode.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().path("slots").size()).isEqualTo(1);
        verify(analyzer).analyze(argThat(d -> d.images().get(0).startsWith("data:image/png;base64,")),eq("G1"));
        call(HttpMethod.GET,"/schedules/current",token,null,HttpStatus.NOT_FOUND);
    }
    String register() {
        var response = client.postForEntity("/api/v1/auth/register",Map.of("email",UUID.randomUUID()+"@emsi-edu.ma","password","TestPass123!","fullName","Schedule Test"),JsonNode.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED); return response.getBody().path("accessToken").asText();
    }
    String offer(String token, LocalDate day, String hour, String campus, boolean toCampus) {
        return call(HttpMethod.POST,"/marketplace/listings",token,Map.of("kind","OFFER","campus",campus,"toCampus",toCampus,
                "point",Map.of("latitude",31.632123,"longitude",-8.011123),"departure",day.atTime(LocalTime.parse(hour)).atZone(ScheduleService.ZONE).toOffsetDateTime().toString(),"seats",2,"vehicle","CAR","notes","Schedule integration test"),HttpStatus.OK).path("id").asText();
    }
    JsonNode call(HttpMethod method,String path,String token,Object body,HttpStatus expected) {
        var headers = new HttpHeaders(); if (token != null) headers.setBearerAuth(token);
        var response = client.exchange("/api/v1" + path,method,new HttpEntity<>(body,headers),JsonNode.class);
        assertThat(response.getStatusCode()).as("%s %s %s",method,path,response.getBody()).isEqualTo(expected); return response.getBody();
    }
}
