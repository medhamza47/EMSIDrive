package ma.emsi.emsidrive.ride.repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.ride.entity.RideRequest;
import ma.emsi.emsidrive.ride.entity.RideRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RideRequestRepository extends JpaRepository<RideRequest, UUID> {

    Page<RideRequest> findAllByPassengerId(UUID passengerId, Pageable pageable);

    List<RideRequest> findAllByStatusAndDepartureTimeBetween(
            RideRequestStatus status, Instant from, Instant to);
}
