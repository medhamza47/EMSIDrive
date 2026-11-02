import 'auth_user.dart';

/// Access and refresh tokens paired with the account they belong to.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  /// Bearer token sent with authenticated requests.
  final String accessToken;

  /// Token used to mint a new access token.
  final String refreshToken;

  /// Access token lifetime, in seconds.
  final int expiresIn;

  /// Account owning the tokens.
  final AuthUser user;

  /// Absolute expiry of [accessToken], computed from now.
  DateTime get accessTokenExpiry => DateTime.now().add(Duration(seconds: expiresIn));

  @override
  String toString() => 'AuthSession(${user.email}, expiresIn: ${expiresIn}s)';
}
