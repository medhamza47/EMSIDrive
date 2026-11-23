package ma.emsi.emsidrive.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import ma.emsi.emsidrive.auth.dto.AuthResponse;
import ma.emsi.emsidrive.auth.dto.LoginRequest;
import ma.emsi.emsidrive.auth.dto.RefreshTokenRequest;
import ma.emsi.emsidrive.auth.dto.RegisterRequest;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.DeviceKeyRequest;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.LoginResponse;
import ma.emsi.emsidrive.auth.dto.PasswordResetDtos.ForgotPasswordRequest;
import ma.emsi.emsidrive.auth.dto.PasswordResetDtos.ResetPasswordRequest;
import ma.emsi.emsidrive.auth.service.AuthService;
import ma.emsi.emsidrive.auth.service.BiometricDeviceService;
import ma.emsi.emsidrive.auth.service.PasswordResetService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Student registration, login and token refresh")
public class AuthController {

    private final AuthService authService;
    private final BiometricDeviceService biometricDeviceService;
    private final PasswordResetService passwordResetService;

    public AuthController(
            AuthService authService,
            BiometricDeviceService biometricDeviceService,
            PasswordResetService passwordResetService) {
        this.authService = authService;
        this.biometricDeviceService = biometricDeviceService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/register/code")
    @Operation(summary = "Check the registration form and email a 6-digit code to the address",
            description = "202 when the code is sent, or when the previous one was sent less than a minute ago")
    public ResponseEntity<Void> registrationCode(@Valid @RequestBody RegisterRequest request) {
        authService.requestRegistrationCode(request);
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/register")
    @Operation(summary = "Register a new student account with the emailed verification code")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    @Operation(summary = "Authenticate with email and password")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Exchange a refresh token for a new token pair")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    @Operation(summary = "Revoke a refresh token so its session ends on the server")
    public ResponseEntity<Void> logout(@Valid @RequestBody RefreshTokenRequest request) {
        authService.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/biometric/login")
    @Operation(summary = "Sign in with a linked phone after a local fingerprint check")
    public ResponseEntity<LoginResponse> biometricLogin(@Valid @RequestBody DeviceKeyRequest request) {
        return ResponseEntity.ok(biometricDeviceService.login(request.deviceId(), request.deviceKey()));
    }

    @PostMapping("/biometric/revoke")
    @Operation(summary = "Unlink a phone from fingerprint login")
    public ResponseEntity<Void> biometricRevoke(@Valid @RequestBody DeviceKeyRequest request) {
        biometricDeviceService.revoke(request.deviceId(), request.deviceKey());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/password/forgot")
    @Operation(summary = "Email a password reset code",
            description = "Always 202, whether or not the email belongs to an account")
    public ResponseEntity<Void> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.requestReset(request.email());
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/password/reset")
    @Operation(summary = "Set a new password with the emailed code and end every session")
    public ResponseEntity<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.email(), request.code(), request.newPassword());
        return ResponseEntity.noContent().build();
    }
}
