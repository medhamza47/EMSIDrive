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
import ma.emsi.emsidrive.auth.service.AuthService;
import ma.emsi.emsidrive.auth.service.BiometricDeviceService;
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

    public AuthController(AuthService authService, BiometricDeviceService biometricDeviceService) {
        this.authService = authService;
        this.biometricDeviceService = biometricDeviceService;
    }

    @PostMapping("/register")
    @Operation(summary = "Register a new student account")
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
}
