package ma.emsi.emsidrive.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.entity.BiometricDevice;
import ma.emsi.emsidrive.auth.repository.BiometricDeviceRepository;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
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

/** Fingerprint login and server logout against a real PostgreSQL instance. */
@Testcontainers
@org.springframework.test.annotation.DirtiesContext(classMode = org.springframework.test.annotation.DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BiometricLoginIntegrationTest {

    private static final String EMAIL = "biometric.student@emsi-edu.ma";

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
        registry.add("app.security.jwt.secret", () -> "emsidrive-biometric-test-secret-key-32b");
        registry.add("app.security.student-email-domains", () -> "emsi-edu.ma");
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private BiometricDeviceRepository deviceRepository;

    private JsonNode session;

    @BeforeEach
    void registerStudent() throws Exception {
        deviceRepository.deleteAll();
        refreshTokenRepository.deleteAll();
        userRepository.deleteAll();
        session = body(post("/api/v1/auth/register",
                new RegisterRequest(EMAIL, "StrongPass123!", "Biometric Student", null), null));
    }

    @Test
    void linkingAPhoneRequiresASession() throws Exception {
        assertThat(post("/api/v1/me/biometric-devices", Map.of(), null).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void linkedPhoneSignsInAndStoresOnlyTheKeyHash() throws Exception {
        JsonNode device = enroll();
        BiometricDevice stored = deviceRepository.findById(UUID.fromString(device.get("deviceId").asText()))
                .orElseThrow();
        assertThat(stored.getKeyHash()).isEqualTo(TokenHasher.sha256Hex(device.get("deviceKey").asText()));
        assertThat(stored.getDeviceName()).isEqualTo("Pixel test");

        ResponseEntity<String> login = biometricLogin(device.get("deviceId").asText(), device.get("deviceKey").asText());

        assertThat(login.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode result = body(login);
        assertThat(result.get("session").get("accessToken").asText()).isNotBlank();
        assertThat(result.get("session").get("user").get("email").asText()).isEqualTo(EMAIL);
        assertThat(result.get("deviceKey").asText()).isNotEqualTo(device.get("deviceKey").asText());
    }

    @Test
    void theRotatedKeyKeepsWorking() throws Exception {
        JsonNode device = enroll();
        String id = device.get("deviceId").asText();
        String next = body(biometricLogin(id, device.get("deviceKey").asText())).get("deviceKey").asText();

        assertThat(biometricLogin(id, next).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void replayingAnOldKeyRevokesThePhone() throws Exception {
        JsonNode device = enroll();
        String id = device.get("deviceId").asText();
        String original = device.get("deviceKey").asText();
        String next = body(biometricLogin(id, original)).get("deviceKey").asText();

        ResponseEntity<String> replay = biometricLogin(id, original);
        assertThat(replay.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(body(replay).get("code").asText()).isEqualTo("INVALID_DEVICE_KEY");
        // Even the legitimate current key is now refused.
        assertThat(biometricLogin(id, next).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void revokedPhoneCanNoLongerSignIn() throws Exception {
        JsonNode device = enroll();
        String id = device.get("deviceId").asText();
        String key = device.get("deviceKey").asText();

        assertThat(post("/api/v1/auth/biometric/revoke", Map.of("deviceId", id, "deviceKey", key), null)
                .getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(biometricLogin(id, key).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void revokingWithAWrongKeyDoesNothing() throws Exception {
        JsonNode device = enroll();
        String id = device.get("deviceId").asText();

        assertThat(post("/api/v1/auth/biometric/revoke", Map.of("deviceId", id, "deviceKey", "wrong"), null)
                .getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(biometricLogin(id, device.get("deviceKey").asText()).getStatusCode())
                .isEqualTo(HttpStatus.OK);
    }

    @Test
    void logoutEndsTheSessionButKeepsTheLinkedPhone() throws Exception {
        JsonNode device = enroll();
        String refreshToken = session.get("refreshToken").asText();

        assertThat(post("/api/v1/auth/logout", Map.of("refreshToken", refreshToken), null).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", refreshToken), null).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        // Logging out again is harmless.
        assertThat(post("/api/v1/auth/logout", Map.of("refreshToken", refreshToken), null).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        assertThat(biometricLogin(device.get("deviceId").asText(), device.get("deviceKey").asText())
                .getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void unknownDeviceIsRejected() throws Exception {
        assertThat(biometricLogin(UUID.randomUUID().toString(), "anything").getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    private JsonNode enroll() throws Exception {
        ResponseEntity<String> response = post("/api/v1/me/biometric-devices",
                Map.of("deviceName", "Pixel test"), session.get("accessToken").asText());
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return body(response);
    }

    private ResponseEntity<String> biometricLogin(String deviceId, String deviceKey) throws Exception {
        return post("/api/v1/auth/biometric/login", Map.of("deviceId", deviceId, "deviceKey", deviceKey), null);
    }

    private ResponseEntity<String> post(String path, Object payload, String bearer) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (bearer != null) {
            headers.setBearerAuth(bearer);
        }
        return restTemplate.postForEntity(
                path, new HttpEntity<>(objectMapper.writeValueAsString(payload), headers), String.class);
    }

    private JsonNode body(ResponseEntity<String> response) throws Exception {
        return objectMapper.readTree(response.getBody());
    }
}
