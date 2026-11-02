import '../../../l10n/app_localizations.dart';
import '../data/dto/auth_requests.dart';

/// Client side form validators.
///
/// Each rule mirrors a backend bean validation constraint so a payload the app
/// accepts is very likely accepted server side too. The server remains the
/// authority: its `details[]` entries always win when present.
class AuthValidators {
  const AuthValidators(this._l10n);

  final AppLocalizations _l10n;

  /// Student email domain enforced by default, matching
  /// `app.security.student-email-domains`.
  static const String defaultStudentEmailDomain = 'emsi-edu.ma';

  /// Matches the backend `RegisterRequest.phoneNumber` pattern.
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{9,20}$');

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Validates the email field of both forms.
  String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return _l10n.validationEmailRequired;
    }
    if (!_emailPattern.hasMatch(email)) {
      return _l10n.validationEmailInvalid;
    }
    if (!_isAllowedDomain(email)) {
      return _l10n.validationEmailDomain(defaultStudentEmailDomain);
    }
    return null;
  }

  /// Validates the login password: only presence matters, the server decides.
  String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return _l10n.validationPasswordRequired;
    }
    return null;
  }

  /// Validates the registration password against the backend bounds.
  String? registerPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return _l10n.validationPasswordRequired;
    }
    if (password.length < RegisterRequestDto.passwordMinLength) {
      return _l10n.validationPasswordTooShort(RegisterRequestDto.passwordMinLength);
    }
    if (password.length > RegisterRequestDto.passwordMaxLength) {
      return _l10n.validationPasswordTooLong(RegisterRequestDto.passwordMaxLength);
    }
    return null;
  }

  /// Validates the full name field.
  String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return _l10n.validationFullNameRequired;
    }
    if (name.length > RegisterRequestDto.fullNameMaxLength) {
      return _l10n.validationFullNameTooLong(RegisterRequestDto.fullNameMaxLength);
    }
    return null;
  }

  /// Validates the optional phone number; an empty value is always accepted.
  String? phoneNumber(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return null;
    }
    if (!_phonePattern.hasMatch(phone)) {
      return _l10n.validationPhoneNumberInvalid;
    }
    return null;
  }

  bool _isAllowedDomain(String email) {
    final domain = email.split('@').last.toLowerCase();
    return domain == defaultStudentEmailDomain;
  }
}
