package ma.emsi.emsidrive.ride.repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.ride.entity.RideOffer;
import ma.emsi.emsidrive.ride.entity.RideOfferStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RideOfferRepository extends JpaRepository<RideOffer, UUID> {

    Page<RideOffer> findAllByDriverId(UUID driverId, Pageable pageable);

    Page<RideOffer> findAllByStatusAndDepartureTimeBetween(
            RideOfferStatus status, Instant from, Instant to, Pageable pageable);

    List<RideOffer> findAllByVehicleId(UUID vehicleId);

    /**
     * Bounding-box search on the origin coordinates, restricted to open offers with
     * enough free seats inside the requested departure window.
     */
    @Query("""
            SELECT o FROM RideOffer o
            WHERE o.status = :status
              AND o.availableSeats >= :seats
              AND o.departureTime BETWEEN :from AND :to
              AND o.originLatitude BETWEEN :minLatitude AND :maxLatitude
              AND o.originLongitude BETWEEN :minLongitude AND :maxLongitude
            ORDER BY o.departureTime ASC
            """)
    List<RideOffer> findNearOrigin(
            @Param("status") RideOfferStatus status,
            @Param("seats") Short seats,
            @Param("from") Instant from,
            @Param("to") Instant to,
            @Param("minLatitude") BigDecimal minLatitude,
            @Param("maxLatitude") BigDecimal maxLatitude,
            @Param("minLongitude") BigDecimal minLongitude,
            @Param("maxLongitude") BigDecimal maxLongitude);
}
