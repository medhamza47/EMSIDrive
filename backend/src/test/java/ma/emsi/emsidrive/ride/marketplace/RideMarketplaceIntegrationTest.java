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
        exchange(HttpMethod.GET, trip, other, null, HttpStatus.NOT_FOUND);
        exchange(HttpMethod.POST, trip + "/messages", driver, Map.of("body", "On my way"), HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, trip + "/messages", passenger, null, HttpStatus.OK).get(0)
                .path("body").asText()).isEqualTo("On my way");
        exchange(HttpMethod.GET, trip + "/messages", other, null, HttpStatus.NOT_FOUND);
        exchange(HttpMethod.PUT, trip + "/location", passenger, point, HttpStatus.FORBIDDEN);
        exchange(HttpMethod.PUT, trip + "/location", driver, point, HttpStatus.OK);
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

    private String publish(String token, String kind, Map<String, Object> point) {
        return exchange(HttpMethod.POST, "/listings", token, Map.of(
                "kind", kind, "campus", "CENTRE", "toCampus", true, "point", point,
                "departure", OffsetDateTime.now().plusHours(1).toString(),
                "seats", 1, "vehicle", "CAR", "notes", "Test listing"), HttpStatus.OK)
                .path("id").asText();
    }

    private String register(String name) {
        var response = client.postForEntity("/api/v1/auth/register", Map.of(
                "email", name + "@emsi-edu.ma", "password", "TestPass123!", "fullName", name), JsonNode.class);
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
