package ma.emsi.emsidrive.auth.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.auth.entity.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, UUID> {

    /** Most recent code of the account, used for verification and the resend cooldown. */
    Optional<PasswordResetCode> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);

    long countByUserIdAndCreatedAtAfter(UUID userId, Instant since);

    /** Closes every open code, so only the newest one emailed can ever be used. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("UPDATE PasswordResetCode c SET c.consumedAt = :now, c.updatedAt = :now "
            + "WHERE c.user.id = :userId AND c.consumedAt IS NULL")
    int consumeAllForUser(@Param("userId") UUID userId, @Param("now") Instant now);
}
