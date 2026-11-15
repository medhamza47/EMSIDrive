package ma.emsi.emsidrive.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.EnrollRequest;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.EnrollResponse;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.auth.service.BiometricDeviceService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Linking a phone requires an authenticated session; logging in with it does not. */
@RestController
@RequestMapping("/api/v1/me/biometric-devices")
@Tag(name = "Fingerprint login", description = "Phones linked for fingerprint login")
public class BiometricDeviceController {

    private final BiometricDeviceService deviceService;

    public BiometricDeviceController(BiometricDeviceService deviceService) {
        this.deviceService = deviceService;
    }

    @PostMapping
    @Operation(summary = "Link the calling phone for fingerprint login")
    public ResponseEntity<EnrollResponse> enroll(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @Valid @RequestBody(required = false) EnrollRequest request) {
        String name = request == null ? null : request.deviceName();
        return ResponseEntity.status(HttpStatus.CREATED).body(deviceService.enroll(principal.id(), name));
    }
}
