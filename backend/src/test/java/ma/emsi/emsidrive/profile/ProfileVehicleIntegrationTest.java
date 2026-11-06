package ma.emsi.emsidrive.profile;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.user.dto.UpdateProfileRequest;
import ma.emsi.emsidrive.user.repository.UserRepository;
import ma.emsi.emsidrive.vehicle.dto.VehicleRequest;
import ma.emsi.emsidrive.vehicle.entity.VehicleType;
import ma.emsi.emsidrive.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * End-to-end coverage of the profile and vehicle endpoints against a real PostgreSQL
 * instance, so the Flyway migrations, the JPA mappings, the JWT filter and the error
 * contract are exercised together.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ProfileVehicleIntegrationTest {

    private static final String SARA_EMAIL = "profile.sara@emsi-edu.ma";
    private static final String OMAR_EMAIL = "profile.omar@emsi-edu.ma";
    private static final String OMAR_NAME = "Omar Bennani";
    private static final String RAW_PASSWORD = "StrongPass123!";
    private static final String JWT_SECRET = "emsidrive-integration-test-secret-key-32b";

    @Container
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"))
                    .withDatabaseName("emsidrive")
                    .withUsername("emsidrive")
                    .withPassword("emsidrive");

    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("app.security.jwt.secret", () -> JWT_SECRET);
        registry.add("app.security.student-email-domains", () -> "emsi-edu.ma");
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @BeforeEach
    void cleanDatabase() {
        vehicleRepository.deleteAll();
        refreshTokenRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void getMeReturnsTheRegisteredProfile() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(HttpMethod.GET, "/api/v1/me", accessToken, null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode body = readBody(response);
        assertThat(body.get("email").asText()).isEqualTo(SARA_EMAIL);
        assertThat(body.get("fullName").asText()).isEqualTo("Sara El Idrissi");
        assertThat(body.get("phoneNumber").asText()).isEqualTo("+212612345678");
        assertThat(body.get("role").asText()).isEqualTo("STUDENT");
        assertThat(body.get("enabled").asBoolean()).isTrue();
        assertThat(body.has("filiere")).isTrue();
    }

    @Test
    void putMeUpdatesAndPersistsTheProfile() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(HttpMethod.PUT, "/api/v1/me", accessToken,
                new UpdateProfileRequest(
                        "Sara El Idrissi Alaoui",
                        "+212698765432",
                        "2DSI",
                        "2025-2026",
                        "https://cdn.emsidrive.ma/sara.jpg"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode body = readBody(response);
        assertThat(body.get("fullName").asText()).isEqualTo("Sara El Idrissi Alaoui");
        assertThat(body.get("filiere").asText()).isEqualTo("2DSI");
        assertThat(body.get("academicYear").asText()).isEqualTo("2025-2026");
        assertThat(body.get("photoUrl").asText()).isEqualTo("https://cdn.emsidrive.ma/sara.jpg");

        JsonNode reloaded = readBody(exchange(HttpMethod.GET, "/api/v1/me", accessToken, null));
        assertThat(reloaded.get("filiere").asText()).isEqualTo("2DSI");
        assertThat(reloaded.get("photoUrl").asText()).isEqualTo("https://cdn.emsidrive.ma/sara.jpg");
        assertThat(userRepository.findByEmailIgnoreCase(SARA_EMAIL).orElseThrow().getFiliere())
                .isEqualTo("2DSI");
    }

    @Test
    void putMeRejectsInvalidPayloadWithFieldDetails() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(HttpMethod.PUT, "/api/v1/me", accessToken,
                new UpdateProfileRequest("   ", "not-a-phone", "x".repeat(61), null, "ftp://invalid"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode body = readBody(response);
        assertThat(body.get("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(fieldNames(body)).containsExactlyInAnyOrder("fullName", "phoneNumber", "filiere", "photoUrl");
    }

    @Test
    void profileEndpointsRequireAuthentication() {
        assertThat(restTemplate.getForEntity("/api/v1/me", String.class).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(restTemplate.getForEntity("/api/v1/me/vehicles", String.class).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void vehiclesCanBeCreatedListedUpdatedAndDeleted() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> created = exchange(HttpMethod.POST, "/api/v1/me/vehicles", accessToken,
                new VehicleRequest(VehicleType.VOITURE, "Dacia", "Logan", "White", 4));
        assertThat(created.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        String vehicleId = readBody(created).get("id").asText();
        assertThat(readBody(created).get("type").asText()).isEqualTo("VOITURE");
        assertThat(readBody(created).get("createdAt").isNull()).isFalse();
        assertThat(readBody(created).get("updatedAt").isNull()).isFalse();

        exchange(HttpMethod.POST, "/api/v1/me/vehicles", accessToken,
                new VehicleRequest(VehicleType.MOTO, "Yamaha", "Xmax", "Black", 2));

        ResponseEntity<String> list = exchange(HttpMethod.GET, "/api/v1/me/vehicles", accessToken, null);
        assertThat(list.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(readBody(list)).hasSize(2);

        ResponseEntity<String> updated = exchange(HttpMethod.PUT, "/api/v1/me/vehicles/" + vehicleId, accessToken,
                new VehicleRequest(VehicleType.VOITURE, "Renault", "Clio", "Blue", 5));
        assertThat(updated.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(readBody(updated).get("brand").asText()).isEqualTo("Renault");
        assertThat(readBody(updated).get("seats").asInt()).isEqualTo(5);

        ResponseEntity<String> deleted = exchange(
                HttpMethod.DELETE, "/api/v1/me/vehicles/" + vehicleId, accessToken, null);
        assertThat(deleted.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(vehicleRepository.findById(UUID.fromString(vehicleId))).isEmpty();

        assertThat(readBody(exchange(HttpMethod.GET, "/api/v1/me/vehicles", accessToken, null))).hasSize(1);
    }

    @Test
    void vehiclesRejectInvalidPayload() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(HttpMethod.POST, "/api/v1/me/vehicles", accessToken,
                new VehicleRequest(null, "  ", "  ", "x".repeat(31), 9));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode body = readBody(response);
        assertThat(body.get("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(fieldNames(body)).containsExactlyInAnyOrder("type", "brand", "model", "color", "seats");
    }

    @Test
    void aUserCannotReadOrMutateAnotherUserVehicle() throws Exception {
        String saraToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");
        String omarToken = registerAndGetAccessToken(OMAR_EMAIL, OMAR_NAME);

        String saraVehicleId = readBody(exchange(HttpMethod.POST, "/api/v1/me/vehicles", saraToken,
                new VehicleRequest(VehicleType.VOITURE, "Dacia", "Logan", "White", 4))).get("id").asText();

        assertThat(readBody(exchange(HttpMethod.GET, "/api/v1/me/vehicles", omarToken, null))).isEmpty();

        ResponseEntity<String> hijackUpdate = exchange(HttpMethod.PUT, "/api/v1/me/vehicles/" + saraVehicleId,
                omarToken, new VehicleRequest(VehicleType.MOTO, "Honda", "PCX", "Red", 2));
        assertThat(hijackUpdate.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(readBody(hijackUpdate).get("code").asText()).isEqualTo("VEHICLE_NOT_FOUND");

        ResponseEntity<String> hijackDelete = exchange(
                HttpMethod.DELETE, "/api/v1/me/vehicles/" + saraVehicleId, omarToken, null);
        assertThat(hijackDelete.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        assertThat(readBody(exchange(HttpMethod.GET, "/api/v1/me/vehicles", saraToken, null))).hasSize(1);
    }

    @Test
    void vehiclesRejectUnknownTypeWithFieldDetails() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(accessToken);

        ResponseEntity<String> response = restTemplate.exchange("/api/v1/me/vehicles", HttpMethod.POST,
                new HttpEntity<>(
                        "{\"type\":\"BATEAU\",\"brand\":\"Dacia\",\"model\":\"Logan\",\"seats\":4}", headers),
                String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode body = readBody(response);
        assertThat(body.get("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(fieldNames(body)).containsExactly("type");
    }

    @Test
    void unknownVehicleIdReturnsNotFound() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(
                HttpMethod.DELETE, "/api/v1/me/vehicles/" + UUID.randomUUID(), accessToken, null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(readBody(response).get("code").asText()).isEqualTo("VEHICLE_NOT_FOUND");
    }

    @Test
    void malformedVehicleIdReturnsBadRequest() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");

        ResponseEntity<String> response = exchange(
                HttpMethod.DELETE, "/api/v1/me/vehicles/not-a-uuid", accessToken, null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(readBody(response).get("code").asText()).isEqualTo("INVALID_PARAMETER");
    }

    @Test
    void malformedJsonBodyReturnsBadRequest() throws Exception {
        String accessToken = registerAndGetAccessToken(SARA_EMAIL, "Sara El Idrissi");
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(accessToken);

        ResponseEntity<String> response = restTemplate.exchange("/api/v1/me/vehicles", HttpMethod.POST,
                new HttpEntity<>("{ not json", headers), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(readBody(response).get("code").asText()).isEqualTo("MALFORMED_REQUEST_BODY");
    }

    private String registerAndGetAccessToken(String email, String fullName) throws Exception {
        ResponseEntity<String> response = restTemplate.postForEntity("/api/v1/auth/register",
                jsonEntity(new RegisterRequest(email, RAW_PASSWORD, fullName, "+212612345678"), null),
                String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return readBody(response).get("accessToken").asText();
    }

    private ResponseEntity<String> exchange(HttpMethod method, String path, String accessToken, Object payload)
            throws Exception {
        return restTemplate.exchange(path, method, jsonEntity(payload, accessToken), String.class);
    }

    private HttpEntity<String> jsonEntity(Object payload, String accessToken) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        if (accessToken != null) {
            headers.setBearerAuth(accessToken);
        }
        String body = payload == null ? null : objectMapper.writeValueAsString(payload);
        return new HttpEntity<>(body, headers);
    }

    private List<String> fieldNames(JsonNode body) {
        return body.get("details").findValuesAsText("field");
    }

    private JsonNode readBody(ResponseEntity<String> response) throws Exception {
        return objectMapper.readTree(response.getBody());
    }
}
