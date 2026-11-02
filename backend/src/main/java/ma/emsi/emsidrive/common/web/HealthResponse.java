package ma.emsi.emsidrive.common.web;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

@Schema(description = "Service health snapshot")
public record HealthResponse(
        @Schema(example = "UP") String status,
        @Schema(example = "emsidrive-api") String application,
        Instant timestamp) {

    public static HealthResponse up(String application) {
        return new HealthResponse("UP", application, Instant.now());
    }
}
