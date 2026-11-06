package ma.emsi.emsidrive.user.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.user.dto.UpdateProfileRequest;
import ma.emsi.emsidrive.user.dto.UserProfileResponse;
import ma.emsi.emsidrive.user.service.UserProfileService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me")
@Tag(name = "Profile", description = "Profile of the authenticated student")
public class UserProfileController {

    private final UserProfileService userProfileService;

    public UserProfileController(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    @GetMapping
    @Operation(summary = "Get the authenticated user profile")
    public UserProfileResponse getProfile(@AuthenticationPrincipal AuthenticatedUser principal) {
        return userProfileService.getProfile(principal.id());
    }

    @PutMapping
    @Operation(summary = "Update the authenticated user profile")
    public UserProfileResponse updateProfile(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @Valid @RequestBody UpdateProfileRequest request) {
        return userProfileService.updateProfile(principal.id(), request);
    }
}
