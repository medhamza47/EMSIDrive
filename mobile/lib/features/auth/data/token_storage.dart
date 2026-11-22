import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/biometric_link.dart';

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

  Future<bool> readPushEnabled() async =>
      await _storage.read(key: 'emsidrive.push_enabled') == 'true';

  Future<void> writePushEnabled(bool enabled) =>
      _storage.write(key: 'emsidrive.push_enabled', value: '$enabled');

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

  /// The fingerprint link of this phone, or `null` when it is not linked.
  Future<BiometricLink?> readBiometricLink() async {
    await _writes;
    final id = await _storage.read(key: StorageKeys.biometricDeviceId);
    final key = await _storage.read(key: StorageKeys.biometricDeviceKey);
    if (id == null || id.isEmpty || key == null || key.isEmpty) return null;
    return BiometricLink(
      deviceId: id,
      deviceKey: key,
      email: await _storage.read(key: StorageKeys.biometricEmail) ?? '',
      fullName: await _storage.read(key: StorageKeys.biometricName) ?? '',
    );
  }

  /// Whether a stored session must be unlocked with a fingerprint.
  Future<bool> readBiometricEnabled() async =>
      await readBiometricLink() != null;

  /// Stores [link], unless the account changed since [expectedSession].
  Future<bool> saveBiometricLink(
    int expectedSession,
    BiometricLink link,
  ) async {
    var saved = false;
    await _serialize(() async {
      if (expectedSession != _session) return;
      await _writeLink(link);
      saved = expectedSession == _session;
    });
    return saved;
  }

  /// Replaces the device key after the server rotated it.
  Future<void> rotateBiometricKey(BiometricLink link, String key) =>
      _serialize(() => _writeLink(link.withKey(key)));

  /// Forgets the fingerprint link of this phone.
  Future<void> clearBiometricLink() => _serialize(() async {
    for (final key in const [
      StorageKeys.biometricDeviceId,
      StorageKeys.biometricDeviceKey,
      StorageKeys.biometricEmail,
      StorageKeys.biometricName,
      StorageKeys.legacyBiometricEnabled,
    ]) {
      await _storage.delete(key: key);
    }
  });

  Future<void> _writeLink(BiometricLink link) async {
    await _storage.write(
      key: StorageKeys.biometricDeviceId,
      value: link.deviceId,
    );
    await _storage.write(
      key: StorageKeys.biometricDeviceKey,
      value: link.deviceKey,
    );
    await _storage.write(key: StorageKeys.biometricEmail, value: link.email);
    await _storage.write(key: StorageKeys.biometricName, value: link.fullName);
  }

  /// Removes both tokens, used when signing out or when a token is rejected.
  ///
  /// The fingerprint link is kept on purpose: it lets the student sign back in
  /// with a fingerprint after a sign-out.
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
