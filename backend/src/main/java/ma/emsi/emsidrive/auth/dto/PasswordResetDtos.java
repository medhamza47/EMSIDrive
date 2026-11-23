package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Payloads of the forgotten password flow. */
public final class PasswordResetDtos {

    private PasswordResetDtos() {
    }

    @Schema(description = "Asks for a reset code to be emailed")
    public record ForgotPasswordRequest(
            @Schema(example = "sara.elidrissi@emsi-edu.ma")
            @NotBlank(message = "Email is required")
            @Email(message = "Email must be a valid address")
            @Size(max = 180, message = "Email must not exceed 180 characters")
            String email) {
    }

    @Schema(description = "Sets a new password with the emailed code")
    public record ResetPasswordRequest(
            @Schema(example = "sara.elidrissi@emsi-edu.ma")
            @NotBlank(message = "Email is required")
            @Email(message = "Email must be a valid address")
            @Size(max = 180, message = "Email must not exceed 180 characters")
            String email,

            @Schema(description = "6-digit code received by email", example = "482913")
            @NotBlank(message = "Code is required")
            @Pattern(regexp = "^[0-9]{6}$", message = "Code must contain 6 digits")
            String code,

            @Schema(description = "New password, same rules as registration", example = "NewStrongPass123!")
            @NotBlank(message = "Password is required")
            @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
            String newPassword) {
    }
}
