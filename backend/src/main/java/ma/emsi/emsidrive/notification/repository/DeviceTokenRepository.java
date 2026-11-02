package ma.emsi.emsidrive.notification.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.notification.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {

    Optional<DeviceToken> findByToken(String token);

    List<DeviceToken> findAllByUserIdAndActiveTrue(UUID userId);

    boolean existsByToken(String token);
}
