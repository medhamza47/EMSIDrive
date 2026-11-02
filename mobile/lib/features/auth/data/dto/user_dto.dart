import '../../domain/auth_user.dart';

/// JSON view of a user account returned by the API.
///
/// Field names match the backend `UserResponse` record exactly.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.enabled,
    this.phoneNumber,
  });

  /// Parses a `UserResponse` payload. Missing optional fields default safely so
  /// a schema drift never crashes the app.
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.fromWireName(json['role'] as String? ?? UserRole.student.wireName),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final bool enabled;

  /// Converts the payload into the domain model consumed by the UI.
  AuthUser toDomain() {
    final phone = phoneNumber;
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName,
      phoneNumber: (phone == null || phone.isEmpty) ? null : phone,
      role: role,
      enabled: enabled,
    );
  }
}
