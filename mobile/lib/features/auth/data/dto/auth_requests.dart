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

  Map<String, dynamic> toJson() {
    final phone = phoneNumber?.trim();
    return <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
      if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
    };
  }
}
