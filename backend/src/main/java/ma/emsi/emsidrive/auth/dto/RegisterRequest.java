package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Registration payload. The email domain must belong to an allowed student domain, and
 * the account is only created with the code emailed to that address.
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
        String phoneNumber,

        @Schema(description = "6-digit code emailed by POST /auth/register/code; required to create the account",
                example = "482913")
        @Pattern(regexp = "^[0-9]{6}$", message = "Code must contain 6 digits")
        String verificationCode) {

    /** Form without code, as sent to request the verification code. */
    public RegisterRequest(String email, String password, String fullName, String phoneNumber) {
        this(email, password, fullName, phoneNumber, null);
    }
}
