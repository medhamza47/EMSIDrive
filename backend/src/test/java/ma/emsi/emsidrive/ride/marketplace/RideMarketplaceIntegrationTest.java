package ma.emsi.emsidrive.ride.marketplace;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.OffsetDateTime;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@org.springframework.test.annotation.DirtiesContext(classMode = org.springframework.test.annotation.DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class RideMarketplaceIntegrationTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired
    private TestRestTemplate client;

    @Test
    void acceptingEitherKindCreatesAPrivateTripAndNotifiesItsAuthor() {
        String driver = register("driver");
        String passenger = register("passenger");
        String other = register("observer");
        Map<String, Object> point = Map.of("latitude", 31.632123, "longitude", -8.011123);

        String request = publish(passenger, "REQUEST", point);
        String offer = publish(driver, "OFFER", point);
        assertThat(exchange(HttpMethod.GET, "/listings?kind=REQUEST", driver, null, HttpStatus.OK).get(0)
                .path("id").asText()).isEqualTo(request);
        assertThat(exchange(HttpMethod.GET, "/listings?kind=OFFER", passenger, null, HttpStatus.OK).get(0)
                .path("id").asText()).isEqualTo(offer);
        var publicListing = exchange(HttpMethod.GET, "/listings/REQUEST/" + request, other, null, HttpStatus.OK);
        assertThat(publicListing.path("origin_latitude").asDouble()).isEqualTo(31.632);
        assertThat(publicListing.has("partner_phone")).isFalse();

        exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept", passenger, null, HttpStatus.CONFLICT);
        String ride = exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept",
                driver, null, HttpStatus.OK).path("id").asText();
        assertThat(exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept",
                driver, null, HttpStatus.OK).path("id").asText()).isEqualTo(ride);
        exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept", other, null, HttpStatus.CONFLICT);

        var notices = exchange(HttpMethod.GET, "/notifications", passenger, null, HttpStatus.OK);
        assertThat(notices.size()).isEqualTo(1);
        assertThat(notices.get(0).path("booking_id").asText()).isEqualTo(ride);
        exchange(HttpMethod.PUT, "/notifications/" + notices.get(0).path("id").asText() + "/read",
                passenger, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, "/notifications", passenger, null, HttpStatus.OK).get(0)
                .path("seen").asBoolean()).isTrue();

        String trip = "/trips/" + ride;
        var accepted = exchange(HttpMethod.GET, trip, passenger, null, HttpStatus.OK);
        assertThat(accepted.path("origin_latitude").asDouble()).isEqualTo(31.632123);
        assertThat(accepted.path("is_driver").asBoolean()).isFalse();
        assertThat(accepted.path("partner_phone").asText()).isEqualTo("+212612345678");
        exchange(HttpMethod.GET, trip, other, null, HttpStatus.NOT_FOUND);
        exchange(HttpMethod.POST, trip + "/messages", driver, Map.of("body", "On my way"), HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, trip + "/messages", passenger, null, HttpStatus.OK).get(0)
                .path("body").asText()).isEqualTo("On my way");
        exchange(HttpMethod.GET, trip + "/messages", other, null, HttpStatus.NOT_FOUND);
        var fix = Map.of("latitude", 31.632123, "longitude", -8.011123,
                "capturedAt", java.time.Instant.now().toString(), "accuracy", 10);
        exchange(HttpMethod.PUT, trip + "/location", passenger, fix, HttpStatus.FORBIDDEN);
        exchange(HttpMethod.PUT, trip + "/location", driver, fix, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, trip, passenger, null, HttpStatus.OK)
                .path("live_latitude").asDouble()).isEqualTo(31.632123);
        exchange(HttpMethod.DELETE, trip + "/location", driver, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, trip, passenger, null, HttpStatus.OK)
                .path("live_latitude").isNull()).isTrue();

        String reserved = exchange(HttpMethod.POST, "/listings/OFFER/" + offer + "/accept",
                passenger, null, HttpStatus.OK).path("id").asText();
        assertThat(exchange(HttpMethod.GET, "/notifications", driver, null, HttpStatus.OK).get(0)
                .path("booking_id").asText()).isEqualTo(reserved);
        exchange(HttpMethod.POST, "/listings/OFFER/" + offer + "/accept", other, null, HttpStatus.CONFLICT);
    }

    @Test
    void trackingProtectsLocationAndEnforcesJourneyOrder() {
        String driver = register("trackingDriver");
        String passenger = register("trackingPassenger");
        String outsider = register("trackingOutsider");
        var point = Map.<String, Object>of("latitude", 31.632123, "longitude", -8.011123);
        String offer = publish(driver, "OFFER", point);
        String id = exchange(HttpMethod.POST, "/listings/OFFER/" + offer + "/accept", passenger, null, HttpStatus.OK).path("id").asText();
        String path = "/trips/" + id;
        exchange(HttpMethod.PUT, path + "/state", outsider, Map.of("state", "EN_ROUTE"), HttpStatus.NOT_FOUND);
        exchange(HttpMethod.PUT, path + "/state", passenger, Map.of("state", "EN_ROUTE"), HttpStatus.FORBIDDEN);
        exchange(HttpMethod.PUT, path + "/state", driver, Map.of("state", "COMPLETED"), HttpStatus.CONFLICT);
        var now = java.time.Instant.now();
        exchange(HttpMethod.PUT, path + "/location", driver, Map.of("latitude", 31.632123, "longitude", -8.011123,
                "capturedAt", now.minusSeconds(40).toString(), "accuracy", 10), HttpStatus.BAD_REQUEST);
        exchange(HttpMethod.PUT, path + "/location", driver, Map.of("latitude", 31.632123, "longitude", -8.011123,
                "capturedAt", now.toString(), "accuracy", 10), HttpStatus.OK);
        exchange(HttpMethod.PUT, path + "/location", driver, Map.of("latitude", 31.633, "longitude", -8.012,
                "capturedAt", now.minusSeconds(5).toString(), "accuracy", 10), HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, path, passenger, null, HttpStatus.OK).path("live_latitude").asDouble()).isEqualTo(31.632123);
        for (String stage : new String[]{"EN_ROUTE", "ARRIVED", "IN_PROGRESS", "COMPLETED"}) {
            assertThat(exchange(HttpMethod.PUT, path + "/state", driver, Map.of("state", stage), HttpStatus.OK)
                    .path("tracking_state").asText()).isEqualTo(stage);
            exchange(HttpMethod.PUT, path + "/state", driver, Map.of("state", stage), HttpStatus.OK);
        }
        assertThat(exchange(HttpMethod.GET, path, passenger, null, HttpStatus.OK).path("live_latitude").isNull()).isTrue();
        assertThat(exchange(HttpMethod.GET, path, passenger, null, HttpStatus.OK).path("partner_phone").isNull()).isTrue();
        exchange(HttpMethod.PUT, path + "/location", driver, Map.of("latitude", 31.632123, "longitude", -8.011123,
                "capturedAt", java.time.Instant.now().toString(), "accuracy", 10), HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, path + "/state", passenger, Map.of("state", "CANCELLED"), HttpStatus.CONFLICT);
        assertThat(exchange(HttpMethod.GET, "/notifications", passenger, null, HttpStatus.OK).toString()).contains("RIDE_ARRIVED", "RIDE_COMPLETED");
    }

    @Test
    void cancellingReleasesOneSeatAndAllowsRebooking() {
        String driver = register("cancelDriver");
        String passenger = register("cancelPassenger");
        String other = register("cancelOther");
        String offer = publish(driver, "OFFER", Map.of("latitude", 31.632123, "longitude", -8.011123));
        String accept = "/listings/OFFER/" + offer + "/accept";
        String id = exchange(HttpMethod.POST, accept, passenger, null, HttpStatus.OK).path("id").asText();
        for (int i = 0; i < 2; i++) exchange(HttpMethod.PUT, "/trips/" + id + "/state", passenger, Map.of("state", "CANCELLED"), HttpStatus.OK);
        assertThat(exchange(HttpMethod.POST, accept, passenger, null, HttpStatus.OK).path("id").asText()).isEqualTo(id);
        exchange(HttpMethod.POST, accept, other, null, HttpStatus.CONFLICT);
    }

    private String publish(String token, String kind, Map<String, Object> point) {
        return exchange(HttpMethod.POST, "/listings", token, Map.of(
                "kind", kind, "campus", "CENTRE", "toCampus", true, "point", point,
                "departure", OffsetDateTime.now().plusHours(1).toString(),
                "seats", 1, "vehicle", "CAR", "notes", "Test listing"), HttpStatus.OK)
                .path("id").asText();
    }

    private String register(String name) {
        var response = client.postForEntity("/api/v1/auth/register", Map.of(
                "email", name + "@emsi-edu.ma", "password", "TestPass123!", "fullName", name,
                "phoneNumber", "+212612345678"), JsonNode.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return response.getBody().path("accessToken").asText();
    }

    private JsonNode exchange(HttpMethod method, String path, String token, Object body, HttpStatus expected) {
        var headers = new HttpHeaders();
        headers.setBearerAuth(token);
        var response = client.exchange("/api/v1/marketplace" + path, method,
                new HttpEntity<>(body, headers), JsonNode.class);
        assertThat(response.getStatusCode()).as("%s %s: %s", method, path, response.getBody())
                .isEqualTo(expected);
        return response.getBody();
    }
}
