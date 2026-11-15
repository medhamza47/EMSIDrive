import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../data/auth_repository.dart';
import '../data/auth_repository_provider.dart';
import '../data/token_storage.dart';
import '../data/token_storage_provider.dart';

enum SessionStatus { restoring, signedIn, signedOut, unavailable }

final sessionControllerProvider = Provider<SessionController>((ref) {
  final controller = SessionController(
    ref.watch(tokenStorageProvider),
    ref.watch(authenticatedApiProvider),
    ref.watch(authRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Validates stored credentials with the API before opening private screens.
///
/// An open session reopens straight on the home tab; the fingerprint is only
/// used to sign back in after a sign-out, from the login screen.
class SessionController extends ChangeNotifier {
  SessionController(this._tokens, this._api, this._auth) {
    _tokens.addListener(_tokensChanged);
    unawaited(restore());
  }

  final TokenStorage _tokens;
  final AuthenticatedApi _api;
  final AuthRepository _auth;
  SessionStatus _status = SessionStatus.restoring;
  SessionStatus get status => _status;
  bool _restoring = false;
  bool _disposed = false;

  /// Whether a session was open at some point in this run of the app.
  bool get wasSignedIn => _wasSignedIn;
  bool _wasSignedIn = false;

  void _setStatus(SessionStatus value) {
    if (_disposed || _status == value) return;
    _status = value;
    if (value == SessionStatus.signedIn) _wasSignedIn = true;
    notifyListeners();
  }

  void _tokensChanged() {
    if (_tokens.signedIn case final signedIn?) {
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

  /// Ends the session on the server when reachable, then locally. The
  /// fingerprint link is kept.
  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _disposed = true;
    _tokens.removeListener(_tokensChanged);
    super.dispose();
  }
}
