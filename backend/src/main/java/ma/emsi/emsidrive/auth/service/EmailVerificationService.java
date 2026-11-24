package ma.emsi.emsidrive.auth.service;

import java.time.Duration;
import java.time.Instant;
import ma.emsi.emsidrive.auth.entity.EmailVerificationCode;
import ma.emsi.emsidrive.auth.mail.CodeMailDispatcher;
import ma.emsi.emsidrive.auth.mail.CodePurpose;
import ma.emsi.emsidrive.auth.repository.EmailVerificationCodeRepository;
import ma.emsi.emsidrive.common.exception.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Proves a registration email exists and belongs to the student: a 6-digit code is
 * emailed, and the account is only created once that code comes back.
 */
@Service
public class EmailVerificationService {

    static final Duration CODE_TTL = Duration.ofMinutes(15);
    static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);
    static final int MAX_CODES_PER_HOUR = 5;
    static final int MAX_ATTEMPTS = 5;

    private final EmailVerificationCodeRepository codeRepository;
    private final JdbcTemplate jdbc;
    private final CodeMailDispatcher mail;
    private final OneTimeCodes codes;
    private final boolean required;

    public EmailVerificationService(
            EmailVerificationCodeRepository codeRepository,
            JdbcTemplate jdbc,
            CodeMailDispatcher mail,
            OneTimeCodes codes,
            @Value("${app.security.email-verification.required:true}") boolean required) {
        this.codeRepository = codeRepository;
        this.jdbc = jdbc;
        this.mail = mail;
        this.codes = codes;
        this.required = required;
    }

    /** Whether registration needs a confirmed email; only disabled in tests. */
    public boolean isRequired() {
        return required;
    }

    /**
     * Emails a new code to an address the caller already checked can be registered.
     * A request inside the resend cooldown keeps the previous code and sends nothing.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void sendCode(String email, String fullName) {
        // Serializes concurrent requests for one address so the limits hold.
        jdbc.queryForList("SELECT pg_advisory_xact_lock(hashtext(?))", "email-verification:" + email);
        Instant now = Instant.now();
        boolean coolingDown = codeRepository.findFirstByEmailOrderByCreatedAtDesc(email)
                .map(latest -> latest.getCreatedAt().isAfter(now.minus(RESEND_COOLDOWN)))
                .orElse(false);
        if (coolingDown) {
            return;
        }
        if (codeRepository.countByEmailAndCreatedAtAfter(email, now.minus(Duration.ofHours(1))) >= MAX_CODES_PER_HOUR) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "VERIFICATION_CODE_LIMIT",
                    "Too many codes requested for this email. Try again later");
        }

        codeRepository.consumeAllForEmail(email, now);
        String code = codes.generate();
        codeRepository.save(EmailVerificationCode.builder()
                .email(email)
                .codeHash(codes.hash(email, code))
                .expiresAt(now.plus(CODE_TTL))
                .build());
        mail.sendAfterCommit(CodePurpose.REGISTRATION, email, fullName, code, CODE_TTL);
    }

    /**
     * Consumes the latest code of the address. A wrong code counts as an attempt, so
     * the caller's transaction must not roll back on {@link ApiException}.
     */
    @Transactional(propagation = Propagation.MANDATORY, noRollbackFor = ApiException.class)
    public void confirm(String email, String code) {
        if (code == null || code.isBlank()) {
            throw ApiException.badRequest("EMAIL_VERIFICATION_REQUIRED", "Confirm the email with the code it received");
        }
        Instant now = Instant.now();
        EmailVerificationCode latest = codeRepository.findFirstByEmailOrderByCreatedAtDesc(email)
                .filter(candidate -> candidate.isUsable(now, MAX_ATTEMPTS))
                .orElseThrow(EmailVerificationService::invalidCode);
        if (!codes.matches(latest.getCodeHash(), email, code.trim())) {
            latest.setAttempts(latest.getAttempts() + 1);
            codeRepository.save(latest);
            throw invalidCode();
        }
        latest.setConsumedAt(now);
        codeRepository.save(latest);
    }

    private static ApiException invalidCode() {
        return ApiException.badRequest("INVALID_VERIFICATION_CODE", "The code is invalid or expired. Request a new one");
    }
}
