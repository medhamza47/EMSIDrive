package ma.emsi.emsidrive.common.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
@Tag(name = "Health", description = "Service availability checks")
public class HealthController {

    private final String applicationName;

    public HealthController(@Value("${spring.application.name:emsidrive-api}") String applicationName) {
        this.applicationName = applicationName;
    }

    @GetMapping
    @Operation(summary = "Report service liveness")
    public HealthResponse health() {
        return HealthResponse.up(applicationName);
    }
}
