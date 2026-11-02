package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;

@Schema(description = "Public representation of a user account")
public record UserResponse(
        UUID id,
        String email,
        String fullName,
        String phoneNumber,
        UserRole role,
        boolean enabled) {

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getRole(),
                user.isEnabled());
    }
}
