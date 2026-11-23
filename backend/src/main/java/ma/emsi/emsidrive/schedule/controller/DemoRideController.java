package ma.emsi.emsidrive.schedule.controller;

import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.schedule.service.DemoRideService;
import org.springframework.context.annotation.Profile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@Profile("dev")
@RequestMapping("/api/v1/schedules/demo-rides")
public class DemoRideController {
    private final DemoRideService service;
    public DemoRideController(DemoRideService service) { this.service = service; }
    @PostMapping
    public List<UUID> seed(@AuthenticationPrincipal AuthenticatedUser user) { return service.seed(user.id()); }
}
