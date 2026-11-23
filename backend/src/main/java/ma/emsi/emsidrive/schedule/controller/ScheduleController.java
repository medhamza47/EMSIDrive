package ma.emsi.emsidrive.schedule.controller;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
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
    private final ScheduleImportJobs jobs;
    private final ScheduleMatchingService matching;
    public ScheduleController(ScheduleService schedules, ScheduleAnalysisService analysis, ScheduleImportJobs jobs, ScheduleMatchingService matching) {
        this.schedules = schedules; this.analysis = analysis; this.jobs = jobs; this.matching = matching;
    }
    @PostMapping(value = "/analyze", consumes = "multipart/form-data")
    public AnalysisResponse analyze(@AuthenticationPrincipal AuthenticatedUser user,
            @RequestPart("file") MultipartFile file, @RequestParam(defaultValue = "") String group) {
        return analysis.analyze(user.id(), file, group);
    }
    @PostMapping(value = "/imports", consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public AnalysisJob submit(@AuthenticationPrincipal AuthenticatedUser user, @RequestPart("file") MultipartFile file,
                              @RequestParam(defaultValue = "") String group, @RequestParam(defaultValue = "0") int revision) {
        return jobs.submit(user.id(), file, group, revision);
    }
    @GetMapping("/imports/latest")
    public AnalysisJob latest(@AuthenticationPrincipal AuthenticatedUser user) { return jobs.latest(user.id()); }
    @GetMapping("/imports/{id}")
    public AnalysisJob job(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) { return jobs.get(user.id(), id); }
    @DeleteMapping("/imports/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void dismiss(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) { jobs.dismiss(user.id(), id); }
    @GetMapping("/travel-preferences")
    public TravelPreferences preferences(@AuthenticationPrincipal AuthenticatedUser user) { return matching.preferences(user.id()); }
    @PutMapping("/travel-preferences")
    public TravelPreferences preferences(@AuthenticationPrincipal AuthenticatedUser user, @Valid @RequestBody TravelPreferences request) {
        return matching.savePreferences(user.id(), request);
    }
    @GetMapping("/matches")
    public List<RideMatch> matches(@AuthenticationPrincipal AuthenticatedUser user, @RequestParam(required = false) Integer commuteMinutes) {
        return matching.matches(user.id(), commuteMinutes);
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
