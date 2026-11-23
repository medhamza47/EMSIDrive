/// JSON body sent to `POST /auth/login`.
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email.trim(),
    'password': password,
  };
}

/// JSON body sent to `POST /auth/register`.
///
/// Constraints mirror the backend `RegisterRequest` bean validation so the
/// server never receives a payload it would reject for a fixable reason.
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
    this.verificationCode,
  });

  /// Maximum accepted by `RegisterRequest.fullName`.
  static const int fullNameMaxLength = 120;

  /// Maximum accepted by `RegisterRequest.password` (BCrypt input cap).
  static const int passwordMaxLength = 72;

  /// Minimum accepted by `RegisterRequest.password`.
  static const int passwordMinLength = 8;

  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;

  /// Code emailed by `POST /auth/register/code`; absent when asking for it.
  final String? verificationCode;

  /// Same form carrying the emailed [code].
  RegisterRequestDto withCode(String code) => RegisterRequestDto(
    email: email,
    password: password,
    fullName: fullName,
    phoneNumber: phoneNumber,
    verificationCode: code,
  );

  Map<String, dynamic> toJson() {
    final phone = phoneNumber?.trim();
    return <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
      if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
      if (verificationCode case final code?) 'verificationCode': code.trim(),
    };
  }
}
