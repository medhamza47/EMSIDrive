package ma.emsi.emsidrive.schedule.repository;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.schedule.entity.ScheduleSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ScheduleSlotRepository extends JpaRepository<ScheduleSlot, UUID> {

    List<ScheduleSlot> findAllByScheduleIdOrderByWeekdayAscStartTimeAsc(UUID scheduleId);

    List<ScheduleSlot> findAllByScheduleUserIdAndWeekday(UUID userId, Short weekday);

    /** Slots on {@code weekday} that overlap the given time window. */
    @Query("""
            SELECT s FROM ScheduleSlot s
            WHERE s.schedule.user.id = :userId
              AND s.weekday = :weekday
              AND s.startTime < :endTime
              AND s.endTime > :startTime
            """)
    List<ScheduleSlot> findOverlapping(
            @Param("userId") UUID userId,
            @Param("weekday") Short weekday,
            @Param("startTime") LocalTime startTime,
            @Param("endTime") LocalTime endTime);
}
