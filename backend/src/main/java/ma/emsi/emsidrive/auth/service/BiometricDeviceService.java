package ma.emsi.emsidrive.auth.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;
import ma.emsi.emsidrive.auth.dto.AuthResponse;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.EnrollResponse;
import ma.emsi.emsidrive.auth.dto.BiometricDtos.LoginResponse;
import ma.emsi.emsidrive.auth.entity.BiometricDevice;
import ma.emsi.emsidrive.auth.repository.BiometricDeviceRepository;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Fingerprint login with a per-phone device key.
 *
 * <p>The fingerprint itself never leaves the phone. After a successful local check the
 * phone presents its device key; the server answers with a new session and a new key.
 * Presenting a key that was already rotated means it was copied, so the device is
 * revoked and the student must sign in with the password again.
 */
@Service
public class BiometricDeviceService {

    private static final int KEY_BYTES = 32;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final BiometricDeviceRepository deviceRepository;
    private final UserRepository userRepository;
    private final AuthService authService;

    public BiometricDeviceService(
            BiometricDeviceRepository deviceRepository,
            UserRepository userRepository,
            AuthService authService) {
        this.deviceRepository = deviceRepository;
        this.userRepository = userRepository;
        this.authService = authService;
    }

    @Transactional
    public EnrollResponse enroll(UUID userId, String deviceName) {
        User user = userRepository.findForAuthentication(userId)
                .filter(User::isEnabled)
                .orElseThrow(() -> ApiException.unauthorized("ACCOUNT_UNAVAILABLE", "Account is not available"));
        String key = newKey();
        BiometricDevice device = deviceRepository.save(BiometricDevice.builder()
                .user(user)
                .keyHash(TokenHasher.sha256Hex(key))
                .deviceName(trimToNull(deviceName))
                .build());
        return new EnrollResponse(device.getId(), key);
    }

    @Transactional(noRollbackFor = ApiException.class)
    public LoginResponse login(UUID deviceId, String deviceKey) {
        // Lock the account before the device, matching moderation's lock order.
        UUID owner = deviceRepository.findOwner(deviceId)
                .orElseThrow(BiometricDeviceService::invalidDevice);
        User user = userRepository.findForAuthentication(owner)
                .orElseThrow(BiometricDeviceService::invalidDevice);
        BiometricDevice device = deviceRepository.findForUpdate(deviceId)
                .filter(BiometricDevice::isActive)
                .orElseThrow(BiometricDeviceService::invalidDevice);

        if (!matches(device, deviceKey)) {
            // A rotated key came back: someone kept a copy. Cut the link for everyone.
            device.setRevokedAt(Instant.now());
            deviceRepository.save(device);
            throw invalidDevice();
        }
        if (!user.isEnabled()) {
            throw ApiException.forbidden("ACCOUNT_DISABLED", "This account is disabled");
        }

        String nextKey = newKey();
        device.setKeyHash(TokenHasher.sha256Hex(nextKey));
        device.setLastUsedAt(Instant.now());
        deviceRepository.save(device);

        AuthResponse session = authService.issueTokens(user);
        return new LoginResponse(session, nextKey);
    }

    /** Unlinks the phone. Silent when the credentials are unknown, to reveal nothing. */
    @Transactional
    public void revoke(UUID deviceId, String deviceKey) {
        deviceRepository.findForUpdate(deviceId)
                .filter(BiometricDevice::isActive)
                .filter(device -> matches(device, deviceKey))
                .ifPresent(device -> {
                    device.setRevokedAt(Instant.now());
                    deviceRepository.save(device);
                });
    }

    private static boolean matches(BiometricDevice device, String deviceKey) {
        return MessageDigest.isEqual(
                device.getKeyHash().getBytes(StandardCharsets.US_ASCII),
                TokenHasher.sha256Hex(deviceKey).getBytes(StandardCharsets.US_ASCII));
    }

    private static String newKey() {
        byte[] bytes = new byte[KEY_BYTES];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static ApiException invalidDevice() {
        return ApiException.unauthorized("INVALID_DEVICE_KEY", "This phone is no longer linked for fingerprint login");
    }
}
