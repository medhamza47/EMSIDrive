package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** Requests and responses of the fingerprint login flow. */
public final class BiometricDtos {

    private BiometricDtos() {
    }

    @Schema(description = "Links the calling phone for fingerprint login")
    public record EnrollRequest(
            @Schema(description = "Label shown to the student, e.g. the phone model")
            @Size(max = 120, message = "Device name must be at most 120 characters")
            String deviceName) {
    }

    /**
     * @param deviceId  identifier to send back on every fingerprint login
     * @param deviceKey secret returned once; the phone keeps it behind its biometric check
     */
    @Schema(description = "Credentials of a newly linked phone")
    public record EnrollResponse(UUID deviceId, String deviceKey) {
    }

    @Schema(description = "Device credentials presented after a successful fingerprint check")
    public record DeviceKeyRequest(
            @NotNull(message = "Device id is required")
            UUID deviceId,

            @NotBlank(message = "Device key is required")
            @Size(max = 128, message = "Device key is too long")
            String deviceKey) {
    }

    /**
     * @param session   new token pair, as returned by a password login
     * @param deviceKey replacement key; the presented key no longer works
     */
    @Schema(description = "Fingerprint login result")
    public record LoginResponse(AuthResponse session, String deviceKey) {
    }
}
