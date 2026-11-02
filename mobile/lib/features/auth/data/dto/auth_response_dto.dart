import '../../domain/auth_session.dart';
import 'user_dto.dart';

/// JSON view of the backend `AuthResponse` record.
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserDto user;

  /// Converts the payload into the domain session stored by the app.
  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      user: user.toDomain(),
    );
  }
}
