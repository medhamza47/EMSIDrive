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

  /// `POST /auth/register` — 201 on success.
  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _registerPath,
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? const <String, dynamic>{});
  }
}
