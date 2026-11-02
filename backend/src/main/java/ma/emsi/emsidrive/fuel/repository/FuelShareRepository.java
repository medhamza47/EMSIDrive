package ma.emsi.emsidrive.fuel.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.fuel.entity.FuelShare;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FuelShareRepository extends JpaRepository<FuelShare, UUID> {

    List<FuelShare> findAllByFuelSplitId(UUID fuelSplitId);

    Optional<FuelShare> findByFuelSplitIdAndUserId(UUID fuelSplitId, UUID userId);

    List<FuelShare> findAllByUserIdAndPaidFalse(UUID userId);
}
