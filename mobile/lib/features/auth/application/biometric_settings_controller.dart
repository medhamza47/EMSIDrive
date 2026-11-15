import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/biometric_auth.dart';
import '../data/session_id_provider.dart';
import '../data/token_storage_provider.dart';
import 'biometric_link_service.dart';

/// What the profile switch needs to know about fingerprint login.
class BiometricSettings {
  const BiometricSettings({required this.available, required this.enabled});

  /// The device has a sensor with at least one enrolled biometric.
  final bool available;

  /// This phone is linked: fingerprint login and startup unlock are on.
  final bool enabled;
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

  /// Links this phone after a fingerprint check, or unlinks it.
  Future<BiometricResult> setEnabled(
    bool enabled, {
    required BiometricPromptTexts prompt,
  }) async {
    final service = ref.read(biometricLinkServiceProvider);
    final BiometricResult result;
    if (enabled) {
      result = await service.link(prompt: prompt);
    } else {
      await service.unlink();
      result = BiometricResult.success;
    }
    ref.invalidate(biometricLinkProvider);
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

/// Email of the account that just signed in with a password or registered,
/// until the app has offered to turn fingerprint login on; `null` otherwise.
final biometricOfferProvider =
    NotifierProvider<BiometricOfferController, String?>(
      BiometricOfferController.new,
    );

class BiometricOfferController extends Notifier<String?> {
  @override
  String? build() {
    // A pending offer belongs to the account that just signed in.
    ref.watch(sessionIdProvider);
    return null;
  }

  void request(String email) => state = email;

  /// Returns the pending account email, and clears the offer.
  String? consume() {
    final pending = state;
    state = null;
    return pending;
  }
}
