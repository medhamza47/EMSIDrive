import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/auth_session.dart';
import 'auth_api.dart';
import 'dto/auth_requests.dart';
import 'dto/auth_response_dto.dart';
import 'token_storage.dart';

/// Coordinates the authentication use cases.
///
/// Talks to [AuthApi], persists the token pair through [TokenStorage] and
/// normalizes every transport failure into an [AppFailure] so callers only deal
/// with one error taxonomy.
class AuthRepository {
  const AuthRepository({
    required this._api,
    required this._tokenStorage,
    this.beforeSignOut,
  });

  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final Future<void> Function()? beforeSignOut;

  /// Authenticates a student and stores the returned tokens.
  ///
  /// Throws an [AppFailure] when the credentials are rejected or the request
  /// cannot complete. `INVALID_CREDENTIALS` arrives as an [UnauthorizedFailure]
  /// carrying the backend code.
  Future<AuthSession> login({required String email, required String password}) {
    return _authenticate(
      () => _api.login(LoginRequestDto(email: email, password: password)),
    );
  }

  /// Checks the registration form on the server and emails a code proving
  /// the address exists. No account is created yet.
  Future<void> requestRegistrationCode(RegisterRequestDto form) =>
      _guard(() => _api.requestRegistrationCode(form));

  /// Creates a student account and stores the returned tokens.
  ///
  /// [verificationCode] is the code emailed by [requestRegistrationCode].
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? verificationCode,
  }) {
    return _authenticate(
      () => _api.register(
        RegisterRequestDto(
          email: email,
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
          verificationCode: verificationCode,
        ),
      ),
    );
  }

  /// Asks the server to email a password reset code to [email].
  ///
  /// Succeeds for any well formed address: the server never says whether an
  /// account exists. Throws an [AppFailure] when the request cannot complete.
  Future<void> requestPasswordReset(String email) =>
      _guard(() => _api.requestPasswordReset(email));

  /// Sets [newPassword] with the emailed [code].
  ///
  /// The server then ends every session of the account, fingerprint links
  /// included, so the student signs in again with the new password.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _guard(
    () => _api.resetPassword(email: email, code: code, newPassword: newPassword),
  );

  /// Ends the session on the server, then removes the stored tokens.
  ///
  /// The server call is best effort: offline, the phone still signs out and
  /// the refresh token simply expires on its own.
  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } catch (_) {
      // Local logout still completes when push registration is unavailable.
    }
    try {
      final refresh = await _tokenStorage.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) await _api.logout(refresh);
    } catch (_) {
      // Signing out locally must never be blocked by the network.
    }
    await _tokenStorage.clear();
  }

  /// Reads the stored access token, used to restore a session at startup.
  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  Future<void> _guard(Future<void> Function() request) async {
    try {
      await request();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AuthSession> _authenticate(
    Future<AuthResponseDto> Function() request,
  ) async {
    try {
      final previousSession = _tokenStorage.session;
      final domain = (await request()).toDomain();
      if (_tokenStorage.session != previousSession) {
        throw const UnauthorizedFailure(message: 'Session changed');
      }
      await _tokenStorage.saveTokens(
        accessToken: domain.accessToken,
        refreshToken: domain.refreshToken,
      );
      if (_tokenStorage.session != previousSession + 1 ||
          _tokenStorage.signedIn != true) {
        throw const UnauthorizedFailure(message: 'Session changed');
      }
      return domain;
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
