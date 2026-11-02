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

  /// `POST /auth/register` — 201 on success.
  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _registerPath,
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? const <String, dynamic>{});
  }
}
