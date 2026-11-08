package ma.emsi.emsidrive.schedule.controller;

import jakarta.validation.Valid;
import java.util.List;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import ma.emsi.emsidrive.schedule.service.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/schedules")
public class ScheduleController {
    private final ScheduleService schedules;
    private final ScheduleAnalysisService analysis;
    public ScheduleController(ScheduleService schedules, ScheduleAnalysisService analysis) {
        this.schedules = schedules; this.analysis = analysis;
    }
    @PostMapping(value = "/analyze", consumes = "multipart/form-data")
    public AnalysisResponse analyze(@AuthenticationPrincipal AuthenticatedUser user,
            @RequestPart("file") MultipartFile file, @RequestParam(defaultValue = "") String group) {
        return analysis.analyze(user.id(), file, group);
    }
    @GetMapping("/current")
    public ScheduleResponse current(@AuthenticationPrincipal AuthenticatedUser user) { return schedules.current(user.id()); }
    @PutMapping("/current")
    public ScheduleResponse save(@AuthenticationPrincipal AuthenticatedUser user, @Valid @RequestBody SaveRequest request) {
        return schedules.save(user.id(), request);
    }
    @DeleteMapping("/current")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal AuthenticatedUser user) { schedules.delete(user.id()); }
    @GetMapping("/suggestions")
    public List<Suggestion> suggestions(@AuthenticationPrincipal AuthenticatedUser user,
            @RequestParam(defaultValue = "30") int commuteMinutes, @RequestParam(defaultValue = "10") int marginMinutes) {
        if (commuteMinutes < 5 || commuteMinutes > 180 || marginMinutes < 0 || marginMinutes > 60) {
            throw ApiException.badRequest("VALIDATION_ERROR", "Invalid commute or margin");
        }
        return schedules.suggestions(user.id(), commuteMinutes, marginMinutes);
    }
}
