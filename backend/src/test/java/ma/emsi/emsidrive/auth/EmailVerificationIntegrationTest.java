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
import java.util.HashMap;
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

/** Registration only creates an account once the emailed code is confirmed. */
@Testcontainers
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class EmailVerificationIntegrationTest {

    private static final String EMAIL = "new.student@emsi-edu.ma";

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
        registry.add("app.security.jwt.secret", () -> "emsidrive-email-verification-test-secret");
        registry.add("app.security.student-email-domains", () -> "emsi-edu.ma");
        registry.add("app.security.email-verification.required", () -> "true");
    }

    @Autowired
    private TestRestTemplate client;

    @Autowired
    private JdbcTemplate jdbc;

    @MockitoBean
    private CodeMailer mailer;

    @BeforeEach
    void cleanDatabase() {
        jdbc.execute("TRUNCATE TABLE users, email_verification_codes CASCADE");
    }

    @Test
    void accountIsCreatedOnlyWithTheEmailedCode() {
        Map<String, Object> form = form(EMAIL);
        assertThat(post("/auth/register", form, HttpStatus.BAD_REQUEST).path("code").asText())
                .isEqualTo("EMAIL_VERIFICATION_REQUIRED");

        String code = requestCode(form);
        assertThat(accounts()).isZero();

        assertThat(post("/auth/register", withCode(form, wrong(code)), HttpStatus.BAD_REQUEST).path("code").asText())
                .isEqualTo("INVALID_VERIFICATION_CODE");
        JsonNode session = post("/auth/register", withCode(form, code), HttpStatus.CREATED);
        assertThat(session.path("user").path("email").asText()).isEqualTo(EMAIL);
        assertThat(session.path("accessToken").asText()).isNotBlank();
        assertThat(accounts()).isEqualTo(1);

        post("/auth/login", Map.of("email", EMAIL, "password", "StrongPass123!"), HttpStatus.OK);
        assertThat(post("/auth/register", withCode(form, code), HttpStatus.CONFLICT).path("code").asText())
                .isEqualTo("EMAIL_ALREADY_USED");
    }

    @Test
    void codeIsCheckedAgainstItsOwnEmail() {
        String code = requestCode(form(EMAIL));

        Map<String, Object> other = withCode(form("other.student@emsi-edu.ma"), code);
        post("/auth/register", other, HttpStatus.BAD_REQUEST);
        assertThat(accounts()).isZero();
    }

    @Test
    void formIsValidatedBeforeAnyEmailIsSent() {
        assertThat(post("/auth/register/code", form("someone@gmail.com"), HttpStatus.BAD_REQUEST)
                .path("code").asText()).isEqualTo("EMAIL_DOMAIN_NOT_ALLOWED");
        Map<String, Object> shortPassword = form(EMAIL);
        shortPassword.put("password", "short");
        post("/auth/register/code", shortPassword, HttpStatus.BAD_REQUEST);

        String code = requestCode(form(EMAIL));
        post("/auth/register", withCode(form(EMAIL), code), HttpStatus.CREATED);
        Mockito.clearInvocations(mailer);
        assertThat(post("/auth/register/code", form(EMAIL), HttpStatus.CONFLICT).path("code").asText())
                .isEqualTo("EMAIL_ALREADY_USED");
        verify(mailer, after(500).never()).sendCode(any(), anyString(), anyString(), anyString(), any());
    }

    @Test
    void resendWithinTheCooldownKeepsThePreviousCode() {
        String code = requestCode(form(EMAIL));
        post("/auth/register/code", form(EMAIL), HttpStatus.ACCEPTED);
        verify(mailer, after(500).times(1)).sendCode(any(), anyString(), anyString(), anyString(), any());

        post("/auth/register", withCode(form(EMAIL), code), HttpStatus.CREATED);
    }

    @Test
    void newCodeReplacesThePreviousOne() {
        String first = requestCode(form(EMAIL));
        jdbc.update("UPDATE email_verification_codes SET created_at = created_at - interval '2 minutes'");
        Mockito.clearInvocations(mailer);
        String second = requestCode(form(EMAIL));

        if (!first.equals(second)) {
            post("/auth/register", withCode(form(EMAIL), first), HttpStatus.BAD_REQUEST);
        }
        post("/auth/register", withCode(form(EMAIL), second), HttpStatus.CREATED);
    }

    @Test
    void codeIsLockedAfterFiveWrongAttemptsAndExpires() {
        String code = requestCode(form(EMAIL));
        for (int attempt = 0; attempt < 5; attempt++) {
            post("/auth/register", withCode(form(EMAIL), wrong(code)), HttpStatus.BAD_REQUEST);
        }
        post("/auth/register", withCode(form(EMAIL), code), HttpStatus.BAD_REQUEST);

        jdbc.update("UPDATE email_verification_codes SET created_at = created_at - interval '2 minutes'");
        Mockito.clearInvocations(mailer);
        String fresh = requestCode(form(EMAIL));
        jdbc.update("UPDATE email_verification_codes SET expires_at = now() - interval '1 second' WHERE consumed_at IS NULL");
        post("/auth/register", withCode(form(EMAIL), fresh), HttpStatus.BAD_REQUEST);
        assertThat(accounts()).isZero();
    }

    @Test
    void hourlyLimitIsReported() {
        for (int sent = 0; sent < 5; sent++) {
            post("/auth/register/code", form(EMAIL), HttpStatus.ACCEPTED);
            jdbc.update("UPDATE email_verification_codes SET created_at = created_at - interval '2 minutes'");
        }
        assertThat(post("/auth/register/code", form(EMAIL), HttpStatus.TOO_MANY_REQUESTS).path("code").asText())
                .isEqualTo("VERIFICATION_CODE_LIMIT");
    }

    private String requestCode(Map<String, Object> form) {
        post("/auth/register/code", form, HttpStatus.ACCEPTED);
        ArgumentCaptor<String> code = ArgumentCaptor.forClass(String.class);
        verify(mailer, timeout(5000)).sendCode(eq(CodePurpose.REGISTRATION), eq((String) form.get("email")),
                eq("New Student"), code.capture(), eq(Duration.ofMinutes(15)));
        assertThat(code.getValue()).matches("[0-9]{6}");
        return code.getValue();
    }

    private int accounts() {
        return jdbc.queryForObject("SELECT count(*) FROM users", Integer.class);
    }

    private static Map<String, Object> form(String email) {
        Map<String, Object> form = new HashMap<>();
        form.put("email", email);
        form.put("password", "StrongPass123!");
        form.put("fullName", "New Student");
        return form;
    }

    private static Map<String, Object> withCode(Map<String, Object> form, String code) {
        Map<String, Object> copy = new HashMap<>(form);
        copy.put("verificationCode", code);
        return copy;
    }

    private static String wrong(String code) {
        return "%06d".formatted((Integer.parseInt(code) + 1) % 1_000_000);
    }

    private JsonNode post(String path, Object body, HttpStatus expected) {
        ResponseEntity<JsonNode> response =
                client.exchange("/api/v1" + path, HttpMethod.POST, new HttpEntity<>(body), JsonNode.class);
        assertThat(response.getStatusCode()).as("POST %s %s", path, response.getBody()).isEqualTo(expected);
        return response.getBody();
    }
}
