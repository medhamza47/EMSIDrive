/// Environment agnostic constants shared across the app.
abstract final class AppConstants {
  /// Base URL of the EMSIDrive API.
  ///
  /// Points at the local backend by default. Override at build time with
  /// `flutter run --dart-define=API_BASE_URL=https://api.emsidrive.ma`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// API version segment prefixed to every versioned endpoint.
  static const String apiVersionPath = '/api/v1';

  /// Timeout applied to connect, send and receive phases.
  static const Duration apiTimeout = Duration(seconds: 20);

  /// Machine readable error code returned by the backend for validation
  /// failures. Matches `ApiError.code`.
  static const String validationErrorCode = 'VALIDATION_ERROR';
}
