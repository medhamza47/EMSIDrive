package ma.emsi.emsidrive.auth.service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.AuthResponse;
import ma.emsi.emsidrive.auth.dto.LoginRequest;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.entity.RefreshToken;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.auth.security.JwtService;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.config.SecurityProperties;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AuthServiceTest {

    private static final String SECRET = "emsidrive-test-secret-key-with-at-least-32-bytes";
    private static final UUID USER_ID = UUID.fromString("3f1c8a54-6c1e-4a4f-9d2b-1f0f2f5c7a11");
    private static final String STUDENT_EMAIL = "sara.elidrissi@emsi-edu.ma";
    private static final String RAW_PASSWORD = "StrongPass123!";

    @Mock
    private UserRepository userRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private final List<RefreshToken> persistedRefreshTokens = new ArrayList<>();

    private JwtService jwtService;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        SecurityProperties properties = new SecurityProperties(
                new SecurityProperties.Jwt(SECRET, Duration.ofMinutes(15), Duration.ofDays(7)),
                List.of("EMSI-EDU.MA "));
        jwtService = new JwtService(properties);
        authService = new AuthService(
                userRepository, refreshTokenRepository, passwordEncoder, jwtService, properties);
        when(refreshTokenRepository.save(any(RefreshToken.class))).thenAnswer(invocation -> {
            persistedRefreshTokens.add(invocation.getArgument(0));
            return invocation.getArgument(0);
        });
    }

    private static RegisterRequest registerRequest(String email) {
        return new RegisterRequest(email, RAW_PASSWORD, "Sara El Idrissi", "+212612345678");
    }

    private static User student(boolean enabled) {
        return User.builder()
                .id(USER_ID)
                .email(STUDENT_EMAIL)
                .passwordHash("placeholder")
                .fullName("Sara El Idrissi")
                .role(UserRole.STUDENT)
                .enabled(enabled)
                .build();
    }

    private void stubUserSaveAssignsId() {
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            saved.setId(USER_ID);
            return saved;
        });
    }

    private String storeRefreshToken(Instant expiresAt, Instant revokedAt) {
        String raw = jwtService.createRefreshToken(USER_ID);
        RefreshToken token = RefreshToken.builder()
                .user(student(true))
                .tokenHash(TokenHasher.sha256Hex(raw))
                .expiresAt(expiresAt)
                .revokedAt(revokedAt)
                .build();
        when(refreshTokenRepository.findByTokenHash(token.getTokenHash())).thenReturn(Optional.of(token));
        return raw;
    }

    @Test
    void registerCreatesStudentAccountWithHashedPasswordAndIssuesTokens() {
        stubUserSaveAssignsId();
        when(userRepository.existsByEmailIgnoreCase(STUDENT_EMAIL)).thenReturn(false);

        AuthResponse response = authService.register(registerRequest("  Sara.ElIdrissi@EMSI-EDU.ma  "));

        User saved = capturedSavedUser();
        assertThat(saved.getEmail()).isEqualTo(STUDENT_EMAIL);
        assertThat(saved.getRole()).isEqualTo(UserRole.STUDENT);
        assertThat(saved.isEnabled()).isTrue();
        assertThat(saved.getFullName()).isEqualTo("Sara El Idrissi");
        assertThat(saved.getPhoneNumber()).isEqualTo("+212612345678");
        assertThat(saved.getPasswordHash()).isNotEqualTo(RAW_PASSWORD);
        assertThat(passwordEncoder.matches(RAW_PASSWORD, saved.getPasswordHash())).isTrue();

        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresIn()).isEqualTo(900);
        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.user().id()).isEqualTo(USER_ID);
        assertThat(response.user().email()).isEqualTo(STUDENT_EMAIL);
        assertThat(response.user().role()).isEqualTo(UserRole.STUDENT);
    }

    @Test
    void registerPersistsOnlyTheRefreshTokenHash() {
        stubUserSaveAssignsId();
        when(userRepository.existsByEmailIgnoreCase(anyString())).thenReturn(false);

        AuthResponse response = authService.register(registerRequest(STUDENT_EMAIL));

        assertThat(persistedRefreshTokens).hasSize(1);
        RefreshToken stored = persistedRefreshTokens.get(0);
        assertThat(stored.getTokenHash())
                .isEqualTo(TokenHasher.sha256Hex(response.refreshToken()))
                .isNotEqualTo(response.refreshToken());
        assertThat(stored.getUser().getId()).isEqualTo(USER_ID);
        assertThat(stored.getRevokedAt()).isNull();
        assertThat(stored.getExpiresAt()).isAfter(Instant.now().plus(Duration.ofDays(6)));
    }

    @Test
    void registerRejectsEmailOutsideStudentDomains() {
        assertThatThrownBy(() -> authService.register(registerRequest("sara@gmail.com")))
                .isInstanceOfSatisfying(ApiException.class, ex -> {
                    assertThat(ex.getCode()).isEqualTo("EMAIL_DOMAIN_NOT_ALLOWED");
                    assertThat(ex.getStatus().value()).isEqualTo(400);
                });
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void registerAcceptsStudentDomainRegardlessOfCase() {
        stubUserSaveAssignsId();
        when(userRepository.existsByEmailIgnoreCase(anyString())).thenReturn(false);

        assertThat(authService.register(registerRequest("sara@EMSI-EDU.MA")).user().role())
                .isEqualTo(UserRole.STUDENT);
    }

    @Test
    void registerRejectsAlreadyUsedEmail() {
        when(userRepository.existsByEmailIgnoreCase(STUDENT_EMAIL)).thenReturn(true);

        assertThatThrownBy(() -> authService.register(registerRequest(STUDENT_EMAIL)))
                .isInstanceOfSatisfying(ApiException.class, ex -> {
                    assertThat(ex.getCode()).isEqualTo("EMAIL_ALREADY_USED");
                    assertThat(ex.getStatus().value()).isEqualTo(409);
                });
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void loginIssuesTokensForValidCredentials() {
        User user = student(true);
        user.setPasswordHash(passwordEncoder.encode(RAW_PASSWORD));
        when(userRepository.findByEmailIgnoreCase(STUDENT_EMAIL)).thenReturn(Optional.of(user));

        AuthResponse response = authService.login(new LoginRequest("  Sara.ElIdrissi@EMSI-EDU.ma  ", RAW_PASSWORD));

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.user().id()).isEqualTo(USER_ID);
        assertThat(persistedRefreshTokens).hasSize(1);
    }

    @Test
    void loginRejectsUnknownEmail() {
        when(userRepository.findByEmailIgnoreCase(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(new LoginRequest(STUDENT_EMAIL, RAW_PASSWORD)))
                .isInstanceOfSatisfying(ApiException.class, ex -> {
                    assertThat(ex.getCode()).isEqualTo("INVALID_CREDENTIALS");
                    assertThat(ex.getStatus().value()).isEqualTo(401);
                });
        assertThat(persistedRefreshTokens).isEmpty();
    }

    @Test
    void loginRejectsWrongPassword() {
        User user = student(true);
        user.setPasswordHash(passwordEncoder.encode(RAW_PASSWORD));
        when(userRepository.findByEmailIgnoreCase(STUDENT_EMAIL)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(new LoginRequest(STUDENT_EMAIL, "WrongPass123!")))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_CREDENTIALS"));
        assertThat(persistedRefreshTokens).isEmpty();
    }

    @Test
    void loginRejectsDisabledAccount() {
        User user = student(false);
        user.setPasswordHash(passwordEncoder.encode(RAW_PASSWORD));
        when(userRepository.findByEmailIgnoreCase(STUDENT_EMAIL)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(new LoginRequest(STUDENT_EMAIL, RAW_PASSWORD)))
                .isInstanceOfSatisfying(ApiException.class, ex -> {
                    assertThat(ex.getCode()).isEqualTo("ACCOUNT_DISABLED");
                    assertThat(ex.getStatus().value()).isEqualTo(403);
                });
        assertThat(persistedRefreshTokens).isEmpty();
    }

    @Test
    void refreshRotatesTheTokenPairAndRevokesThePreviousToken() {
        String raw = storeRefreshToken(Instant.now().plus(Duration.ofDays(7)), null);
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(student(true)));

        AuthResponse response = authService.refresh(raw);

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank().isNotEqualTo(raw);
        assertThat(persistedRefreshTokens).hasSize(2);
        assertThat(persistedRefreshTokens.get(0).getRevokedAt()).isNotNull();
        assertThat(persistedRefreshTokens.get(1).getRevokedAt()).isNull();
        assertThat(persistedRefreshTokens.get(1).getTokenHash())
                .isEqualTo(TokenHasher.sha256Hex(response.refreshToken()));
    }

    @Test
    void refreshRejectsUnknownToken() {
        when(refreshTokenRepository.findByTokenHash(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refresh(jwtService.createRefreshToken(USER_ID)))
                .isInstanceOfSatisfying(ApiException.class, ex -> {
                    assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN");
                    assertThat(ex.getStatus().value()).isEqualTo(401);
                });
    }

    @Test
    void refreshRejectsAlreadyRevokedToken() {
        String raw = storeRefreshToken(
                Instant.now().plus(Duration.ofDays(7)), Instant.now().minusSeconds(30));

        assertThatThrownBy(() -> authService.refresh(raw))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN"));
        assertThat(persistedRefreshTokens).isEmpty();
    }

    @Test
    void refreshRejectsExpiredToken() {
        String raw = storeRefreshToken(Instant.now().minusSeconds(5), null);

        assertThatThrownBy(() -> authService.refresh(raw))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN"));
    }

    @Test
    void refreshRejectsAccessToken() {
        String accessToken = jwtService.createAccessToken(USER_ID, STUDENT_EMAIL, UserRole.STUDENT);

        assertThatThrownBy(() -> authService.refresh(accessToken))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN"));
    }

    @Test
    void refreshRejectsMalformedToken() {
        assertThatThrownBy(() -> authService.refresh("not-a-jwt"))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN"));
    }

    @Test
    void refreshRejectsTokenOfDisabledOwner() {
        String raw = storeRefreshToken(Instant.now().plus(Duration.ofDays(7)), null);
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(student(false)));

        assertThatThrownBy(() -> authService.refresh(raw))
                .isInstanceOfSatisfying(ApiException.class, ex ->
                        assertThat(ex.getCode()).isEqualTo("INVALID_REFRESH_TOKEN"));
    }

    private User capturedSavedUser() {
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        return captor.getValue();
    }
}
