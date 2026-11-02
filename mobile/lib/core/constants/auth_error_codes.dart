/// Machine readable error codes returned by the authentication endpoints.
///
/// Mirrors `ma.emsi.emsidrive.common.exception` and `AuthService` on the
/// backend so the presentation layer can translate them without string
/// matching on messages.
abstract final class AuthErrorCodes {
  static const String validationError = 'VALIDATION_ERROR';
  static const String emailDomainNotAllowed = 'EMAIL_DOMAIN_NOT_ALLOWED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String emailAlreadyUsed = 'EMAIL_ALREADY_USED';
  static const String accountDisabled = 'ACCOUNT_DISABLED';
}
