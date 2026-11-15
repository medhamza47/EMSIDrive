import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../data/biometric_auth.dart';
import '../data/token_storage.dart';
import '../data/token_storage_provider.dart';

/// `locked`: a session is stored but the biometric unlock is enabled and has
/// not been passed yet in this run of the app.
enum SessionStatus { restoring, locked, signedIn, signedOut, unavailable }

final sessionControllerProvider = Provider<SessionController>((ref) {
  final controller = SessionController(
    ref.watch(tokenStorageProvider),
    ref.watch(authenticatedApiProvider),
    ref.watch(biometricAuthProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Validates stored credentials with the API before opening private screens.
class SessionController extends ChangeNotifier {
  SessionController(this._tokens, this._api, this._biometrics) {
    _tokens.addListener(_tokensChanged);
    unawaited(restore());
  }

  final TokenStorage _tokens;
  final AuthenticatedApi _api;
  final BiometricAuth _biometrics;
  SessionStatus _status = SessionStatus.restoring;
  SessionStatus get status => _status;
  bool _restoring = false;
  bool _unlocking = false;
  bool _disposed = false;

  /// Set once the biometric check passed, or when the user typed the password
  /// in this run, so the lock is not shown again until the app restarts.
  bool _unlocked = false;

  void _setStatus(SessionStatus value) {
    if (_disposed || _status == value) return;
    _status = value;
    notifyListeners();
  }

  void _tokensChanged() {
    if (_tokens.signedIn case final signedIn?) {
      // A password login is proof enough: no fingerprint right after it.
      _unlocked = signedIn;
      _setStatus(signedIn ? SessionStatus.signedIn : SessionStatus.signedOut);
    }
  }

  Future<void> restore() async {
    if (_restoring || _disposed) return;
    _restoring = true;
    final session = _tokens.session;
    _setStatus(SessionStatus.restoring);
    try {
      final access = await _tokens.readAccessToken();
      final refresh = await _tokens.readRefreshToken();
      if (_disposed || _tokens.session != session) return;
      if (access == null && refresh == null) {
        _setStatus(SessionStatus.signedOut);
        return;
      }
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        await _tokens.invalidate(session);
        return;
      }
      // Lock before any network call, so the check also applies offline.
      if (!_unlocked && await _tokens.readBiometricEnabled()) {
        if (_tokens.session == session) _setStatus(SessionStatus.locked);
        return;
      }
      await _api.request<Map<String, dynamic>>('GET', '/me');
      if (_tokens.session == session) _setStatus(SessionStatus.signedIn);
    } catch (_) {
      if (_tokens.session == session || _status == SessionStatus.restoring) {
        _setStatus(SessionStatus.unavailable);
      }
    } finally {
      _restoring = false;
    }
  }

  /// Shows the biometric prompt and, on success, continues the restore.
  ///
  /// [reason] is the localized text displayed by the system prompt.
  Future<BiometricResult> unlock(String reason) async {
    if (_status != SessionStatus.locked || _unlocking) {
      return BiometricResult.cancelled;
    }
    _unlocking = true;
    final session = _tokens.session;
    try {
      final result = await _biometrics.authenticate(reason);
      if (_disposed || _tokens.session != session) {
        return BiometricResult.cancelled;
      }
      if (result == BiometricResult.success) {
        _unlocked = true;
        await restore();
      }
      return result;
    } finally {
      _unlocking = false;
    }
  }

  Future<void> signOut() => _tokens.clear();

  @override
  void dispose() {
    _disposed = true;
    _tokens.removeListener(_tokensChanged);
    super.dispose();
  }
}
