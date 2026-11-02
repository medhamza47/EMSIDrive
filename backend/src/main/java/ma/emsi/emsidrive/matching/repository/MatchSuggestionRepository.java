package ma.emsi.emsidrive.matching.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.matching.entity.MatchSuggestion;
import ma.emsi.emsidrive.matching.entity.MatchSuggestionStatus;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MatchSuggestionRepository extends JpaRepository<MatchSuggestion, UUID> {

    Optional<MatchSuggestion> findByRideRequestIdAndRideOfferId(UUID rideRequestId, UUID rideOfferId);

    List<MatchSuggestion> findAllByRideRequestIdAndStatusOrderByScoreDesc(
            UUID rideRequestId, MatchSuggestionStatus status);

    List<MatchSuggestion> findAllByRideOfferId(UUID rideOfferId);

    List<MatchSuggestion> findAllByStatusOrderByScoreDesc(MatchSuggestionStatus status, Limit limit);
}
