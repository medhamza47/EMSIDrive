package ma.emsi.emsidrive.notification.push;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class PushIntegrationTest {
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
    @Autowired PlatformTransactionManager transactions;

    @BeforeEach
    void clearDeliveries() {
        jdbc.update("DELETE FROM push_devices");
    }

    private JsonNode account() {
        return client.postForObject("/api/v1/auth/register", Map.of(
                "email", "push-" + UUID.randomUUID() + "@emsi-edu.ma",
                "password", "StrongPass123!", "fullName", "Push Student"), JsonNode.class);
    }

    private ResponseEntity<JsonNode> register(JsonNode user, String token) {
        return device(user, HttpMethod.PUT, Map.of("token", token, "refreshToken", user.path("refreshToken").asText()));
    }

    private ResponseEntity<JsonNode> device(JsonNode user, HttpMethod method, Object body) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(user.path("accessToken").asText());
        return client.exchange("/api/v1/me/push-devices", method, new HttpEntity<>(body, headers), JsonNode.class);
    }

    private UUID notice(JsonNode user) {
        return jdbc.queryForObject("""
                INSERT INTO notifications(user_id, type, title, body, reference_type, reference_id)
                VALUES (?, 'BOOKING', 'CHAT_MESSAGE', '', 'BOOKING', ?) RETURNING id
                """, UUID.class, UUID.fromString(user.path("user").path("id").asText()), UUID.randomUUID());
    }

    private int pending(UUID notice) {
        return jdbc.queryForObject("SELECT count(*) FROM push_deliveries WHERE notification_id = ? AND finished_at IS NULL", Integer.class, notice);
    }

    private PushSender sender(PushSender.Result result) {
        var sender = mock(PushSender.class);
        when(sender.send(anyString(), any(), any(), any(), anyString())).thenReturn(result);
        return sender;
    }

    @Test
    void queuesOnlyNewNoticesAndRollsBackWithTheBusinessTransaction() {
        var user = account();
        UUID old = notice(user);
        assertThat(register(user, UUID.randomUUID().toString()).getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(pending(old)).isZero();
        UUID current = notice(user);
        assertThat(pending(current)).isEqualTo(1);
        new TransactionTemplate(transactions).executeWithoutResult(status -> {
            notice(user);
            status.setRollbackOnly();
        });
        assertThat(jdbc.queryForObject("SELECT count(*) FROM push_deliveries WHERE notification_id <> ?", Integer.class, current)).isZero();
        var sender = sender(PushSender.Result.SENT);
        new PushDeliveryWorker(jdbc, transactions, sender).dispatch();
        assertThat(pending(current)).isZero();
        verify(sender).send(anyString(), eq(current), any(), any(), eq("CHAT_MESSAGE"));
        new PushDeliveryWorker(jdbc, transactions, sender).dispatch();
        verifyNoMoreInteractions(sender);
    }

    @Test
    void rejectsForeignSessionsAndProtectsAccountSwitchesAndRemoval() {
        var first = account();
        var second = account();
        String token = UUID.randomUUID().toString();
        assertThat(device(second, HttpMethod.PUT, Map.of("token", token,
                "refreshToken", first.path("refreshToken").asText())).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        register(first, token);
        UUID old = notice(first);
        register(second, token);
        // The old owner cannot remove the new owner's phone registration.
        device(first, HttpMethod.DELETE, Map.of("token", token));
        UUID current = notice(second);
        var sender = sender(PushSender.Result.SENT);
        new PushDeliveryWorker(jdbc, transactions, sender).dispatch();
        assertThat(pending(old)).isZero();
        assertThat(pending(current)).isZero();
        verify(sender).send(eq(token), eq(current), any(), any(), anyString());
        verifyNoMoreInteractions(sender);
    }

    @Test
    void refreshKeepsThePhoneLinkedAndLogoutStopsQueuedAndFuturePushes() {
        var user = account();
        register(user, UUID.randomUUID().toString());
        var fresh = client.postForObject("/api/v1/auth/refresh", Map.of("refreshToken", user.path("refreshToken").asText()), JsonNode.class);
        UUID current = notice(user);
        assertThat(pending(current)).isEqualTo(1);
        client.postForEntity("/api/v1/auth/logout", Map.of("refreshToken", fresh.path("refreshToken").asText()), Void.class);
        var sender = sender(PushSender.Result.SENT);
        new PushDeliveryWorker(jdbc, transactions, sender).dispatch();
        assertThat(pending(current)).isZero();
        assertThat(pending(notice(user))).isZero();
        verifyNoInteractions(sender);
    }

    @Test
    void retriesTransientFailuresThenRemovesUnregisteredTokens() {
        var user = account();
        String token = UUID.randomUUID().toString();
        register(user, token);
        UUID current = notice(user);
        new PushDeliveryWorker(jdbc, transactions, sender(PushSender.Result.RETRY)).dispatch();
        assertThat(pending(current)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT attempts FROM push_deliveries WHERE notification_id = ?", Integer.class, current)).isEqualTo(1);
        jdbc.update("UPDATE push_deliveries SET available_at = now() WHERE notification_id = ?", current);
        new PushDeliveryWorker(jdbc, transactions, sender(PushSender.Result.UNREGISTERED)).dispatch();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM push_devices WHERE token = ?", Integer.class, token)).isZero();
        assertThat(pending(current)).isZero();
    }
}
