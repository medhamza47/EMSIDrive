import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/storage_keys.dart';

/// Persists the token pair in platform secure storage.
///
/// Kept behind a class so tests can swap in an in-memory implementation without
/// touching the keystore plugin.
class TokenStorage extends ChangeNotifier {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  Future<void> _writes = Future<void>.value();
  int _session = 0;
  int get session => _session;
  bool? _signedIn;
  bool? get signedIn => _signedIn;

  /// Reads the stored access token, `null` when the user is signed out.
  Future<String?> readAccessToken() async {
    await _writes;
    return _storage.read(key: StorageKeys.accessToken);
  }

  /// Reads the stored refresh token, `null` when the user is signed out.
  Future<String?> readRefreshToken() async {
    await _writes;
    return _storage.read(key: StorageKeys.refreshToken);
  }

  /// Stores both tokens atomically from the caller's point of view.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final session = ++_session;
    await _serialize(() async {
      if (session == _session) await _writeTokens(accessToken, refreshToken);
    });
    if (session != _session) return;
    _signedIn = true;
    notifyListeners();
  }

  Future<bool> rotate(
    int session, {
    required String accessToken,
    required String refreshToken,
  }) async {
    var saved = false;
    await _serialize(() async {
      if (session != _session) return;
      await _writeTokens(accessToken, refreshToken);
      saved = session == _session;
    });
    return saved;
  }

  Future<void> _serialize(Future<void> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _writeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  /// Removes both tokens, used when signing out or when a token is rejected.
  Future<void> clear() async {
    final session = ++_session;
    _signedIn = false;
    await _serialize(() async {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
    });
    if (session == _session) notifyListeners();
  }

  /// A rejected response from an older account must not sign out the new one.
  Future<void> invalidate(int expectedSession) {
    if (_session != expectedSession) return Future<void>.value();
    return clear();
  }

  @override
  void dispose() {
    _session++;
    super.dispose();
  }
}
