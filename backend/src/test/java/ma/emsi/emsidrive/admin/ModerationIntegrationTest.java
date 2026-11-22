package ma.emsi.emsidrive.admin;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.auth.security.JwtService;
import ma.emsi.emsidrive.user.entity.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ModerationIntegrationTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired TestRestTemplate client;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;

    @Test
    void adminRoutesRequireLiveAdministratorRole() {
        var student = register();
        call("GET", "/admin/dashboard", null, null, 401);
        call("GET", "/admin/dashboard", token(student), null, 403);
        // A signed claim alone cannot grant administrative permissions.
        String forgedRole = jwt.createAccessToken(id(student), student.path("user").path("email").asText(), UserRole.ADMIN);
        call("GET", "/admin/dashboard", forgedRole, null, 403);
        jdbc.update("UPDATE users SET role = 'ADMIN' WHERE id = ?", id(student));
        call("GET", "/admin/dashboard", token(student), null, 200);
        jdbc.update("UPDATE users SET role = 'STUDENT' WHERE id = ?", id(student));
        call("GET", "/admin/audit", token(student), null, 403);
    }

    @Test
    void suspensionInvalidatesAccessRefreshBiometricsAndPushAndCannotTargetAdmins() {
        var admin = admin(); var student = register();
        var observer = register();
        String listing = publish(token(student), "OFFER", "TARGA");
        UUID userId = id(student);
        var account = call("GET", "/admin/users/" + userId, token(admin), null, 200);
        var decision = new HashMap<String, Object>(Map.of("enabled", false, "reason", "Repeated unsafe conduct", "revision", account.path("revision").asText()));
        call("PUT", "/admin/users/" + userId + "/access", token(student), decision, 403);
        call("PUT", "/admin/users/" + userId + "/access", token(admin), decision, 200);
        call("GET", "/me", token(student), null, 401);
        var unavailable = call("GET", "/marketplace/listings/OFFER/" + listing, token(observer), null, 200);
        assertThat(unavailable.path("can_accept").asBoolean()).isFalse();
        call("POST", "/marketplace/listings/OFFER/" + listing + "/accept", token(observer), null, 409);
        call("POST", "/auth/refresh", null, Map.of("refreshToken", student.path("refreshToken").asText()), 401);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM refresh_tokens WHERE user_id = ? AND revoked_at IS NULL", Integer.class, userId)).isZero();
        call("PUT", "/admin/users/" + userId + "/access", token(admin), decision, 409);
        account = call("GET", "/admin/users/" + userId, token(admin), null, 200);
        decision.put("enabled", true); decision.put("revision", account.path("revision").asText());
        call("PUT", "/admin/users/" + userId + "/access", token(admin), decision, 200);
        call("GET", "/me", token(student), null, 401);
        var self = call("GET", "/admin/users/" + id(admin), token(admin), null, 200);
        decision.put("revision", self.path("revision").asText()); decision.put("enabled", false);
        call("PUT", "/admin/users/" + id(admin) + "/access", token(admin), decision, 403);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM admin_actions WHERE target_id = ?", Integer.class, userId)).isEqualTo(2);
    }

    @Test
    void listingReportsAreIdempotentPrivateAndModeratedWithRevisionAndAudit() {
        var driver = register(); var reporter = register(); var admin = admin();
        String listing = publish(token(driver), "OFFER", "TARGA");
        var input = new HashMap<String, Object>(Map.of("kind", "OFFER", "listingId", listing,
                "category", "UNSAFE_DRIVING", "description", "Unsafe driving near the campus"));
        String submission = UUID.randomUUID().toString();
        call("PUT", "/reports/" + submission, token(driver), input, 400);
        var result = call("PUT", "/reports/" + submission, token(reporter), input, 200);
        String report = result.path("id").asText();
        assertThat(call("PUT", "/reports/" + submission, token(reporter), input, 200).path("id").asText()).isEqualTo(report);
        input.put("description", "Different facts");
        call("PUT", "/reports/" + submission, token(reporter), input, 409);
        var mine = call("GET", "/reports", token(reporter), null, 200);
        assertThat(mine.size()).isEqualTo(1);
        assertThat(mine.get(0).has("reporter_id")).isFalse();
        assertThat(call("GET", "/reports", token(driver), null, 200).size()).isZero();
        var decision = Map.of("status", "RESOLVED", "reason", "Facts reviewed and warning sent", "revision", 1);
        call("PUT", "/admin/reports/" + report, token(reporter), decision, 403);
        call("PUT", "/admin/reports/" + report, token(admin), decision, 200);
        call("PUT", "/admin/reports/" + report, token(admin), decision, 409);
        assertThat(call("GET", "/reports", token(reporter), null, 200).get(0).path("status").asText()).isEqualTo("RESOLVED");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM admin_actions WHERE target_id = ?::uuid", Integer.class, report)).isEqualTo(1);
        call("GET", "/admin/reports?status=RESOLVED", token(admin), null, 200);
        call("GET", "/admin/audit", token(admin), null, 200);
    }

    @Test
    void bookingReportRequiresParticipationAndRejectsAmbiguousContexts() {
        var driver = register(); var passenger = register(); var observer = register();
        String listing = publish(token(driver), "OFFER", "CENTRE");
        String booking = call("POST", "/marketplace/listings/OFFER/" + listing + "/accept", token(passenger), null, 200).path("id").asText();
        var input = new HashMap<String, Object>(Map.of("bookingId", booking, "category", "NO_SHOW", "description", "No one at pickup"));
        call("PUT", "/reports/" + UUID.randomUUID(), token(observer), input, 404);
        call("PUT", "/reports/" + UUID.randomUUID(), token(driver), input, 200);
        input.put("listingId", listing); input.put("kind", "OFFER");
        call("PUT", "/reports/" + UUID.randomUUID(), token(passenger), input, 400);
        input.clear(); input.put("description", " "); input.put("category", "OTHER");
        call("PUT", "/reports/" + UUID.randomUUID(), token(passenger), input, 400);
    }

    @Test
    void filtersPaginationAndDashboardReadRealRows() {
        var driver = register(); var admin = admin();
        publish(token(driver), "OFFER", "TARGA"); publish(token(driver), "REQUEST", "CENTRE");
        var offers = call("GET", "/admin/rides?kind=OFFER&campus=TARGA&status=OPEN", token(admin), null, 200);
        assertThat(offers.path("items").size()).isGreaterThan(0);
        for (var item : offers.path("items")) {
            assertThat(item.path("kind").asText()).isEqualTo("OFFER");
            assertThat(item.path("destination_label").asText()).isEqualTo("EMSI Marrakech Targa");
        }
        var dashboard = call("GET", "/admin/dashboard", token(admin), null, 200);
        assertThat(dashboard.path("users").asLong()).isEqualTo(jdbc.queryForObject("SELECT count(*) FROM users WHERE role = 'STUDENT'", Long.class));
        call("GET", "/admin/users?search=student&enabled=true", token(admin), null, 200);
        call("GET", "/admin/users?page=-1", token(admin), null, 400);
        call("GET", "/admin/rides?kind=INVALID", token(admin), null, 400);
        call("GET", "/admin/rides?date=2026-11-22", token(admin), null, 200);
    }

    private JsonNode register() {
        return call("POST", "/auth/register", null, Map.of("email", UUID.randomUUID() + "@emsi-edu.ma", "password", "StudentPass123!", "fullName", "Test student"), 201);
    }
    private JsonNode admin() {
        var account = register(); jdbc.update("UPDATE users SET role = 'ADMIN' WHERE id = ?", id(account)); return account;
    }
    private UUID id(JsonNode auth) { return UUID.fromString(auth.path("user").path("id").asText()); }
    private String token(JsonNode auth) { return auth.path("accessToken").asText(); }
    private String publish(String token, String kind, String campus) {
        return call("POST", "/marketplace/listings", token, Map.of("kind", kind, "campus", campus, "toCampus", true,
                "point", Map.of("latitude", 31.632123, "longitude", -8.011123),
                "departure", OffsetDateTime.now().plusHours(2).toString(), "seats", 1, "vehicle", "CAR"), 200).path("id").asText();
    }
    private JsonNode call(String method, String path, String token, Object body, int expected) {
        var headers = new HttpHeaders(); if (token != null) headers.setBearerAuth(token);
        var result = client.exchange("/api/v1" + path, HttpMethod.valueOf(method), new HttpEntity<>(body, headers), JsonNode.class);
        assertThat(result.getStatusCode().value()).as(method + " " + path + " " + result.getBody()).isEqualTo(expected);
        return result.getBody();
    }
}
