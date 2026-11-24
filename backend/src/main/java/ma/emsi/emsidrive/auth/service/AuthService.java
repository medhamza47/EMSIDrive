package ma.emsi.emsidrive.auth.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import ma.emsi.emsidrive.auth.dto.AuthResponse;
import ma.emsi.emsidrive.auth.dto.LoginRequest;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.dto.UserResponse;
import ma.emsi.emsidrive.auth.entity.RefreshToken;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.auth.security.JwtService;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.config.SecurityProperties;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Registration, credential verification and refresh token rotation. */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EmailVerificationService emailVerification;
    private final List<String> studentEmailDomains;

    public AuthService(
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            EmailVerificationService emailVerification,
            SecurityProperties securityProperties) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.emailVerification = emailVerification;
        this.studentEmailDomains = securityProperties.studentEmailDomains().stream()
                .map(domain -> domain.trim().toLowerCase(Locale.ROOT))
                .toList();
    }

    /**
     * Checks the registration form, then emails a code proving the address exists.
     * Nothing is stored about the account until {@link #register} receives the code.
     */
    @Transactional
    public void requestRegistrationCode(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        requireRegistrableEmail(email);
        emailVerification.sendCode(email, request.fullName().trim());
    }

    /**
     * Creates the account once the emailed code is confirmed. A wrong code is counted
     * as an attempt, so business errors keep the transaction's writes.
     */
    @Transactional(noRollbackFor = ApiException.class)
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        requireRegistrableEmail(email);
        if (emailVerification.isRequired()) {
            emailVerification.confirm(email, request.verificationCode());
        }

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(request.password()))
                .fullName(request.fullName().trim())
                .phoneNumber(normalizePhoneNumber(request.phoneNumber()))
                .role(UserRole.STUDENT)
                .enabled(true)
                .build();

        return issueTokens(userRepository.save(user));
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findForLogin(normalizeEmail(request.email()))
                .orElseThrow(AuthService::invalidCredentials);

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw invalidCredentials();
        }
        if (!user.isEnabled()) {
            throw ApiException.forbidden("ACCOUNT_DISABLED", "This account is disabled");
        }
        return issueTokens(user);
    }

    /**
     * Exchanges a valid refresh token for a brand new token pair. The presented token is
     * revoked immediately so a leaked token can only be replayed once at most.
     */
    @Transactional
    public AuthResponse refresh(String rawRefreshToken) {
        Claims claims = parseRefreshClaims(rawRefreshToken);
        String tokenHash = TokenHasher.sha256Hex(rawRefreshToken);

        RefreshToken stored = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> ApiException.unauthorized(
                        "INVALID_REFRESH_TOKEN", "Refresh token is not recognized"));

        if (!stored.isUsable(Instant.now())) {
            throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token is expired or revoked");
        }

        User user = userRepository.findForAuthentication(jwtService.extractUserId(claims))
                .filter(User::isEnabled)
                .orElseThrow(() -> ApiException.unauthorized(
                        "INVALID_REFRESH_TOKEN", "Refresh token owner is not available"));

        stored.setRevokedAt(Instant.now());
        refreshTokenRepository.save(stored);

        AuthResponse response = issueTokens(user);
        refreshTokenRepository.rotatePushSession(tokenHash, TokenHasher.sha256Hex(response.refreshToken()));
        return response;
    }

    /**
     * Ends the session of this refresh token on the server. Idempotent and silent: an
     * unknown, expired or already revoked token simply has nothing left to revoke.
     */
    @Transactional
    public void logout(String rawRefreshToken) {
        refreshTokenRepository.findByTokenHash(TokenHasher.sha256Hex(rawRefreshToken))
                .filter(token -> token.getRevokedAt() == null)
                .ifPresent(token -> {
                    token.setRevokedAt(Instant.now());
                    refreshTokenRepository.save(token);
                });
    }

    /** Issues a fresh token pair; shared with the fingerprint login. */
    AuthResponse issueTokens(User user) {
        String accessToken = jwtService.createAccessToken(user.getId(), user.getEmail(), user.getRole());
        String refreshToken = jwtService.createRefreshToken(user.getId());

        refreshTokenRepository.save(RefreshToken.builder()
                .user(user)
                .tokenHash(TokenHasher.sha256Hex(refreshToken))
                .expiresAt(Instant.now().plus(jwtService.refreshTokenTtl()))
                .build());

        return AuthResponse.bearer(accessToken, refreshToken, jwtService.accessTokenTtlSeconds(),
                UserResponse.from(user));
    }

    private Claims parseRefreshClaims(String rawRefreshToken) {
        Claims claims;
        try {
            claims = jwtService.parse(rawRefreshToken);
        } catch (JwtException | IllegalArgumentException ex) {
            throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token is invalid or expired");
        }
        if (!jwtService.isRefreshToken(claims)) {
            throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Provided token is not a refresh token");
        }
        return claims;
    }

    private void requireRegistrableEmail(String email) {
        requireStudentDomain(email);
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("EMAIL_ALREADY_USED", "An account already exists for this email address");
        }
    }

    private void requireStudentDomain(String email) {
        if (studentEmailDomains.isEmpty()) {
            return;
        }
        String domain = email.substring(email.indexOf('@') + 1);
        if (!studentEmailDomains.contains(domain)) {
            throw ApiException.badRequest(
                    "EMAIL_DOMAIN_NOT_ALLOWED",
                    "Registration is restricted to these student domains: " + String.join(", ", studentEmailDomains));
        }
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static String normalizePhoneNumber(String phoneNumber) {
        if (phoneNumber == null) {
            return null;
        }
        String trimmed = phoneNumber.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static ApiException invalidCredentials() {
        return ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password");
    }
}
