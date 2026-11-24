package ma.emsi.emsidrive.auth.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.auth.entity.EmailVerificationCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface EmailVerificationCodeRepository extends JpaRepository<EmailVerificationCode, UUID> {

    /** Most recent code for the address, used for verification and the resend cooldown. */
    Optional<EmailVerificationCode> findFirstByEmailOrderByCreatedAtDesc(String email);

    long countByEmailAndCreatedAtAfter(String email, Instant since);

    /** Closes every open code, so only the newest one emailed can ever be used. */
    @Modifying(flushAutomatically = true)
    @Query("UPDATE EmailVerificationCode c SET c.consumedAt = :now, c.updatedAt = :now "
            + "WHERE c.email = :email AND c.consumedAt IS NULL")
    int consumeAllForEmail(@Param("email") String email, @Param("now") Instant now);
}
