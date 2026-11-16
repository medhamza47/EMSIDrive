import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/dio_client_provider.dart';
import '../data/auth_api.dart';
import '../data/biometric_auth.dart';
import '../data/token_storage.dart';
import '../data/token_storage_provider.dart';
import '../domain/biometric_link.dart';

final biometricLinkServiceProvider = Provider<BiometricLinkService>(
  (ref) => BiometricLinkService(
    tokens: ref.watch(tokenStorageProvider),
    biometrics: ref.watch(biometricAuthProvider),
    api: AuthApi(ref.watch(dioClientProvider)),
    authenticated: ref.watch(authenticatedApiProvider),
  ),
);

/// The link stored on this phone; refreshed when it is created or removed.
final biometricLinkProvider = FutureProvider.autoDispose<BiometricLink?>(
  (ref) => ref.watch(tokenStorageProvider).readBiometricLink(),
);

/// Links this phone for fingerprint login, signs in with it, and unlinks it.
///
/// The fingerprint is checked on the phone only. A success releases the
/// device key, which the server exchanges for a session and a new key.
class BiometricLinkService {
  BiometricLinkService({
    required this._tokens,
    required this._biometrics,
    required this._api,
    required this._authenticated,
  });

  final TokenStorage _tokens;
  final BiometricAuth _biometrics;
  final AuthApi _api;
  final AuthenticatedApi _authenticated;

  /// Links the signed-in account after a fingerprint check. [prompt] holds the
  /// texts of the system prompt.
  Future<BiometricResult> link({required BiometricPromptTexts prompt}) async {
    final session = _tokens.session;
    final check = await _biometrics.authenticate(prompt);
    if (check != BiometricResult.success) return check;
    try {
      final profile = await _authenticated.request<Map<String, dynamic>>(
        'GET',
        '/me',
      );
      final device = await _authenticated.request<Map<String, dynamic>>(
        'POST',
        '/me/biometric-devices',
        data: {'deviceName': _deviceName},
      );
      final link = BiometricLink(
        deviceId: device?['deviceId'] as String? ?? '',
        deviceKey: device?['deviceKey'] as String? ?? '',
        email: profile?['email'] as String? ?? '',
        fullName: profile?['fullName'] as String? ?? '',
      );
      if (link.deviceId.isEmpty || link.deviceKey.isEmpty) {
        return BiometricResult.failed;
      }
      // Replace any previous link of this phone, on the server too.
      await unlink();
      final saved = await _tokens.saveBiometricLink(session, link);
      return saved ? BiometricResult.success : BiometricResult.cancelled;
    } catch (_) {
      return BiometricResult.networkError;
    }
  }

  /// Fingerprint, then server login with the device key. On success the new
  /// session is stored, which moves the router to the home tab.
  ///
  /// [beforeSession] runs between the server answer and the session switch,
  /// so the screen can show its success feedback first.
  Future<BiometricResult> signIn({
    required BiometricPromptTexts prompt,
    Future<void> Function()? beforeSession,
  }) async {
    final link = await _tokens.readBiometricLink();
    if (link == null) return BiometricResult.unlinked;
    final check = await _biometrics.authenticate(prompt);
    if (check != BiometricResult.success) return check;
    try {
      final result = await _api.biometricLogin(
        deviceId: link.deviceId,
        deviceKey: link.deviceKey,
      );
      // Keep the rotated key first: the previous one no longer works.
      await _tokens.rotateBiometricKey(link, result.deviceKey);
      await beforeSession?.call();
      await _tokens.saveTokens(
        accessToken: result.session.accessToken,
        refreshToken: result.session.refreshToken,
      );
      return BiometricResult.success;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokens.clearBiometricLink();
        return BiometricResult.unlinked;
      }
      return BiometricResult.networkError;
    } catch (_) {
      return BiometricResult.networkError;
    }
  }

  /// Unlinks this phone: revoked on the server when reachable, always
  /// forgotten locally.
  Future<void> unlink() async {
    final link = await _tokens.readBiometricLink();
    if (link == null) return;
    try {
      await _api.biometricRevoke(
        deviceId: link.deviceId,
        deviceKey: link.deviceKey,
      );
    } catch (_) {
      // The key is forgotten anyway; without it the link is unusable.
    }
    await _tokens.clearBiometricLink();
  }

  /// Forgets the link when a different account signs in with a password.
  Future<void> unlinkIfOtherAccount(String email) async {
    final link = await _tokens.readBiometricLink();
    if (link != null && link.email.toLowerCase() != email.toLowerCase()) {
      await unlink();
    }
  }

  static String get _deviceName => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iPhone',
    _ => defaultTargetPlatform.name,
  };
}
