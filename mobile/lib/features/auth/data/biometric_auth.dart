import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

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

  /// The server no longer accepts this phone: the link was revoked.
  unlinked,

  /// The fingerprint passed but the server could not be reached.
  networkError,
}

/// Texts of the system biometric prompt, which the app cannot otherwise style.
class BiometricPromptTexts {
  const BiometricPromptTexts({
    required this.reason,
    required this.title,
    required this.cancel,
    this.hint,
  });

  /// Subtitle under the title (Android), "Verify identity" by default.
  final String? hint;

  /// Why the app asks; shown under the title.
  final String reason;

  /// Prompt title (Android); defaults to the app name otherwise.
  final String title;

  /// Label of the button that closes the prompt.
  final String cancel;
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

  /// Shows the system biometric prompt with the texts of [prompt].
  ///
  /// The prompt itself is drawn by the OS; only its texts can be set.
  /// Biometrics only: the device PIN is not offered, the app's own password
  /// login is the way out.
  Future<BiometricResult> authenticate(BiometricPromptTexts prompt) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: prompt.reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: prompt.title,
            signInHint: prompt.hint,
            cancelButton: prompt.cancel,
          ),
          IOSAuthMessages(cancelButton: prompt.cancel),
        ],
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
