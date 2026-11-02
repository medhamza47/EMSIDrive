package ma.emsi.emsidrive.auth.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.config.SecurityProperties;
import ma.emsi.emsidrive.user.entity.UserRole;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private static final String SECRET = "emsidrive-test-secret-key-with-at-least-32-bytes";
    private static final UUID USER_ID = UUID.fromString("3f1c8a54-6c1e-4a4f-9d2b-1f0f2f5c7a11");

    private static JwtService service(String secret, Duration accessTtl, Duration refreshTtl) {
        return new JwtService(new SecurityProperties(
                new SecurityProperties.Jwt(secret, accessTtl, refreshTtl),
                List.of("emsi-edu.ma")));
    }

    private static JwtService service() {
        return service(SECRET, Duration.ofMinutes(15), Duration.ofDays(7));
    }

    @Test
    void accessTokenCarriesSubjectEmailAndRole() {
        JwtService jwtService = service();

        Claims claims = jwtService.parse(
                jwtService.createAccessToken(USER_ID, "sara@emsi-edu.ma", UserRole.STUDENT));

        assertThat(jwtService.extractUserId(claims)).isEqualTo(USER_ID);
        assertThat(claims.get("email", String.class)).isEqualTo("sara@emsi-edu.ma");
        assertThat(claims.get("role", String.class)).isEqualTo("STUDENT");
        assertThat(claims.getId()).isNotBlank();
    }

    @Test
    void accessAndRefreshTokensAreDistinguishable() {
        JwtService jwtService = service();

        assertThat(jwtService.isAccessToken(jwtService.parse(jwtService.createAccessToken(
                USER_ID, "admin@emsi-edu.ma", UserRole.ADMIN)))).isTrue();
        assertThat(jwtService.isRefreshToken(jwtService.parse(jwtService.createRefreshToken(USER_ID))))
                .isTrue();
        assertThat(jwtService.isAccessToken(jwtService.parse(jwtService.createRefreshToken(USER_ID))))
                .isFalse();
    }

    @Test
    void toAuthenticatedUserExposesRoleAuthority() {
        JwtService jwtService = service();

        AuthenticatedUser user = jwtService.toAuthenticatedUser(jwtService.parse(
                jwtService.createAccessToken(USER_ID, "admin@emsi-edu.ma", UserRole.ADMIN)));

        assertThat(user.id()).isEqualTo(USER_ID);
        assertThat(user.email()).isEqualTo("admin@emsi-edu.ma");
        assertThat(user.role()).isEqualTo(UserRole.ADMIN);
        assertThat(user.authorities()).extracting("authority").containsExactly("ROLE_ADMIN");
    }

    @Test
    void exposesConfiguredLifetimes() {
        JwtService jwtService = service(SECRET, Duration.ofMinutes(30), Duration.ofDays(3));

        assertThat(jwtService.accessTokenTtlSeconds()).isEqualTo(1800);
        assertThat(jwtService.refreshTokenTtl()).isEqualTo(Duration.ofDays(3));
    }

    @Test
    void rejectsTokenSignedWithAnotherSecret() {
        String foreignToken = service("a-completely-different-secret-key-of-32-bytes",
                Duration.ofMinutes(15), Duration.ofDays(7))
                .createAccessToken(USER_ID, "sara@emsi-edu.ma", UserRole.STUDENT);

        assertThatThrownBy(() -> service().parse(foreignToken)).isInstanceOf(JwtException.class);
    }

    @Test
    void rejectsExpiredToken() {
        JwtService expiredIssuer = service(SECRET, Duration.ofSeconds(-60), Duration.ofDays(7));
        String expired = expiredIssuer.createAccessToken(USER_ID, "sara@emsi-edu.ma", UserRole.STUDENT);

        assertThatThrownBy(() -> service().parse(expired)).isInstanceOf(JwtException.class);
    }

    @Test
    void rejectsTamperedToken() {
        JwtService jwtService = service();
        String token = jwtService.createAccessToken(USER_ID, "sara@emsi-edu.ma", UserRole.STUDENT);
        String tampered = token.substring(0, token.length() - 2) + "xy";

        assertThatThrownBy(() -> jwtService.parse(tampered)).isInstanceOf(JwtException.class);
    }

    @Test
    void rejectsSecretShorterThanThirtyTwoBytes() {
        assertThatThrownBy(() -> service("too-short-secret", Duration.ofMinutes(15), Duration.ofDays(7)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("at least 32 bytes");
    }
}
