package ma.emsi.emsidrive.rating.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.rating.entity.Rating;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RatingRepository extends JpaRepository<Rating, UUID> {

    Page<Rating> findAllByTargetId(UUID targetId, Pageable pageable);

    List<Rating> findAllByAuthorId(UUID authorId);

    Optional<Rating> findByBookingIdAndAuthorId(UUID bookingId, UUID authorId);

    @Query("SELECT AVG(r.score) FROM Rating r WHERE r.target.id = :targetId")
    Double averageScoreForTarget(@Param("targetId") UUID targetId);

    long countByTargetId(UUID targetId);
}
