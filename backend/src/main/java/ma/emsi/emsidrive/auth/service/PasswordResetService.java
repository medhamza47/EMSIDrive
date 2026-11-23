package ma.emsi.emsidrive.auth.service;

import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;
import ma.emsi.emsidrive.auth.entity.PasswordResetCode;
import ma.emsi.emsidrive.auth.mail.CodeMailDispatcher;
import ma.emsi.emsidrive.auth.mail.CodePurpose;
import ma.emsi.emsidrive.auth.repository.PasswordResetCodeRepository;
import ma.emsi.emsidrive.auth.repository.RefreshTokenRepository;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Forgotten password flow: a 6-digit code is emailed, then exchanged once for a new
 * password. Answers never reveal whether an email belongs to an account.
 */
@Service
public class PasswordResetService {

    static final Duration CODE_TTL = Duration.ofMinutes(15);
    static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);
    static final int MAX_CODES_PER_HOUR = 5;
    static final int MAX_ATTEMPTS = 5;

    private final UserRepository userRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final CodeMailDispatcher mail;
    private final OneTimeCodes codes;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordResetCodeRepository codeRepository,
            RefreshTokenRepository refreshTokenRepository,
            JdbcTemplate jdbc,
            PasswordEncoder passwordEncoder,
            CodeMailDispatcher mail,
            OneTimeCodes codes) {
        this.userRepository = userRepository;
        this.codeRepository = codeRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.mail = mail;
        this.codes = codes;
    }

    /**
     * Emails a new code when the address belongs to an active account. Unknown
     * addresses, disabled accounts and throttled requests return silently with the
     * same answer, and the email leaves after the commit on another thread.
     */
    @Transactional
    public void requestReset(String rawEmail) {
        Optional<User> account = userRepository.findForLogin(normalizeEmail(rawEmail))
                .filter(User::isEnabled);
        if (account.isEmpty()) {
            return;
        }
        User user = account.get();
        Instant now = Instant.now();
        boolean coolingDown = codeRepository.findFirstByUserIdOrderByCreatedAtDesc(user.getId())
                .map(latest -> latest.getCreatedAt().isAfter(now.minus(RESEND_COOLDOWN)))
                .orElse(false);
        if (coolingDown
                || codeRepository.countByUserIdAndCreatedAtAfter(user.getId(), now.minus(Duration.ofHours(1)))
                        >= MAX_CODES_PER_HOUR) {
            return;
        }

        codeRepository.consumeAllForUser(user.getId(), now);
        String code = codes.generate();
        codeRepository.save(PasswordResetCode.builder()
                .user(user)
                .codeHash(codes.hash(user.getId().toString(), code))
                .expiresAt(now.plus(CODE_TTL))
                .build());

        mail.sendAfterCommit(CodePurpose.PASSWORD_RESET, user.getEmail(), user.getFullName(), code, CODE_TTL);
    }

    /**
     * Sets a new password with the latest emailed code, then ends every session of
     * the account: refresh tokens, fingerprint links, push devices and access tokens.
     */
    @Transactional(noRollbackFor = ApiException.class)
    public void resetPassword(String rawEmail, String code, String newPassword) {
        User user = userRepository.findForLogin(normalizeEmail(rawEmail))
                .filter(User::isEnabled)
                .orElseThrow(PasswordResetService::invalidCode);
        Instant now = Instant.now();
        PasswordResetCode latest = codeRepository.findFirstByUserIdOrderByCreatedAtDesc(user.getId())
                .filter(candidate -> candidate.isUsable(now, MAX_ATTEMPTS))
                .orElseThrow(PasswordResetService::invalidCode);

        if (!codes.matches(latest.getCodeHash(), user.getId().toString(), code)) {
            latest.setAttempts(latest.getAttempts() + 1);
            codeRepository.save(latest);
            throw invalidCode();
        }

        latest.setConsumedAt(now);
        codeRepository.save(latest);
        codeRepository.consumeAllForUser(user.getId(), now);

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setAccessInvalidatedAt(now);
        userRepository.save(user);

        refreshTokenRepository.revokeAllForUser(user.getId(), now);
        jdbc.update("UPDATE biometric_devices SET revoked_at = now() WHERE user_id = ? AND revoked_at IS NULL",
                user.getId());
        jdbc.update("DELETE FROM push_devices WHERE user_id = ?", user.getId());
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static ApiException invalidCode() {
        return ApiException.badRequest("INVALID_RESET_CODE", "The code is invalid or expired. Request a new one");
    }
}
