import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/token_storage.dart';
import '../../features/auth/data/token_storage_provider.dart';
import '../errors/app_failure.dart';
import 'dio_client_provider.dart';

final authenticatedApiProvider = Provider<AuthenticatedApi>(
  (ref) => AuthenticatedApi(
    ref.watch(dioClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

class AuthenticatedApi {
  AuthenticatedApi(this._dio, this._tokens);
  final Dio _dio;
  final TokenStorage _tokens;
  Future<String?>? _refreshing;

  Future<String?> _refresh(int session) async {
    final token = await _tokens.readRefreshToken();
    if (token == null || _tokens.session != session) return null;
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': token},
    );
    final access = response.data!['accessToken'] as String;
    return await _tokens.rotate(
          session,
          accessToken: access,
          refreshToken: response.data!['refreshToken'] as String,
        )
        ? access
        : null;
  }

  Future<T?> request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Duration? timeout,
  }) async {
    final session = _tokens.session;
    final token = await _tokens.readAccessToken();
    void checkSession() {
      if (token == null || _tokens.session != session) {
        throw const UnauthorizedFailure(message: 'Sign-in required');
      }
    }

    checkSession();
    Future<T?> send(String access) async {
      checkSession();
      final response = await _dio.request<T>(
        path,
        data: data is FormData ? data.clone() : data,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          contentType: data is FormData
              ? Headers.multipartFormDataContentType
              : Headers.jsonContentType,
          headers: {'Authorization': 'Bearer $access'},
        ),
      );
      checkSession();
      return response.data;
    }

    try {
      return await send(token!);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _tokens.session != session) {
        rethrow;
      }
      var replacement = await _tokens.readAccessToken();
      if (replacement == token) {
        final operation = _refreshing ??= _refresh(session);
        try {
          replacement = await operation;
        } finally {
          if (identical(operation, _refreshing)) _refreshing = null;
        }
      }
      if (replacement == null || _tokens.session != session) rethrow;
      return send(replacement);
    }
  }
}
