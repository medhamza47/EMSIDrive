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
  const AuthRepository({required this._api, required this._tokenStorage});

  final AuthApi _api;
  final TokenStorage _tokenStorage;

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

  /// Creates a student account and stores the returned tokens.
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) {
    return _authenticate(
      () => _api.register(
        RegisterRequestDto(
          email: email,
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
        ),
      ),
    );
  }

  /// Removes the stored tokens.
  Future<void> signOut() => _tokenStorage.clear();

  /// Reads the stored access token, used to restore a session at startup.
  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  Future<AuthSession> _authenticate(Future<AuthResponseDto> Function() request) async {
    try {
      final domain = (await request()).toDomain();
      await _tokenStorage.saveTokens(
        accessToken: domain.accessToken,
        refreshToken: domain.refreshToken,
      );
      return domain;
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
