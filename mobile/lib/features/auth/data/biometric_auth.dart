import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Outcome of a biometric check, mapped from the platform errors.
enum BiometricResult {
  success,

  /// The user dismissed the prompt or the system interrupted it.
  cancelled,

  /// Too many failed attempts; the sensor is temporarily or fully locked.
  lockedOut,

  /// No sensor, no enrolled fingerprint, or the prompt cannot be shown.
  unavailable,

  /// Any other failure.
  failed,
}

final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => BiometricAuth(LocalAuthentication()),
);

/// Thin wrapper around `local_auth` so screens and tests never touch the
/// plugin directly.
///
/// The check happens on the device only: no biometric data ever reaches the
/// API. A successful check simply unlocks the session already stored in
/// secure storage.
class BiometricAuth {
  const BiometricAuth(this._auth);

  final LocalAuthentication _auth;

  /// Whether the device has a sensor with at least one enrolled biometric.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system biometric prompt with [reason].
  ///
  /// Biometrics only: the device PIN is not offered, the app's own password
  /// login is the fallback.
  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => BiometricResult.cancelled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.uiUnavailable => BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } catch (_) {
      return BiometricResult.failed;
    }
  }
}
