package ma.emsi.emsidrive.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.LoginRequest;
import ma.emsi.emsidrive.auth.dto.RefreshTokenRequest;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.entity.RefreshToken;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.auth.security.JwtService;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import ma.emsi.emsidrive.user.repository.UserRepository;
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
 * End-to-end authentication test against a real PostgreSQL instance so that the Flyway
 * migrations and the JPA mappings are exercised together with the HTTP layer.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class AuthIntegrationTest {

    private static final String STUDENT_EMAIL = "integration.student@emsi-edu.ma";
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
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private JwtService jwtService;

    @BeforeEach
    void cleanDatabase() {
        refreshTokenRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void registerPersistsStudentAndReturnsTokenPair() throws Exception {
        ResponseEntity<String> response = postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        JsonNode body = readBody(response);
        assertThat(body.get("tokenType").asText()).isEqualTo("Bearer");
        assertThat(body.get("expiresIn").asLong()).isEqualTo(900);
        assertThat(body.get("accessToken").asText()).isNotBlank();
        assertThat(body.get("refreshToken").asText()).isNotBlank();
        assertThat(body.get("user").get("email").asText()).isEqualTo(STUDENT_EMAIL);
        assertThat(body.get("user").get("role").asText()).isEqualTo("STUDENT");

        User persisted = userRepository.findByEmailIgnoreCase(STUDENT_EMAIL).orElseThrow();
        assertThat(persisted.getRole()).isEqualTo(UserRole.STUDENT);
        assertThat(persisted.isEnabled()).isTrue();
        assertThat(persisted.getPasswordHash()).startsWith("$2");

        Optional<RefreshToken> stored =
                refreshTokenRepository.findByTokenHash(TokenHasher.sha256Hex(body.get("refreshToken").asText()));
        assertThat(stored).isPresent();
        assertThat(stored.orElseThrow().getRevokedAt()).isNull();
        assertThat(stored.orElseThrow().getUser().getId()).isEqualTo(persisted.getId());
    }

    @Test
    void registerRejectsEmailOutsideStudentDomains() throws Exception {
        ResponseEntity<String> response = postJson("/api/v1/auth/register", registerPayload("someone@gmail.com"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(readBody(response).get("code").asText()).isEqualTo("EMAIL_DOMAIN_NOT_ALLOWED");
        assertThat(userRepository.count()).isZero();
    }

    @Test
    void registerRejectsDuplicateEmail() throws Exception {
        assertThat(postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL)).getStatusCode())
                .isEqualTo(HttpStatus.CREATED);

        ResponseEntity<String> duplicate = postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL));

        assertThat(duplicate.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(readBody(duplicate).get("code").asText()).isEqualTo("EMAIL_ALREADY_USED");
        assertThat(userRepository.count()).isEqualTo(1);
    }

    @Test
    void loginReturnsTokenPairForValidCredentials() throws Exception {
        postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL));

        ResponseEntity<String> response = postJson(
                "/api/v1/auth/login", new LoginRequest("Integration.Student@EMSI-EDU.ma", RAW_PASSWORD));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(readBody(response).get("accessToken").asText()).isNotBlank();
        assertThat(refreshTokenRepository.count()).isEqualTo(2);
    }

    @Test
    void loginRejectsWrongPassword() throws Exception {
        postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL));

        ResponseEntity<String> response = postJson(
                "/api/v1/auth/login", new LoginRequest(STUDENT_EMAIL, "WrongPass123!"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(readBody(response).get("code").asText()).isEqualTo("INVALID_CREDENTIALS");
    }

    @Test
    void refreshRotatesTokenAndRevokesThePreviousOne() throws Exception {
        String originalRefreshToken = readBody(postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL)))
                .get("refreshToken").asText();

        ResponseEntity<String> refreshed = postJson(
                "/api/v1/auth/refresh", new RefreshTokenRequest(originalRefreshToken));

        assertThat(refreshed.getStatusCode()).isEqualTo(HttpStatus.OK);
        String rotatedRefreshToken = readBody(refreshed).get("refreshToken").asText();
        assertThat(rotatedRefreshToken).isNotEqualTo(originalRefreshToken);

        RefreshToken revoked = refreshTokenRepository
                .findByTokenHash(TokenHasher.sha256Hex(originalRefreshToken))
                .orElseThrow();
        assertThat(revoked.getRevokedAt()).isNotNull();

        ResponseEntity<String> replay = postJson(
                "/api/v1/auth/refresh", new RefreshTokenRequest(originalRefreshToken));
        assertThat(replay.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(readBody(replay).get("code").asText()).isEqualTo("INVALID_REFRESH_TOKEN");
    }

    @Test
    void refreshRejectsUnknownAccessToken() throws Exception {
        UUID userId = userRepository.save(User.builder()
                        .email(STUDENT_EMAIL)
                        .passwordHash("$2a$10$0123456789012345678901234567890123456789012345678901234567")
                        .fullName("Sara El Idrissi")
                        .role(UserRole.STUDENT)
                        .enabled(true)
                        .build())
                .getId();
        String accessToken = jwtService.createAccessToken(userId, STUDENT_EMAIL, UserRole.STUDENT);

        ResponseEntity<String> response = postJson(
                "/api/v1/auth/refresh", new RefreshTokenRequest(accessToken));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(readBody(response).get("code").asText()).isEqualTo("INVALID_REFRESH_TOKEN");
    }

    @Test
    void accessTokenAuthenticatesProtectedRequests() throws Exception {
        String accessToken = readBody(postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL)))
                .get("accessToken").asText();

        // No endpoint other than auth and health is exposed yet, so an authenticated call to an
        // unknown route reaches the dispatcher (404) while an anonymous call is stopped (401).
        assertThat(getWithBearer("/api/v1/unknown", accessToken).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        ResponseEntity<String> anonymous = restTemplate.getForEntity("/api/v1/unknown", String.class);
        assertThat(anonymous.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(readBody(anonymous).get("code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void tamperedAccessTokenIsRejected() throws Exception {
        String accessToken = readBody(postJson("/api/v1/auth/register", registerPayload(STUDENT_EMAIL)))
                .get("accessToken").asText();
        String tampered = accessToken.substring(0, accessToken.length() - 3) + "abc";

        ResponseEntity<String> response = getWithBearer("/api/v1/unknown", tampered);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(readBody(response).get("code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void healthEndpointStaysPublic() {
        assertThat(restTemplate.getForEntity("/health", String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    private RegisterRequest registerPayload(String email) {
        return new RegisterRequest(email, RAW_PASSWORD, "Sara El Idrissi", "+212612345678");
    }

    private ResponseEntity<String> postJson(String path, Object payload) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        return restTemplate.postForEntity(path, new HttpEntity<>(objectMapper.writeValueAsString(payload), headers),
                String.class);
    }

    private ResponseEntity<String> getWithBearer(String path, String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        return restTemplate.exchange(path, HttpMethod.GET, new HttpEntity<>(headers), String.class);
    }

    private JsonNode readBody(ResponseEntity<String> response) throws Exception {
        return objectMapper.readTree(response.getBody());
    }
}
