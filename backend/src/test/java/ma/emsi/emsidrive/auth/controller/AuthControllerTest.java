package ma.emsi.emsidrive.auth.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.AuthResponse;
import ma.emsi.emsidrive.auth.dto.LoginRequest;
import ma.emsi.emsidrive.auth.dto.RefreshTokenRequest;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.dto.UserResponse;
import ma.emsi.emsidrive.auth.security.JwtAuthenticationFilter;
import ma.emsi.emsidrive.auth.security.JwtService;
import ma.emsi.emsidrive.auth.security.RestAuthenticationEntryPoint;
import ma.emsi.emsidrive.auth.service.AuthService;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.config.SecurityConfig;
import ma.emsi.emsidrive.user.entity.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, JwtService.class, JwtAuthenticationFilter.class, RestAuthenticationEntryPoint.class})
class AuthControllerTest {

    private static final UUID USER_ID = UUID.fromString("3f1c8a54-6c1e-4a4f-9d2b-1f0f2f5c7a11");
    private static final String EMAIL = "sara.elidrissi@emsi-edu.ma";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private AuthService authService;

    private static AuthResponse sampleAuthResponse() {
        return AuthResponse.bearer(
                "access-token",
                "refresh-token",
                900,
                new UserResponse(USER_ID, EMAIL, "Sara El Idrissi", "+212612345678", UserRole.STUDENT, true));
    }

    @Test
    void registerReturns201WithTokenPair() throws Exception {
        when(authService.register(any(RegisterRequest.class))).thenReturn(sampleAuthResponse());

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RegisterRequest(EMAIL, "StrongPass123!", "Sara El Idrissi", "+212612345678"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").value("access-token"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-token"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andExpect(jsonPath("$.user.email").value(EMAIL))
                .andExpect(jsonPath("$.user.role").value("STUDENT"));
    }

    @Test
    void registerRejectsInvalidPayloadWithFieldDetails() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RegisterRequest("not-an-email", "short", "", null))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details.length()").value(3));
    }

    @Test
    void registerMapsDomainRestrictionTo400() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(ApiException.badRequest("EMAIL_DOMAIN_NOT_ALLOWED", "Restricted domain"));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new RegisterRequest("sara@gmail.com", "StrongPass123!", "Sara", null))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("EMAIL_DOMAIN_NOT_ALLOWED"));
    }

    @Test
    void loginReturns200WithTokenPair() throws Exception {
        when(authService.login(any(LoginRequest.class))).thenReturn(sampleAuthResponse());

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest(EMAIL, "StrongPass123!"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("access-token"))
                .andExpect(jsonPath("$.user.id").value(USER_ID.toString()));
    }

    @Test
    void loginMapsInvalidCredentialsTo401() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid email or password"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest(EMAIL, "wrong-password"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    void refreshReturns200WithRotatedPair() throws Exception {
        when(authService.refresh("refresh-token")).thenReturn(sampleAuthResponse());

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest("refresh-token"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").value("refresh-token"));
    }

    @Test
    void refreshRejectsBlankToken() throws Exception {
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest("  "))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details[0].field").value("refreshToken"));
    }

    @Test
    void refreshMapsInvalidTokenTo401() throws Exception {
        when(authService.refresh("stale-token"))
                .thenThrow(ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token is expired or revoked"));

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest("stale-token"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_REFRESH_TOKEN"));
    }
}
