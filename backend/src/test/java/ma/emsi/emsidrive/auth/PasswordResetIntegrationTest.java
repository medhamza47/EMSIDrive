package ma.emsi.emsidrive.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.after;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Duration;
import java.util.Map;
import ma.emsi.emsidrive.auth.mail.CodeMailer;
import ma.emsi.emsidrive.auth.mail.CodePurpose;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/** Forgotten password flow against a real PostgreSQL, with the mailer captured. */
@Testcontainers
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class PasswordResetIntegrationTest {

    private static final String EMAIL = "reset.student@emsi-edu.ma";
    private static final String OLD_PASSWORD = "OldStrongPass1!";
    private static final String NEW_PASSWORD = "NewStrongPass2!";

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
        registry.add("app.security.jwt.secret", () -> "emsidrive-password-reset-test-secret-32b");
        registry.add("app.security.student-email-domains", () -> "emsi-edu.ma");
    }

    @Autowired
    private TestRestTemplate client;

    @Autowired
    private JdbcTemplate jdbc;

    @MockitoBean
    private CodeMailer mailer;

    private JsonNode session;

    @BeforeEach
    void registerStudent() {
        jdbc.execute("TRUNCATE TABLE users CASCADE");
        session = post("/auth/register", Map.of(
                "email", EMAIL, "password", OLD_PASSWORD, "fullName", "Reset Student"), HttpStatus.CREATED);
    }

    @Test
    void codeResetsPasswordAndEndsEverySession() {
        String access = session.path("accessToken").asText();
        String refresh = session.path("refreshToken").asText();
        call(HttpMethod.POST, "/me/biometric-devices", access, Map.of("deviceName", "Pixel"), HttpStatus.CREATED);

        String code = requestCode("Reset.Student@EMSI-EDU.ma");
        post("/auth/password/reset", resetBody(wrong(code)), HttpStatus.BAD_REQUEST);
        post("/auth/password/reset", resetBody(code), HttpStatus.NO_CONTENT);

        assertThat(post("/auth/login", Map.of("email", EMAIL, "password", OLD_PASSWORD), HttpStatus.UNAUTHORIZED)
                .path("code").asText()).isEqualTo("INVALID_CREDENTIALS");
        post("/auth/login", Map.of("email", EMAIL, "password", NEW_PASSWORD), HttpStatus.OK);
        post("/auth/refresh", Map.of("refreshToken", refresh), HttpStatus.UNAUTHORIZED);
        call(HttpMethod.GET, "/me", access, null, HttpStatus.UNAUTHORIZED);
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM biometric_devices WHERE revoked_at IS NULL", Integer.class)).isZero();

        // A code works only once.
        assertThat(post("/auth/password/reset", resetBody(code), HttpStatus.BAD_REQUEST)
                .path("code").asText()).isEqualTo("INVALID_RESET_CODE");
    }

    @Test
    void unknownEmailGetsTheSameAnswerAndNoEmail() {
        post("/auth/password/forgot", Map.of("email", "nobody@emsi-edu.ma"), HttpStatus.ACCEPTED);
        verify(mailer, after(500).never()).sendCode(any(), anyString(), anyString(), anyString(), any());
        assertThat(post("/auth/password/reset", Map.of("email", "nobody@emsi-edu.ma", "code", "123456",
                "newPassword", NEW_PASSWORD), HttpStatus.BAD_REQUEST).path("code").asText())
                .isEqualTo("INVALID_RESET_CODE");
    }

    @Test
    void secondRequestWithinTheCooldownSendsNothing() {
        String code = requestCode(EMAIL);
        post("/auth/password/forgot", Map.of("email", EMAIL), HttpStatus.ACCEPTED);
        verify(mailer, after(500).times(1)).sendCode(any(), anyString(), anyString(), anyString(), any());
        post("/auth/password/reset", resetBody(code), HttpStatus.NO_CONTENT);
    }

    @Test
    void newCodeReplacesThePreviousOne() {
        String first = requestCode(EMAIL);
        jdbc.update("UPDATE password_reset_codes SET created_at = created_at - interval '2 minutes'");
        Mockito.clearInvocations(mailer);
        String second = requestCode(EMAIL);

        if (!first.equals(second)) {
            post("/auth/password/reset", resetBody(first), HttpStatus.BAD_REQUEST);
        }
        post("/auth/password/reset", resetBody(second), HttpStatus.NO_CONTENT);
    }

    @Test
    void codeIsLockedAfterFiveWrongAttempts() {
        String code = requestCode(EMAIL);
        for (int attempt = 0; attempt < 5; attempt++) {
            post("/auth/password/reset", resetBody(wrong(code)), HttpStatus.BAD_REQUEST);
        }
        post("/auth/password/reset", resetBody(code), HttpStatus.BAD_REQUEST);
        post("/auth/login", Map.of("email", EMAIL, "password", OLD_PASSWORD), HttpStatus.OK);
    }

    @Test
    void expiredCodeIsRejected() {
        String code = requestCode(EMAIL);
        jdbc.update("UPDATE password_reset_codes SET expires_at = now() - interval '1 second'");
        post("/auth/password/reset", resetBody(code), HttpStatus.BAD_REQUEST);
    }

    @Test
    void disabledAccountReceivesNoCode() {
        jdbc.update("UPDATE users SET enabled = false");
        post("/auth/password/forgot", Map.of("email", EMAIL), HttpStatus.ACCEPTED);
        verify(mailer, after(500).never()).sendCode(any(), anyString(), anyString(), anyString(), any());
    }

    private String requestCode(String email) {
        post("/auth/password/forgot", Map.of("email", email), HttpStatus.ACCEPTED);
        ArgumentCaptor<String> code = ArgumentCaptor.forClass(String.class);
        verify(mailer, timeout(5000)).sendCode(eq(CodePurpose.PASSWORD_RESET), eq(EMAIL), eq("Reset Student"), code.capture(),
                eq(Duration.ofMinutes(15)));
        assertThat(code.getValue()).matches("[0-9]{6}");
        assertThat(jdbc.queryForObject("SELECT code_hash FROM password_reset_codes ORDER BY created_at DESC LIMIT 1",
                String.class)).doesNotContain(code.getValue());
        return code.getValue();
    }

    private static Map<String, String> resetBody(String code) {
        return Map.of("email", EMAIL, "code", code, "newPassword", NEW_PASSWORD);
    }

    private static String wrong(String code) {
        return "%06d".formatted((Integer.parseInt(code) + 1) % 1_000_000);
    }

    private JsonNode post(String path, Object body, HttpStatus expected) {
        return call(HttpMethod.POST, path, null, body, expected);
    }

    private JsonNode call(HttpMethod method, String path, String token, Object body, HttpStatus expected) {
        HttpHeaders headers = new HttpHeaders();
        if (token != null) {
            headers.setBearerAuth(token);
        }
        ResponseEntity<JsonNode> response =
                client.exchange("/api/v1" + path, method, new HttpEntity<>(body, headers), JsonNode.class);
        assertThat(response.getStatusCode()).as("%s %s %s", method, path, response.getBody()).isEqualTo(expected);
        return response.getBody();
    }
}
