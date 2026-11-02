/// Role attached to an authenticated account.
///
/// Mirrors the backend `Role` enum. Only two roles exist for now.
enum UserRole {
  student('STUDENT'),
  admin('ADMIN');

  const UserRole(this.wireName);

  /// Value exchanged with the API.
  final String wireName;

  /// Parses [value], falling back to [UserRole.student] for unknown input.
  static UserRole fromWireName(String value) {
    for (final role in UserRole.values) {
      if (role.wireName == value) {
        return role;
      }
    }
    return UserRole.student;
  }
}

/// Account returned by the authentication endpoints.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.enabled,
  });

  /// Server side identifier (UUID as a string).
  final String id;

  final String email;
  final String fullName;

  /// Optional, empty when the student did not provide one.
  final String? phoneNumber;

  final UserRole role;

  /// Whether the account may sign in.
  final bool enabled;

  bool get isAdmin => role == UserRole.admin;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.fullName == fullName &&
      other.phoneNumber == phoneNumber &&
      other.role == role &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, email, fullName, phoneNumber, role, enabled);

  @override
  String toString() => 'AuthUser($email, ${role.wireName})';
}
