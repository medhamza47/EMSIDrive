import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/biometric_auth.dart';
import '../data/session_id_provider.dart';
import '../data/token_storage.dart';
import '../data/token_storage_provider.dart';

/// What the profile switch needs to know about the biometric unlock.
class BiometricSettings {
  const BiometricSettings({required this.available, required this.enabled});

  /// The device has a sensor with at least one enrolled biometric.
  final bool available;

  /// The stored session is unlocked with a biometric check at startup.
  final bool enabled;
}

/// Turns the biometric unlock on after a successful check, or off directly.
///
/// Enabling requires the user to pass the prompt once, which proves the sensor
/// works and that the person holding the phone owns the enrolled biometric.
Future<BiometricResult> setBiometricUnlock(
  TokenStorage tokens,
  BiometricAuth biometrics, {
  required bool enabled,
  required String reason,
}) async {
  final session = tokens.session;
  if (enabled) {
    final result = await biometrics.authenticate(reason);
    if (result != BiometricResult.success) return result;
  }
  final saved = await tokens.setBiometricEnabled(session, enabled);
  return saved ? BiometricResult.success : BiometricResult.cancelled;
}

final biometricSettingsProvider =
    AsyncNotifierProvider.autoDispose<
      BiometricSettingsController,
      BiometricSettings
    >(BiometricSettingsController.new);

class BiometricSettingsController extends AsyncNotifier<BiometricSettings> {
  @override
  Future<BiometricSettings> build() async {
    // Re-read when the account changes.
    ref.watch(sessionIdProvider);
    final tokens = ref.watch(tokenStorageProvider);
    final biometrics = ref.watch(biometricAuthProvider);
    return BiometricSettings(
      available: await biometrics.isAvailable(),
      enabled: await tokens.readBiometricEnabled(),
    );
  }

  Future<BiometricResult> setEnabled(
    bool enabled, {
    required String reason,
  }) async {
    final result = await setBiometricUnlock(
      ref.read(tokenStorageProvider),
      ref.read(biometricAuthProvider),
      enabled: enabled,
      reason: reason,
    );
    if (ref.mounted && result == BiometricResult.success) {
      state = AsyncData(
        BiometricSettings(
          available: state.value?.available ?? true,
          enabled: enabled,
        ),
      );
    }
    return result;
  }
}

/// `true` right after a password login or a registration, until the app has
/// offered to turn the biometric unlock on.
final biometricOfferProvider = NotifierProvider<BiometricOfferController, bool>(
  BiometricOfferController.new,
);

class BiometricOfferController extends Notifier<bool> {
  @override
  bool build() {
    // A pending offer belongs to the account that just signed in.
    ref.watch(sessionIdProvider);
    return false;
  }

  void request() => state = true;

  /// Returns whether an offer was pending, and clears it.
  bool consume() {
    final pending = state;
    state = false;
    return pending;
  }
}
