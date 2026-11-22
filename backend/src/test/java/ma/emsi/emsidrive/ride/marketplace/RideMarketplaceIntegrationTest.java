package ma.emsi.emsidrive.ride.marketplace;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import java.math.BigDecimal;
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

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void offersValidateOwnedVehiclesAndKeepTheirPublishedDescription() {
        String driver = register("vehicleDriver");
        String other = register("vehicleOther");
        var headers = new HttpHeaders();
        headers.setBearerAuth(driver);
        var created = client.exchange("/api/v1/me/vehicles", HttpMethod.POST, new HttpEntity<>(Map.of(
                "type", "VOITURE", "brand", "Dacia", "model", "Sandero", "color", "Blue", "seats", 2), headers), JsonNode.class);
        assertThat(created.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        String vehicle = created.getBody().path("id").asText();
        var input = new java.util.HashMap<String, Object>(Map.of(
                "kind", "OFFER", "campus", "CENTRE", "toCampus", true,
                "point", Map.of("latitude", 31.632123, "longitude", -8.011123),
                "departure", OffsetDateTime.now().plusHours(1).toString(),
                "seats", 2, "vehicle", "CAR", "vehicleId", vehicle));
        exchange(HttpMethod.POST, "/listings", other, input, HttpStatus.BAD_REQUEST);
        input.put("seats", 3);
        exchange(HttpMethod.POST, "/listings", driver, input, HttpStatus.BAD_REQUEST);
        input.put("seats", 2);
        input.put("vehicle", "MOTO");
        exchange(HttpMethod.POST, "/listings", driver, input, HttpStatus.BAD_REQUEST);
        input.put("vehicle", "CAR");
        String offer = exchange(HttpMethod.POST, "/listings", driver, input, HttpStatus.OK).path("id").asText();
        var listing = exchange(HttpMethod.GET, "/listings/OFFER/" + offer, other, null, HttpStatus.OK);
        assertThat(listing.path("vehicle_brand").asText()).isEqualTo("Dacia");
        assertThat(listing.path("vehicle_color").asText()).isEqualTo("Blue");
        client.exchange("/api/v1/me/vehicles/" + vehicle, HttpMethod.DELETE, new HttpEntity<>(headers), Void.class);
        listing = exchange(HttpMethod.GET, "/listings/OFFER/" + offer, other, null, HttpStatus.OK);
        assertThat(listing.path("vehicle_id").isNull()).isTrue();
        assertThat(listing.path("vehicle_model").asText()).isEqualTo("Sandero");
    }

    @Test
    void completedRideHasPrivateSummaryReviewsAndExactSharedCosts() throws Exception {
        String driver = register("summaryDriver"), passenger = register("summaryPassenger"),
                second = register("summarySecond"), observer = register("summaryObserver");
        String offer = publish(driver, "OFFER", Map.of("latitude", 31.632123, "longitude", -8.011123), 2);
        String firstId = exchange(HttpMethod.POST, "/listings/OFFER/" + offer + "/accept", passenger, null, HttpStatus.OK).path("id").asText();
        String secondId = exchange(HttpMethod.POST, "/listings/OFFER/" + offer + "/accept", second, null, HttpStatus.OK).path("id").asText();
        String trip = "/trips/" + firstId;
        exchange(HttpMethod.GET, trip + "/summary", passenger, null, HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, trip + "/review", passenger, Map.of("score", 5), HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "10.00"), HttpStatus.CONFLICT);
        exchange(HttpMethod.POST, trip + "/actions/START", driver, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/messages", passenger, Map.of("body", "Arrived"), HttpStatus.OK);
        exchange(HttpMethod.PUT, trip + "/location", driver, Map.of("latitude", 31.632123, "longitude", -8.011123), HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.OK);
        exchange(HttpMethod.GET, trip + "/summary", observer, null, HttpStatus.NOT_FOUND);
        exchange(HttpMethod.PUT, trip + "/review", observer, Map.of("score", 5), HttpStatus.NOT_FOUND);
        exchange(HttpMethod.PUT, trip + "/costs", passenger, Map.of("total", "10.00"), HttpStatus.FORBIDDEN);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "-1.00"), HttpStatus.BAD_REQUEST);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "1.001"), HttpStatus.BAD_REQUEST);
        exchange(HttpMethod.PUT, trip + "/review", passenger, Map.of("score", 6), HttpStatus.BAD_REQUEST);
        var reviews = java.util.stream.IntStream.range(0, 2).mapToObj(i -> CompletableFuture.runAsync(() ->
                exchange(HttpMethod.PUT, trip + "/review", passenger, Map.of("score", 5, "comment", "Great ride"), HttpStatus.OK))).toList();
        CompletableFuture.allOf(reviews.toArray(CompletableFuture[]::new)).get(20, TimeUnit.SECONDS);
        exchange(HttpMethod.PUT, trip + "/review", passenger, Map.of("score", 4), HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, trip + "/review", driver, Map.of("score", 4, "comment", "On time"), HttpStatus.OK);
        var publications = java.util.stream.IntStream.range(0, 2).mapToObj(i -> CompletableFuture.runAsync(() ->
                exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "10.00"), HttpStatus.OK))).toList();
        CompletableFuture.allOf(publications.toArray(CompletableFuture[]::new)).get(20, TimeUnit.SECONDS);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "11.00"), HttpStatus.CONFLICT);
        var summary = exchange(HttpMethod.GET, trip + "/summary", passenger, null, HttpStatus.OK);
        assertThat(summary.path("participants").size()).isEqualTo(3);
        assertThat(summary.path("duration_seconds").asDouble()).isGreaterThanOrEqualTo(0);
        assertThat(summary.path("trip").path("live_latitude").isNull()).isTrue();
        assertThat(summary.path("my_review").path("score").asInt()).isEqualTo(5);
        BigDecimal sum = BigDecimal.ZERO;
        for (var share : summary.path("shares")) sum = sum.add(share.path("amount").decimalValue());
        assertThat(sum).isEqualByComparingTo("10.00");
        assertThat(summary.path("shares").size()).isEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM ratings WHERE booking_id = ?::uuid", Integer.class, firstId)).isEqualTo(2);
        var otherSummary = exchange(HttpMethod.GET, "/trips/" + secondId + "/summary", second, null, HttpStatus.OK);
        assertThat(otherSummary.path("costs").path("total_cost").decimalValue()).isEqualByComparingTo("10.00");
        var headers = new HttpHeaders();
        headers.setBearerAuth(driver);
        var profile = client.exchange("/api/v1/me", HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class).getBody();
        assertThat(profile.path("rating").asDouble()).isEqualTo(5.0);
        assertThat(profile.path("ratingCount").asInt()).isEqualTo(1);
    }

    @Test
    void groupedRequestCostsAreWeightedBySeatsAndZeroCostIsSupported() {
        String driver = register("groupDriver"), passenger = register("groupPassenger");
        String request = publish(passenger, "REQUEST", Map.of("latitude", 31.632123, "longitude", -8.011123), 3);
        String id = exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept", driver, null, HttpStatus.OK).path("id").asText();
        String trip = "/trips/" + id;
        exchange(HttpMethod.POST, trip + "/actions/START", driver, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.OK);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "10.01"), HttpStatus.OK);
        var summary = exchange(HttpMethod.GET, trip + "/summary", passenger, null, HttpStatus.OK);
        for (var share : summary.path("shares")) {
            assertThat(share.path("amount").decimalValue()).isEqualByComparingTo(share.path("mine").asBoolean() ? "7.50" : "2.51");
        }
        request = publish(passenger, "REQUEST", Map.of("latitude", 31.632123, "longitude", -8.011123));
        id = exchange(HttpMethod.POST, "/listings/REQUEST/" + request + "/accept", driver, null, HttpStatus.OK).path("id").asText();
        trip = "/trips/" + id;
        exchange(HttpMethod.POST, trip + "/actions/START", driver, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.OK);
        exchange(HttpMethod.PUT, trip + "/costs", driver, Map.of("total", "0.00"), HttpStatus.OK);
        summary = exchange(HttpMethod.GET, trip + "/summary", passenger, null, HttpStatus.OK);
        assertThat(summary.path("shares").size()).isEqualTo(2);
        for (var share : summary.path("shares")) assertThat(share.path("amount").decimalValue()).isEqualByComparingTo("0.00");
    }

    @Test
    void acceptingEitherKindCreatesAPrivateTripAndNotifiesItsAuthor() {
        String driver = register("driver");
        String passenger = register("passenger");
        String other = register("observer");
        Map<String, Object> point = Map.of("latitude", 31.632123, "longitude", -8.011123);

        String request = publish(passenger, "REQUEST", point);
        String offer = publish(driver, "OFFER", point);
        assertThat(exchange(HttpMethod.GET, "/listings?kind=REQUEST", driver, null, HttpStatus.OK)
                .findValuesAsText("id")).contains(request);
        assertThat(exchange(HttpMethod.GET, "/listings?kind=OFFER", passenger, null, HttpStatus.OK)
                .findValuesAsText("id")).contains(offer);
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
        assertThat(exchange(HttpMethod.GET, "/notifications", passenger, null, HttpStatus.OK).get(0)
                .path("title").asText()).isEqualTo("CHAT_MESSAGE");
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
        return publish(token, kind, point, 1);
    }

    private String publish(String token, String kind, Map<String, Object> point, int seats) {
        return exchange(HttpMethod.POST, "/listings", token, Map.of(
                "kind", kind, "campus", "CENTRE", "toCampus", true, "point", point,
                "departure", OffsetDateTime.now().plusHours(1).toString(),
                "seats", seats, "vehicle", "CAR", "notes", "Test listing"), HttpStatus.OK)
                .path("id").asText();
    }

    private String register(String name) {
        var response = client.postForEntity("/api/v1/auth/register", Map.of(
                "email", name + "." + UUID.randomUUID() + "@emsi-edu.ma", "password", "TestPass123!", "fullName", name), JsonNode.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return response.getBody().path("accessToken").asText();
    }

    @Test
    void onlyTheOwnerCanEditUnbookedListingsAndStaleUpdatesAreRejected() {
        String owner = register("editor");
        String other = register("reader");
        var point = Map.<String, Object>of("latitude", 31.632123, "longitude", -8.011123);
        for (String kind : new String[]{"OFFER", "REQUEST"}) {
            String id = publish(owner, kind, point);
            String path = "/listings/" + kind + "/" + id;
            var before = exchange(HttpMethod.GET, path, owner, null, HttpStatus.OK);
            assertThat(before.path("origin_latitude").asDouble()).isEqualTo(31.632123);
            Map<String, Object> input = Map.of("listing", Map.of(
                    "kind", kind, "campus", "TARGA", "toCampus", false, "point", point,
                    "departure", OffsetDateTime.now().plusHours(2).toString(), "seats", 2,
                    "vehicle", "CAR", "notes", "Updated"), "revision", before.path("revision").asText());
            exchange(HttpMethod.PUT, path, other, input, HttpStatus.NOT_FOUND);
            exchange(HttpMethod.PUT, path, owner, input, HttpStatus.OK);
            exchange(HttpMethod.PUT, path, owner, input, HttpStatus.CONFLICT);
            var after = exchange(HttpMethod.GET, path, owner, null, HttpStatus.OK);
            assertThat(after.path("seats").asInt()).isEqualTo(2);
            assertThat(after.path("origin_label").asText()).isEqualTo("EMSI Marrakech Targa");
            assertThat(after.path("destination_latitude").asDouble()).isEqualTo(31.632123);
            exchange(HttpMethod.POST, path + "/cancel", other, null, HttpStatus.NOT_FOUND);
            exchange(HttpMethod.POST, path + "/cancel", owner, null, HttpStatus.OK);
            exchange(HttpMethod.POST, path + "/cancel", owner, null, HttpStatus.OK);
            assertThat(exchange(HttpMethod.GET, path, owner, null, HttpStatus.OK).path("can_accept").asBoolean()).isFalse();
        }
    }

    @Test
    void cancellingRestoresOneSeatAndRebookingKeepsTheOldHistory() {
        String driver = register("driver");
        String passenger = register("passenger");
        String other = register("other");
        String offer = publish(driver, "OFFER", Map.of("latitude", 31.632123, "longitude", -8.011123));
        String listing = "/listings/OFFER/" + offer;
        String first = exchange(HttpMethod.POST, listing + "/accept", passenger, null, HttpStatus.OK).path("id").asText();
        String trip = "/trips/" + first;
        exchange(HttpMethod.POST, trip + "/actions/CANCEL", other, null, HttpStatus.NOT_FOUND);
        exchange(HttpMethod.POST, trip + "/actions/CANCEL", passenger, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/CANCEL", passenger, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, listing, driver, null, HttpStatus.OK).path("seats").asInt()).isEqualTo(1);
        String replacement = exchange(HttpMethod.POST, listing + "/accept", passenger, null, HttpStatus.OK).path("id").asText();
        assertThat(replacement).isNotEqualTo(first);
        var history = exchange(HttpMethod.GET, "/trips?history=true", passenger, null, HttpStatus.OK);
        assertThat(history.size()).isEqualTo(1);
        assertThat(history.get(0).path("status").asText()).isEqualTo("CANCELLED");
        exchange(HttpMethod.POST, trip + "/messages", driver, Map.of("body", "Closed"), HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, trip + "/location", driver, Map.of("latitude", 31.632123, "longitude", -8.011123), HttpStatus.CONFLICT);
        exchange(HttpMethod.POST, listing + "/cancel", driver, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, "/trips/" + replacement, passenger, null, HttpStatus.OK)
                .path("status").asText()).isEqualTo("CANCELLED");
        assertThat(exchange(HttpMethod.GET, listing, driver, null, HttpStatus.OK).path("status").asText()).isEqualTo("CANCELLED");
    }

    @Test
    void driverStartsAndCompletesAllPassengersAndClosesLocationAndChat() {
        String driver = register("driver");
        String firstPassenger = register("first");
        String secondPassenger = register("second");
        var point = Map.<String, Object>of("latitude", 31.632123, "longitude", -8.011123);
        String offer = publish(driver, "OFFER", point, 3);
        String listing = "/listings/OFFER/" + offer;
        String first = exchange(HttpMethod.POST, listing + "/accept", firstPassenger, null, HttpStatus.OK).path("id").asText();
        String second = exchange(HttpMethod.POST, listing + "/accept", secondPassenger, null, HttpStatus.OK).path("id").asText();
        String trip = "/trips/" + first;
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.CONFLICT);
        exchange(HttpMethod.POST, trip + "/actions/START", firstPassenger, null, HttpStatus.FORBIDDEN);
        exchange(HttpMethod.POST, trip + "/actions/START", driver, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/START", driver, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, "/trips/" + second, secondPassenger, null, HttpStatus.OK)
                .path("status").asText()).isEqualTo("ONGOING");
        exchange(HttpMethod.POST, listing + "/accept", register("late"), null, HttpStatus.CONFLICT);
        exchange(HttpMethod.POST, trip + "/actions/CANCEL", firstPassenger, null, HttpStatus.CONFLICT);
        exchange(HttpMethod.PUT, trip + "/location", driver, point, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.OK);
        exchange(HttpMethod.POST, trip + "/actions/COMPLETE", driver, null, HttpStatus.OK);
        var completed = exchange(HttpMethod.GET, trip, firstPassenger, null, HttpStatus.OK);
        assertThat(completed.path("status").asText()).isEqualTo("COMPLETED");
        assertThat(completed.path("live_latitude").isNull()).isTrue();
        assertThat(exchange(HttpMethod.GET, "/trips", firstPassenger, null, HttpStatus.OK).isEmpty()).isTrue();
        assertThat(exchange(HttpMethod.GET, "/trips?history=true", secondPassenger, null, HttpStatus.OK).size()).isEqualTo(1);
        exchange(HttpMethod.POST, trip + "/messages", firstPassenger, Map.of("body", "Closed"), HttpStatus.CONFLICT);
        var notifications = exchange(HttpMethod.GET, "/notifications", firstPassenger, null, HttpStatus.OK);
        assertThat(notifications.findValuesAsText("title")).contains("TRIP_STARTED", "TRIP_COMPLETED");
    }

    @Test
    void aDriverCancellationReopensARequestAndPassengerCancellationClosesIt() {
        String driver = register("driver");
        String passenger = register("passenger");
        String request = publish(passenger, "REQUEST", Map.of("latitude", 31.632123, "longitude", -8.011123));
        String listing = "/listings/REQUEST/" + request;
        String first = exchange(HttpMethod.POST, listing + "/accept", driver, null, HttpStatus.OK).path("id").asText();
        exchange(HttpMethod.POST, "/trips/" + first + "/actions/CANCEL", driver, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, listing, passenger, null, HttpStatus.OK).path("status").asText()).isEqualTo("PENDING");
        String replacement = exchange(HttpMethod.POST, listing + "/accept", driver, null, HttpStatus.OK).path("id").asText();
        exchange(HttpMethod.POST, listing + "/cancel", passenger, null, HttpStatus.OK);
        assertThat(exchange(HttpMethod.GET, "/trips/" + replacement, passenger, null, HttpStatus.OK)
                .path("status").asText()).isEqualTo("CANCELLED");
        assertThat(exchange(HttpMethod.GET, listing, passenger, null, HttpStatus.OK).path("status").asText()).isEqualTo("CANCELLED");
    }

    @Test
    void concurrentAcceptancesCannotOversellAndConcurrentCancellationsRestoreOneSeat() throws Exception {
        String driver = register("driver");
        var passengers = List.of(register("first"), register("second"));
        String offer = publish(driver, "OFFER", Map.of("latitude", 31.632123, "longitude", -8.011123));
        String path = "/listings/OFFER/" + offer;
        var acceptances = passengers.stream().map(token -> CompletableFuture.supplyAsync(() -> {
            var headers = new HttpHeaders();
            headers.setBearerAuth(token);
            return client.exchange("/api/v1/marketplace" + path + "/accept", HttpMethod.POST,
                    new HttpEntity<>(null, headers), JsonNode.class);
        })).toList();
        var first = acceptances.get(0).get(15, TimeUnit.SECONDS);
        var second = acceptances.get(1).get(15, TimeUnit.SECONDS);
        assertThat(List.of(first.getStatusCode(), second.getStatusCode()))
                .containsExactlyInAnyOrder(HttpStatus.OK, HttpStatus.CONFLICT);
        var accepted = first.getStatusCode().is2xxSuccessful() ? first : second;
        String passenger = first.getStatusCode().is2xxSuccessful() ? passengers.get(0) : passengers.get(1);
        String trip = "/trips/" + accepted.getBody().path("id").asText();
        var booked = exchange(HttpMethod.GET, path, driver, null, HttpStatus.OK);
        assertThat(booked.path("can_edit").asBoolean()).isFalse();
        exchange(HttpMethod.PUT, path, driver, Map.of("revision", booked.path("revision").asText(),
                "listing", Map.of("kind", "OFFER", "campus", "CENTRE", "toCampus", true,
                        "point", Map.of("latitude", 31.632123, "longitude", -8.011123),
                        "departure", OffsetDateTime.now().plusHours(2).toString(), "seats", 4,
                        "vehicle", "CAR", "notes", "Locked")), HttpStatus.CONFLICT);
        var cancelFirst = CompletableFuture.runAsync(() -> exchange(HttpMethod.POST,
                trip + "/actions/CANCEL", passenger, null, HttpStatus.OK));
        var cancelSecond = CompletableFuture.runAsync(() -> exchange(HttpMethod.POST,
                trip + "/actions/CANCEL", passenger, null, HttpStatus.OK));
        CompletableFuture.allOf(cancelFirst, cancelSecond).get(15, TimeUnit.SECONDS);
        assertThat(exchange(HttpMethod.GET, path, driver, null, HttpStatus.OK).path("seats").asInt()).isEqualTo(1);
        var notices = exchange(HttpMethod.GET, "/notifications", driver, null, HttpStatus.OK);
        assertThat(notices.findValuesAsText("title")).containsExactlyInAnyOrder("OFFER_ACCEPTED", "TRIP_CANCELLED");
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
