package ma.emsi.emsidrive.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.admin.entity.ReportStatus;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class ModerationController {
    private final ModerationService service;

    public ModerationController(ModerationService service) { this.service = service; }

    public record AccountDecision(@NotNull Boolean enabled, @NotBlank @Size(max = 500) String reason,
                                  @NotBlank String revision) {}
    public record ReportDecision(@NotNull ReportStatus status, @NotBlank @Size(max = 500) String reason,
                                 @Min(1) int revision) {}

    @GetMapping("/dashboard")
    public Map<String, Object> dashboard() { return service.dashboard(); }

    @GetMapping("/users")
    public Map<String, Object> users(@RequestParam(defaultValue = "") String search,
            @RequestParam(required = false) Boolean enabled, @RequestParam(defaultValue = "0") int page) {
        return service.users(search, enabled, page);
    }

    @GetMapping("/users/{id}")
    public Map<String, Object> user(@PathVariable UUID id) { return service.user(id); }

    @PutMapping("/users/{id}/access")
    public void access(@AuthenticationPrincipal AuthenticatedUser actor, @PathVariable UUID id,
                       @Valid @RequestBody AccountDecision input) { service.access(actor.id(), id, input); }

    @GetMapping("/rides")
    public Map<String, Object> rides(@RequestParam(defaultValue = "") String kind,
            @RequestParam(defaultValue = "") String status, @RequestParam(defaultValue = "") String campus,
            @RequestParam(required = false) LocalDate date, @RequestParam(defaultValue = "0") int page) {
        return service.rides(kind, status, campus, date, page);
    }

    @GetMapping("/reports")
    public Map<String, Object> reports(@RequestParam(required = false) ReportStatus status,
                                     @RequestParam(defaultValue = "0") int page) {
        return service.reports(status, page);
    }

    @PutMapping("/reports/{id}")
    public void resolve(@AuthenticationPrincipal AuthenticatedUser actor, @PathVariable UUID id,
                        @Valid @RequestBody ReportDecision input) { service.resolve(actor.id(), id, input); }

    @GetMapping("/audit")
    public Map<String, Object> audit(@RequestParam(defaultValue = "0") int page) { return service.audit(page); }
}
