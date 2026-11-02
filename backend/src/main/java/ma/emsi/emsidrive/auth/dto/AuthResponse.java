package ma.emsi.emsidrive.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Access and refresh token pair returned by every successful authentication call.
 *
 * @param accessToken  short lived token to send as {@code Authorization: Bearer}
 * @param refreshToken long lived token used only on {@code /auth/refresh}
 * @param tokenType    always {@code Bearer}
 * @param expiresIn    access token lifetime in seconds
 * @param user         authenticated account
 */
@Schema(description = "Authentication result")
public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresIn,
        UserResponse user) {

    public static AuthResponse bearer(String accessToken, String refreshToken, long expiresIn, UserResponse user) {
        return new AuthResponse(accessToken, refreshToken, "Bearer", expiresIn, user);
    }
}
