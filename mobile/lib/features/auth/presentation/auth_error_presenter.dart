import '../../../core/constants/auth_error_codes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../l10n/app_localizations.dart';

/// Turns an [AppFailure] into French copy ready for the screen.
///
/// Known backend codes get a localized message so the UI never shows an English
/// server string. `VALIDATION_ERROR` is handled field by field through
/// [fieldErrors].
class AuthErrorPresenter {
  const AuthErrorPresenter(this._l10n);

  final AppLocalizations _l10n;

  /// Message shown in the inline error banner, `null` when there is nothing to
  /// display (for example a pure validation error already shown under fields).
  String? bannerMessage(AppFailure failure) {
    if (failure.isValidationError) {
      return null;
    }
    return switch (failure.code) {
      AuthErrorCodes.invalidCredentials => _l10n.invalidCredentialsErrorMessage,
      AuthErrorCodes.emailDomainNotAllowed => _l10n.emailDomainNotAllowedErrorMessage,
      AuthErrorCodes.emailAlreadyUsed => _l10n.emailAlreadyUsedErrorMessage,
      AuthErrorCodes.accountDisabled => _l10n.accountDisabledErrorMessage,
      _ => switch (failure) {
        NetworkFailure() => _l10n.networkErrorMessage,
        TimeoutFailure() => _l10n.timeoutErrorMessage,
        _ => failure.message.isEmpty ? _l10n.genericErrorMessage : failure.message,
      },
    };
  }

  /// Per-field messages keyed by the backend field name, used as `errorText`
  /// on the matching [AppTextField].
  Map<String, String> fieldErrors(AppFailure failure) => failure.fieldErrorsByField;
}
