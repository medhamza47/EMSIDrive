package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Registration payload. The email domain must belong to an allowed student domain.
 */
@Schema(description = "Student registration request")
public record RegisterRequest(

        @Schema(description = "Student email address", example = "sara.elidrissi@emsi-edu.ma")
        @NotBlank(message = "Email is required")
        @Email(message = "Email must be a valid address")
        @Size(max = 180, message = "Email must not exceed 180 characters")
        String email,

        @Schema(description = "Password, at least 8 characters", example = "StrongPass123!")
        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
        String password,

        @Schema(description = "Full name", example = "Sara El Idrissi")
        @NotBlank(message = "Full name is required")
        @Size(max = 120, message = "Full name must not exceed 120 characters")
        String fullName,

        @Schema(description = "Moroccan phone number", example = "+212612345678")
        @Pattern(regexp = "^$|^\\+?[0-9]{9,20}$", message = "Phone number must contain between 9 and 20 digits")
        String phoneNumber) {
}
