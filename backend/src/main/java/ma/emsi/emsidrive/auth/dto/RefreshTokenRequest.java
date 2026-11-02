package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Refresh token exchange request")
public record RefreshTokenRequest(

        @Schema(description = "Refresh token issued by login or by a previous refresh")
        @NotBlank(message = "Refresh token is required")
        String refreshToken) {
}
