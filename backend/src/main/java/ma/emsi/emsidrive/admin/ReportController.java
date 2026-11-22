package ma.emsi.emsidrive.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.admin.entity.ReportCategory;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Kind;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {
    private final ReportService service;
    public ReportController(ReportService service) { this.service = service; }

    public record ReportInput(UUID bookingId, Kind kind, UUID listingId, @NotNull ReportCategory category,
                              @NotBlank @Size(max = 1000) String description) {}

    @PutMapping("/{submissionId}")
    public Map<String, Object> submit(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID submissionId,
                                     @Valid @RequestBody ReportInput input) {
        return service.submit(user.id(), submissionId, input);
    }

    @GetMapping
    public List<Map<String, Object>> mine(@AuthenticationPrincipal AuthenticatedUser user) { return service.mine(user.id()); }
}
