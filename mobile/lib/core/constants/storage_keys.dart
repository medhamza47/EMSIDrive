/// Keys used to read and write secrets in secure storage.
abstract final class StorageKeys {
  static const String accessToken = 'emsidrive.access_token';
  static const String refreshToken = 'emsidrive.refresh_token';

  /// Phone linked for fingerprint login: identifier and secret given by the
  /// server, plus the account shown on the login screen. Survives sign-out.
  static const String biometricDeviceId = 'emsidrive.biometric_device_id';
  static const String biometricDeviceKey = 'emsidrive.biometric_device_key';
  static const String biometricEmail = 'emsidrive.biometric_email';
  static const String biometricName = 'emsidrive.biometric_name';

  /// Flag written by the first version of the fingerprint unlock. No longer
  /// read; deleted together with the link.
  static const String legacyBiometricEnabled = 'emsidrive.biometric_enabled';
}
