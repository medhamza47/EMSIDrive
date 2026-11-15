package ma.emsi.emsidrive.auth.repository;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.auth.entity.BiometricDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BiometricDeviceRepository extends JpaRepository<BiometricDevice, UUID> {

    /** Locks the row so two logins with the same key cannot both rotate it. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT d FROM BiometricDevice d JOIN FETCH d.user WHERE d.id = :id")
    Optional<BiometricDevice> findForUpdate(@Param("id") UUID id);
}
