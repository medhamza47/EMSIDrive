package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Login request")
public record LoginRequest(

        @Schema(description = "Registered email address", example = "sara.elidrissi@emsi-edu.ma")
        @NotBlank(message = "Email is required")
        @Email(message = "Email must be a valid address")
        String email,

        @Schema(description = "Account password", example = "StrongPass123!")
        @NotBlank(message = "Password is required")
        String password) {
}
