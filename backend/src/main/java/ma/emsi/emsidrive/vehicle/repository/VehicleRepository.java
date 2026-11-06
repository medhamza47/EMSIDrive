package ma.emsi.emsidrive.vehicle.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.vehicle.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {

    List<Vehicle> findAllByOwnerIdOrderByCreatedAtDesc(UUID ownerId);

    List<Vehicle> findAllByOwnerIdAndActiveTrue(UUID ownerId);

    Optional<Vehicle> findByPlateNumberIgnoreCase(String plateNumber);

    boolean existsByPlateNumberIgnoreCase(String plateNumber);

    Optional<Vehicle> findByIdAndOwnerId(UUID id, UUID ownerId);
}
