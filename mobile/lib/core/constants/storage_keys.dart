/// Keys used to read and write secrets in secure storage.
abstract final class StorageKeys {
  static const String accessToken = 'emsidrive.access_token';
  static const String refreshToken = 'emsidrive.refresh_token';

  /// `'true'` when the stored session must be unlocked with a biometric check.
  static const String biometricEnabled = 'emsidrive.biometric_enabled';
}
