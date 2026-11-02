package ma.emsi.emsidrive.schedule.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.schedule.entity.Schedule;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, UUID> {

    Page<Schedule> findAllByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    List<Schedule> findAllByUserIdAndActiveTrue(UUID userId);

    Optional<Schedule> findFirstByUserIdAndActiveTrueOrderByCreatedAtDesc(UUID userId);
}
