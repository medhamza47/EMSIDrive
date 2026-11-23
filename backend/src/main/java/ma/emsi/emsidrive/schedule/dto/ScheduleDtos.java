package ma.emsi.emsidrive.schedule.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Campus;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Point;
import java.time.Instant;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;

public final class ScheduleDtos {
    private ScheduleDtos() {}

    public record Slot(@Size(max = 120) String label,
                       @Size(max = 160) String location,
                       @NotNull @Min(1) @Max(7) Integer weekday,
                       @NotNull LocalTime startTime, @NotNull LocalTime endTime,
                       Campus campus) {}

    public record SaveRequest(@NotBlank @Size(max = 120) String name,
                              @NotNull ScheduleSource source,
                              @NotNull LocalDate validFrom, @NotNull LocalDate validUntil,
                              @NotNull @AssertTrue Boolean confirmed,
                              @NotNull @Min(0) Integer revision,
                              @NotEmpty @Size(max = 80) List<@NotNull @Valid Slot> slots,
                              UUID analysisJobId) {
        public SaveRequest(String name, ScheduleSource source, LocalDate validFrom, LocalDate validUntil,
                           Boolean confirmed, Integer revision, List<Slot> slots) {
            this(name, source, validFrom, validUntil, confirmed, revision, slots, null);
        }
    }

    public record ScheduleResponse(UUID id, String name, ScheduleSource source,
                                   LocalDate validFrom, LocalDate validUntil,
                                   int revision, List<Slot> slots) {}

    // Draft fields can be null: the user must correct uncertainty before saving.
    public record DraftSlot(String label, String location, Integer weekday,
                            String startTime, String endTime, Campus campus,
                            boolean needsReview) {}
    public record AnalysisResponse(ScheduleSource source, String name, List<DraftSlot> slots,
                                   List<String> warnings) {}
    public record Suggestion(Map<String, Object> listing, LocalDate date, boolean toCampus,
                             LocalTime courseTime, int departureGapMinutes) {}

    public record AnalysisJob(UUID id, String status, int revision, AnalysisResponse draft,
                              String errorCode, Instant createdAt) {}

    public record TravelPreferences(@NotNull Campus campus, @NotNull @Valid Point point,
                                    @Min(100) @Max(10000) int radiusMeters,
                                    @Min(5) @Max(180) int commuteMinutes,
                                    @Min(0) @Max(60) int marginMinutes) {}

    public record RideMatch(Map<String, Object> listing, LocalDate date, boolean toCampus,
                            LocalTime courseTime, int departureGapMinutes, int distanceMeters) {}
}
