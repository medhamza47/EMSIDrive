package ma.emsi.emsidrive.ride.marketplace;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/marketplace")
public class RideMarketplaceController {
    private final RideMarketplace service;

    public RideMarketplaceController(RideMarketplace service) {
        this.service = service;
    }

    public enum Kind { REQUEST, OFFER }
    public enum Campus { CENTRE, TARGA }
    public enum Vehicle { MOTO, CAR, ANY }

    public record ListingInput(
            @NotNull Kind kind, @NotNull Campus campus, @NotNull Boolean toCampus,
            @NotNull @Valid Point point, @NotNull @Future OffsetDateTime departure,
            @Min(1) @Max(4) int seats, @NotNull Vehicle vehicle, @Size(max = 500) String notes) {}

    public record Point(
            @NotNull @DecimalMin("-90") @DecimalMax("90") java.math.BigDecimal latitude,
            @NotNull @DecimalMin("-180") @DecimalMax("180") java.math.BigDecimal longitude) {}

    public record MessageInput(@NotBlank @Size(max = 1000) String body) {}

    @GetMapping("/listings")
    public List<Map<String, Object>> listings(
            @AuthenticationPrincipal AuthenticatedUser user, @RequestParam Kind kind) {
        return service.listings(user.id(), kind);
    }

    @PostMapping("/listings")
    public Map<String, UUID> publish(
            @AuthenticationPrincipal AuthenticatedUser user, @Valid @RequestBody ListingInput input) {
        return Map.of("id", service.publish(user.id(), input));
    }

    @GetMapping("/listings/{kind}/{id}")
    public Map<String, Object> listing(@AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable Kind kind, @PathVariable UUID id) {
        return service.listing(user.id(), kind, id);
    }

    @PostMapping("/listings/{kind}/{id}/accept")
    public Map<String, UUID> accept(@AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable Kind kind, @PathVariable UUID id) {
        return Map.of("id", service.accept(user.id(), kind, id));
    }

    @GetMapping("/trips")
    public List<Map<String, Object>> trips(@AuthenticationPrincipal AuthenticatedUser user) {
        return service.trips(user.id());
    }

    @GetMapping("/trips/{id}")
    public Map<String, Object> trip(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        return service.trip(user.id(), id);
    }

    @GetMapping("/trips/{id}/messages")
    public List<Map<String, Object>> messages(@AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable UUID id, @RequestParam(defaultValue = "0") long after) {
        return service.messages(user.id(), id, after);
    }

    @PostMapping("/trips/{id}/messages")
    public void message(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id,
            @Valid @RequestBody MessageInput message) {
        service.send(user.id(), id, message.body());
    }

    @PutMapping("/trips/{id}/location")
    public void location(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id,
            @Valid @RequestBody Point point) {
        service.location(user.id(), id, point);
    }

    @DeleteMapping("/trips/{id}/location")
    public void stopLocation(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        service.location(user.id(), id, null);
    }

    @GetMapping("/notifications")
    public List<Map<String, Object>> notifications(@AuthenticationPrincipal AuthenticatedUser user) {
        return service.notifications(user.id());
    }

    @PutMapping("/notifications/{id}/read")
    public void read(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        service.read(user.id(), id);
    }
}
