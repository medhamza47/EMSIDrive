package ma.emsi.emsidrive.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;

/** Full profile of the authenticated user. */
@Schema(description = "Profile of the authenticated user")
public record UserProfileResponse(
        UUID id,
        String email,
        String fullName,
        String phoneNumber,
        String filiere,
        String academicYear,
        String photoUrl,
        UserRole role,
        boolean enabled,
        Instant createdAt,
        Instant updatedAt) {

    public static UserProfileResponse from(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getFiliere(),
                user.getAcademicYear(),
                user.getPhotoUrl(),
                user.getRole(),
                user.isEnabled(),
                user.getCreatedAt(),
                user.getUpdatedAt());
    }
}
