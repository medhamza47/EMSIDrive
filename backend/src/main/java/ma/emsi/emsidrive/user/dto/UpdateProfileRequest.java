package ma.emsi.emsidrive.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Editable part of a profile. The email and role are owned by the auth module and
 * cannot be changed here.
 */
@Schema(description = "Profile update request")
public record UpdateProfileRequest(

        @Schema(description = "Full name", example = "Sara El Idrissi")
        @NotBlank(message = "Full name is required")
        @Size(max = 120, message = "Full name must not exceed 120 characters")
        String fullName,

        @Schema(description = "Moroccan phone number", example = "+212612345678")
        @Size(max = 20)
        @Pattern(regexp = "^$|^\\+?[0-9]{9,20}$", message = "Phone number must contain between 9 and 20 digits")
        String phoneNumber,

        @Schema(description = "Study program", example = "2DSI")
        @Size(max = 60, message = "Filiere must not exceed 60 characters")
        String filiere,

        @Schema(description = "Academic year label", example = "2025-2026")
        @Size(max = 20, message = "Academic year must not exceed 20 characters")
        String academicYear,

        @Schema(description = "Absolute URL of the profile picture", example = "https://cdn.emsidrive.ma/me.jpg")
        @Size(max = 500, message = "Photo URL must not exceed 500 characters")
        @Pattern(regexp = "^$|^https?://.+$", message = "Photo URL must be a valid http(s) URL")
        String photoUrl,

        @Pattern(regexp = "^$|^(CENTRE|TARGA)$") String preferredCampus,
        @Pattern(regexp = "^$|^(MOTO|CAR|ANY)$") String preferredVehicle) {

    public UpdateProfileRequest(String fullName, String phoneNumber, String filiere, String academicYear, String photoUrl) {
        this(fullName, phoneNumber, filiere, academicYear, photoUrl, null, null);
    }
}
