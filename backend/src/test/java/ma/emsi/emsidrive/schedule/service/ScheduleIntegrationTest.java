package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.jdbc.core.JdbcTemplate;
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
@org.springframework.test.annotation.DirtiesContext(classMode = org.springframework.test.annotation.DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {"logging.level.root=WARN", "logging.level.ma.emsi=WARN", "logging.level.org.springframework=WARN"})
class ScheduleIntegrationTest {
    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");
    @DynamicPropertySource static void properties(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl); r.add("spring.datasource.username", POSTGRES::getUsername); r.add("spring.datasource.password", POSTGRES::getPassword);
    }
    @Autowired TestRestTemplate client;
    @Autowired JdbcTemplate jdbc;
    @Autowired com.fasterxml.jackson.databind.ObjectMapper mapper;
    @Autowired ScheduleService schedules;
    @Autowired ScheduleMatchingService matching;
    @Autowired ma.emsi.emsidrive.ride.marketplace.MarrakechArea area;
    @Autowired org.springframework.security.crypto.password.PasswordEncoder passwords;
    @MockitoBean GeminiScheduleAnalyzer analyzer;

    @BeforeEach void clearIsolatedTestDatabase() {
        // This datasource belongs to the dedicated PostgreSQLContainer above.
        jdbc.execute("TRUNCATE TABLE users CASCADE");
    }

    @Test void threeDevelopmentOffersMatchThePlanAndStayBookableWithoutResettingReservations() {
        String passenger = register();
        UUID owner = UUID.fromString(call(HttpMethod.GET, "/me", passenger, null, HttpStatus.OK).path("id").asText());
        var day = LocalDate.now(ScheduleService.ZONE).plusDays(1);
        call(HttpMethod.PUT, "/schedules/current", passenger, Map.of("name", "Présence", "source", "MANUAL", "revision", 0,
                "confirmed", true, "validFrom", day.toString(), "validUntil", day.plusDays(6).toString(),
                "slots", List.of(Map.of("weekday", day.getDayOfWeek().getValue(), "startTime", "10:00", "endTime", "18:00"))), HttpStatus.OK);
        call(HttpMethod.PUT, "/schedules/travel-preferences", passenger, Map.of("campus", "TARGA",
                "point", Map.of("latitude", 31.632123, "longitude", -8.011123), "radiusMeters", 2000,
                "commuteMinutes", 20, "marginMinutes", 10), HttpStatus.OK);
        // Production/default profiles do not expose fixture creation.
        call(HttpMethod.POST, "/schedules/demo-rides", passenger, null, HttpStatus.NOT_FOUND);
        var fixtures = new DemoRideService(jdbc, schedules, matching, area, passwords);
        var ids = fixtures.seed(owner);
        assertThat(ids).hasSize(3);
        assertThat(fixtures.seed(owner)).containsExactlyElementsOf(ids);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM ride_offers", Integer.class)).isEqualTo(3);
        var matches = call(HttpMethod.GET, "/schedules/matches", passenger, null, HttpStatus.OK);
        assertThat(matches.size()).isEqualTo(3);
        assertThat(matches.get(0).path("listing").path("author").asText()).contains("TEST");
        UUID first = ids.get(0);
        call(HttpMethod.POST, "/marketplace/listings/OFFER/" + first + "/accept", passenger, null, HttpStatus.OK);
        fixtures.seed(owner);
        assertThat(jdbc.queryForObject("SELECT available_seats FROM ride_offers WHERE id=?", Integer.class, first)).isZero();
        assertThat(call(HttpMethod.GET, "/schedules/matches", passenger, null, HttpStatus.OK).size()).isEqualTo(2);
    }

    @Test void authenticatesAndIsolatesSchedulesValidatesEditsAndMatchesOnlyRealOffers() {
        String passenger = register(), other = register(), driver = register();
        var day = LocalDate.now(ScheduleService.ZONE).plusDays(1);
        var slot = new HashMap<String,Object>(Map.of("label","ERP", "weekday",day.getDayOfWeek().getValue(), "startTime","10:00", "endTime","11:30", "campus","TARGA"));
        var save = new HashMap<String,Object>(Map.of("name","Mon groupe", "source","MANUAL", "validFrom",day.toString(), "validUntil",day.plusDays(30).toString(), "confirmed",true, "revision",0, "slots",List.of(slot)));
        call(HttpMethod.GET,"/schedules/current",null,null,HttpStatus.UNAUTHORIZED);
        call(HttpMethod.GET,"/schedules/current",passenger,null,HttpStatus.NOT_FOUND);
        save.put("confirmed",false); call(HttpMethod.PUT,"/schedules/current",passenger,save,HttpStatus.BAD_REQUEST); save.put("confirmed",true);
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
    @Test void persistsTimesWithoutMetadataAndMatchesBothCampusesWithoutPreference() {
        String passenger = register(), driver = register();
        var day = LocalDate.now(ScheduleService.ZONE).plusDays(1);
        var slot = Map.of("weekday", day.getDayOfWeek().getValue(), "startTime", "10:00", "endTime", "11:30");
        var save = Map.of("name", "Horaires", "source", "MANUAL", "revision", 0, "confirmed", true,
                "validFrom", day.toString(), "validUntil", day.plusDays(7).toString(), "slots", List.of(slot));
        var saved = call(HttpMethod.PUT, "/schedules/current", passenger, save, HttpStatus.OK);
        assertThat(saved.path("slots").get(0).path("campus").isNull()).isTrue();
        assertThat(saved.path("slots").get(0).path("location").isNull()).isTrue();
        offer(driver, day, "09:00", "TARGA", true);
        offer(driver, day, "09:00", "CENTRE", true);
        assertThat(call(HttpMethod.GET, "/schedules/suggestions", passenger, null, HttpStatus.OK).size()).isEqualTo(2);
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

    @Test void importReturnsBeforeAnalysisAndCanBeResumedOnlyByItsOwner() throws Exception {
        String user = register(), other = register();
        var release = new java.util.concurrent.CountDownLatch(1);
        when(analyzer.analyze(any(), eq("G1"))).thenAnswer(call -> {
            release.await(8, java.util.concurrent.TimeUnit.SECONDS);
            return new AnalysisResponse(ScheduleSource.IMAGE, "G1", List.of(new DraftSlot(null,null,1,"08:30","16:30",null,false)), List.of());
        });
        try {
            var job = uploadJob(user);
            String id = job.path("id").asText();
            assertThat(job.path("status").asText()).isIn("QUEUED", "PROCESSING");
            assertThat(uploadJob(user).path("id").asText()).isEqualTo(id);
            call(HttpMethod.GET, "/schedules/imports/" + id, other, null, HttpStatus.NOT_FOUND);
            assertThat(call(HttpMethod.GET, "/schedules/imports/latest", user, null, HttpStatus.OK).path("id").asText()).isEqualTo(id);
            call(HttpMethod.GET, "/schedules/current", user, null, HttpStatus.NOT_FOUND);
            release.countDown();
            var complete = awaitJob(user, id, "SUCCEEDED");
            assertThat(complete.path("draft").path("slots").get(0).path("endTime").asText()).isEqualTo("16:30");
            assertThat(jdbc.queryForObject("SELECT payload FROM schedule_import_jobs WHERE id = ?", String.class, UUID.fromString(id))).isNull();
            var today = LocalDate.now(ScheduleService.ZONE);
            var save = new HashMap<String,Object>(Map.of("name","Présence", "source","IMAGE", "revision",0, "confirmed",true,
                    "validFrom",today.toString(), "validUntil",today.plusDays(7).toString(), "analysisJobId",id,
                    "slots", List.of(Map.of("weekday",1,"startTime","08:30","endTime","16:30"))));
            call(HttpMethod.PUT, "/schedules/current", user, save, HttpStatus.OK);
            assertThat(call(HttpMethod.GET, "/schedules/imports/latest", user, null, HttpStatus.OK)).isNull();
            verify(analyzer, times(1)).analyze(any(), eq("G1"));
        } finally { release.countDown(); }
    }

    @Test void cancelledImportCannotPublishALateResult() throws Exception {
        String user = register();
        var started = new java.util.concurrent.CountDownLatch(1);
        var release = new java.util.concurrent.CountDownLatch(1);
        when(analyzer.analyze(any(), eq("G1"))).thenAnswer(call -> {
            started.countDown(); release.await(8, java.util.concurrent.TimeUnit.SECONDS);
            return new AnalysisResponse(ScheduleSource.IMAGE,"G1",List.of(),List.of());
        });
        try {
            var job = uploadJob(user); String id = job.path("id").asText();
            assertThat(started.await(5, java.util.concurrent.TimeUnit.SECONDS)).isTrue();
            call(HttpMethod.DELETE, "/schedules/imports/" + id, user, null, HttpStatus.NO_CONTENT);
            release.countDown();
            assertThat(call(HttpMethod.GET, "/schedules/imports/" + id, user, null, HttpStatus.OK).path("status").asText()).isEqualTo("CANCELLED");
            assertThat(jdbc.queryForObject("SELECT payload FROM schedule_import_jobs WHERE id = ?", String.class, UUID.fromString(id))).isNull();
        } finally { release.countDown(); }
    }

    @Test void workerRecoversAnImportWhosePreviousProcessLostItsLease() throws Exception {
        String token = register();
        UUID user = UUID.fromString(call(HttpMethod.GET,"/me",token,null,HttpStatus.OK).path("id").asText());
        UUID id = UUID.randomUUID();
        when(analyzer.analyze(any(), eq("G1"))).thenReturn(new AnalysisResponse(ScheduleSource.IMAGE,"G1",
                List.of(new DraftSlot(null,null,1,"08:30","16:30",null,false)), List.of()));
        String payload = mapper.writeValueAsString(new ScheduleDocumentReader.Document(ScheduleSource.IMAGE,List.of("data:image/png;base64,AA==")));
        jdbc.update("""
                INSERT INTO schedule_import_jobs(id,user_id,status,document_hash,group_name,revision,payload,lease_token,lease_until)
                VALUES (?,?,'PROCESSING','fixture','G1',0,?,?,now()-interval '2 minutes')
                """, id,user,payload,UUID.randomUUID());
        var result = awaitJob(token,id.toString(),"SUCCEEDED");
        assertThat(result.path("draft").path("slots").get(0).path("startTime").asText()).isEqualTo("08:30");
        assertThat(jdbc.queryForObject("SELECT payload FROM schedule_import_jobs WHERE id=?",String.class,id)).isNull();
    }

    @Test void matchesOnlyNearbyOffersAtTheChosenCampusAndCompatibleTimes() {
        String passenger = register(), driver = register(), other = register();
        var day = LocalDate.now(ScheduleService.ZONE).plusDays(1);
        call(HttpMethod.PUT,"/schedules/current",passenger, Map.of("name","Présence","source","MANUAL","revision",0,"confirmed",true,
                "validFrom",day.toString(),"validUntil",day.plusDays(7).toString(),
                "slots",List.of(Map.of("weekday",day.getDayOfWeek().getValue(),"startTime","10:00","endTime","11:30"))), HttpStatus.OK);
        assertThat(call(HttpMethod.GET,"/schedules/matches",passenger,null,HttpStatus.BAD_REQUEST).path("code").asText()).isEqualTo("SCHEDULE_TRAVEL_REQUIRED");
        call(HttpMethod.PUT,"/schedules/travel-preferences",passenger,Map.of("campus","TARGA",
                "point",Map.of("latitude",31.632123,"longitude",-8.011123),"radiusMeters",1000,"commuteMinutes",30,"marginMinutes",10),HttpStatus.OK);
        assertThat(call(HttpMethod.GET,"/schedules/travel-preferences",other,null,HttpStatus.OK)).isNull();
        String near = offer(driver,day,"09:00","TARGA",true);
        String returning = offer(driver,day,"11:45","TARGA",false);
        offer(driver,day,"09:00","CENTRE",true);
        offer(driver,day,"09:45","TARGA",true);
        call(HttpMethod.POST,"/marketplace/listings",driver,Map.of("kind","OFFER","campus","TARGA","toCampus",true,
                "point",Map.of("latitude",31.632123,"longitude",-8.041123),
                "departure",day.atTime(9,0).atZone(ScheduleService.ZONE).toOffsetDateTime().toString(),"seats",2,"vehicle","CAR"),HttpStatus.OK);
        var matches = call(HttpMethod.GET,"/schedules/matches",passenger,null,HttpStatus.OK);
        assertThat(matches.size()).isEqualTo(2);
        assertThat(matches.get(0).path("listing").path("id").asText()).isEqualTo(near);
        assertThat(matches.get(1).path("listing").path("id").asText()).isEqualTo(returning);
        assertThat(matches.get(0).path("distanceMeters").asInt()).isLessThan(5);
        call(HttpMethod.POST,"/marketplace/listings/OFFER/"+near+"/accept",passenger,null,HttpStatus.OK);
        assertThat(call(HttpMethod.GET,"/schedules/matches",passenger,null,HttpStatus.OK).size()).isEqualTo(1);
    }

    JsonNode uploadJob(String token) throws Exception {
        var image = new java.awt.image.BufferedImage(100,100,java.awt.image.BufferedImage.TYPE_INT_RGB);
        var out = new java.io.ByteArrayOutputStream(); javax.imageio.ImageIO.write(image,"png",out);
        var form = new LinkedMultiValueMap<String,Object>();
        form.add("file",new ByteArrayResource(out.toByteArray()) { @Override public String getFilename() { return "timetable.png"; } });
        form.add("group","G1"); form.add("revision","0");
        return call(HttpMethod.POST,"/schedules/imports",token,form,HttpStatus.ACCEPTED);
    }

    JsonNode awaitJob(String token, String id, String expected) throws Exception {
        for (int attempt=0;attempt<80;attempt++) {
            var job = call(HttpMethod.GET,"/schedules/imports/"+id,token,null,HttpStatus.OK);
            if (job.path("status").asText().equals(expected)) return job;
            if (job.path("status").asText().equals("FAILED")) fail("Import failed: %s",job.path("errorCode"));
            Thread.sleep(100);
        }
        throw new AssertionError("Import did not reach " + expected);
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
