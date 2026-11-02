import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/storage_keys.dart';

/// Persists the token pair in platform secure storage.
///
/// Kept behind a class so tests can swap in an in-memory implementation without
/// touching the keystore plugin.
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  /// Reads the stored access token, `null` when the user is signed out.
  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  /// Reads the stored refresh token, `null` when the user is signed out.
  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  /// Stores both tokens atomically from the caller's point of view.
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  /// Removes both tokens, used when signing out or when a token is rejected.
  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
