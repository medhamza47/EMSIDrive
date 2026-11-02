package ma.emsi.emsidrive.fuel.repository;

import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.fuel.entity.FuelSplit;
import ma.emsi.emsidrive.fuel.entity.FuelSplitStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FuelSplitRepository extends JpaRepository<FuelSplit, UUID> {

    Optional<FuelSplit> findByRideOfferId(UUID rideOfferId);

    Page<FuelSplit> findAllByCreatedById(UUID createdById, Pageable pageable);

    Page<FuelSplit> findAllByStatus(FuelSplitStatus status, Pageable pageable);
}
