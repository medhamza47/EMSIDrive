import 'package:dio/dio.dart';

import 'dto/auth_requests.dart';
import 'dto/auth_response_dto.dart';

/// Thin HTTP client for the `/auth` endpoints.
///
/// Returns parsed DTOs and lets [Dio] throw, so error normalization stays the
/// responsibility of the repository.
class AuthApi {
  const AuthApi(this._dio);

  static const String _loginPath = '/auth/login';
  static const String _registerPath = '/auth/register';

  final Dio _dio;

  /// `POST /auth/login` — 200 on success.
  Future<AuthResponseDto> login(LoginRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _loginPath,
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  /// `POST /auth/logout` — 204. Revokes the refresh token on the server.
  ///
  /// Short timeouts: signing out must stay quick even on a bad network, the
  /// local tokens are removed whatever happens here.
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  /// `POST /auth/biometric/login` — 200 with a new session and the rotated
  /// device key, 401 `INVALID_DEVICE_KEY` when the phone is no longer linked.
  Future<({AuthResponseDto session, String deviceKey})> biometricLogin({
    required String deviceId,
    required String deviceKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/biometric/login',
      data: {'deviceId': deviceId, 'deviceKey': deviceKey},
    );
    final body = response.data ?? const <String, dynamic>{};
    return (
      session: AuthResponseDto.fromJson(
        body['session'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      deviceKey: body['deviceKey'] as String? ?? '',
    );
  }

  /// `POST /auth/biometric/revoke` — 204. Unlinks the phone.
  Future<void> biometricRevoke({
    required String deviceId,
    required String deviceKey,
  }) async {
    await _dio.post<void>(
      '/auth/biometric/revoke',
      data: {'deviceId': deviceId, 'deviceKey': deviceKey},
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  /// `POST /auth/password/forgot` — always 202, whether or not the email
  /// belongs to an account, so the answer never reveals who is registered.
  Future<void> requestPasswordReset(String email) async {
    await _dio.post<void>(
      '/auth/password/forgot',
      data: {'email': email.trim()},
    );
  }

  /// `POST /auth/password/reset` — 204 on success, 400 `INVALID_RESET_CODE`
  /// when the code is wrong, expired, already used or locked.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/password/reset',
      data: {'email': email.trim(), 'code': code.trim(), 'newPassword': newPassword},
    );
  }

  /// `POST /auth/register/code` — 202 once the form is valid and a 6-digit
  /// code is on its way to the email. Same errors as `register` for the form.
  Future<void> requestRegistrationCode(RegisterRequestDto request) async {
    await _dio.post<void>('/auth/register/code', data: request.toJson());
  }

  /// `POST /auth/register` — 201 on success.
  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _registerPath,
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? const <String, dynamic>{});
  }
}
