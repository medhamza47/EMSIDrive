package ma.emsi.emsidrive.tracking.repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.tracking.entity.DriverLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverLocationRepository extends JpaRepository<DriverLocation, UUID> {

    Optional<DriverLocation> findFirstByDriverIdOrderByRecordedAtDesc(UUID driverId);

    List<DriverLocation> findAllByDriverIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            UUID driverId, Instant from, Instant to);

    /**
     * Latest location per driver recorded after {@code since}, constrained to a
     * bounding box. Keeps one row per driver by excluding older samples.
     */
    @Query("""
            SELECT l FROM DriverLocation l
            WHERE l.recordedAt >= :since
              AND l.latitude BETWEEN :minLatitude AND :maxLatitude
              AND l.longitude BETWEEN :minLongitude AND :maxLongitude
              AND NOT EXISTS (
                  SELECT 1 FROM DriverLocation newer
                  WHERE newer.driver = l.driver
                    AND newer.recordedAt > l.recordedAt
              )
            ORDER BY l.recordedAt DESC
            """)
    List<DriverLocation> findLatestNear(
            @Param("since") Instant since,
            @Param("minLatitude") BigDecimal minLatitude,
            @Param("maxLatitude") BigDecimal maxLatitude,
            @Param("minLongitude") BigDecimal minLongitude,
            @Param("maxLongitude") BigDecimal maxLongitude);
}
