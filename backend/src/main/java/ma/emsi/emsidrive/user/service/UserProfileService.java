package ma.emsi.emsidrive.user.service;

import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.dto.UpdateProfileRequest;
import ma.emsi.emsidrive.user.dto.UserProfileResponse;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads and updates the profile of the authenticated user. Every operation is scoped
 * to the account id taken from the access token, so a user can only ever read or
 * modify their own profile.
 */
@Service
public class UserProfileService {

    private final UserRepository userRepository;

    public UserProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        return UserProfileResponse.from(requireUser(userId));
    }

    @Transactional
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = requireUser(userId);

        user.setFullName(request.fullName().trim());
        user.setPhoneNumber(normalize(request.phoneNumber()));
        user.setFiliere(normalize(request.filiere()));
        user.setAcademicYear(normalize(request.academicYear()));
        user.setPhotoUrl(normalize(request.photoUrl()));

        return UserProfileResponse.from(userRepository.saveAndFlush(user));
    }

    private User requireUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "User account no longer exists"));
    }

    private static String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
