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
        String preferredCampus,
        String preferredVehicle,
        UserRole role,
        boolean enabled,
        Instant createdAt,
        Instant updatedAt,
        Double rating,
        long ratingCount) {

    public static UserProfileResponse from(User user) {
        return from(user, null, 0);
    }

    public static UserProfileResponse from(User user, Double rating, long ratingCount) {
        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getFiliere(),
                user.getAcademicYear(),
                user.getPhotoUrl(),
                user.getPreferredCampus(),
                user.getPreferredVehicle(),
                user.getRole(),
                user.isEnabled(),
                user.getCreatedAt(),
                user.getUpdatedAt(), rating, ratingCount);
    }
}
