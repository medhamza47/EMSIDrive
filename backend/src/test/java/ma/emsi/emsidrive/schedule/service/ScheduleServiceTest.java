package ma.emsi.emsidrive.schedule.service;

import java.time.*;
import java.util.List;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Campus;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class ScheduleServiceTest {
    private Slot slot(int day, String start, String end) {
        return new Slot("Course", null, day, LocalTime.parse(start), LocalTime.parse(end), Campus.TARGA);
    }
    private SaveRequest request(List<Slot> slots) {
        return new SaveRequest("G1", ScheduleSource.MANUAL, LocalDate.of(2026, 9, 1), LocalDate.of(2027, 1, 31), true, 0, slots);
    }
    @Test void allowsAdjacentCoursesAndDifferentDays() {
        assertThatCode(() -> ScheduleService.validate(request(List.of(slot(1,"08:30","10:00"), slot(1,"10:00","11:45"), slot(2,"08:30","10:00")))))
                .doesNotThrowAnyException();
    }
    @Test void rejectsNestedOrPartialOverlapsRegardlessOfOrder() {
        assertThatThrownBy(() -> ScheduleService.validate(request(List.of(slot(1,"10:00","11:00"), slot(1,"08:30","12:00")))))
                .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getCode()).isEqualTo("SCHEDULE_OVERLAP"));
    }
    @Test void rejectsInvalidTimeOrderAndSubMinuteTimes() {
        for (var s : List.of(slot(1,"10:00","08:30"), slot(1,"08:30:01","10:00"))) {
            assertThatThrownBy(() -> ScheduleService.validate(request(List.of(s))))
                    .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getCode()).isEqualTo("SCHEDULE_TIMES_INVALID"));
        }
    }
    @Test void enforcesConfirmationAndValidity() {
        var base = request(List.of(slot(1,"08:30","10:00")));
        assertThatThrownBy(() -> ScheduleService.validate(new SaveRequest(base.name(), base.source(), base.validFrom(), base.validUntil(), false, 0, base.slots())))
                .isInstanceOf(ApiException.class);
        for (var end : List.of(base.validFrom().minusDays(1), base.validFrom().plusYears(1).plusDays(1))) {
            assertThatThrownBy(() -> ScheduleService.validate(new SaveRequest(base.name(),base.source(),base.validFrom(),end,true,0,base.slots())))
                    .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getCode()).isEqualTo("SCHEDULE_DATES_INVALID"));
        }
    }
    @Test void matchesOutboundUsingTravelEstimateAndReturnAfterClass() {
        assertThat(ScheduleService.matches(true, 39, 30, 10)).isFalse();
        assertThat(ScheduleService.matches(true, 40, 30, 10)).isTrue();
        assertThat(ScheduleService.matches(true, 100, 30, 10)).isTrue();
        assertThat(ScheduleService.matches(true, 101, 30, 10)).isFalse();
        assertThat(ScheduleService.matches(false, 1, 30, 10)).isFalse();
        assertThat(ScheduleService.matches(false, 0, 30, 10)).isTrue();
        assertThat(ScheduleService.matches(false, -60, 30, 10)).isTrue();
        assertThat(ScheduleService.matches(false, -61, 30, 10)).isFalse();
    }
}
