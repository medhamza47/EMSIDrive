import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';

part 'dio_client_provider.g.dart';

/// Provides the configured [Dio] instance used by every repository.
///
/// The client only knows about transport concerns: base URL, timeouts, JSON
/// headers and logging. Authentication and refresh handling are added later
/// through [Dio.interceptors] so features stay independent.
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConstants.apiBaseUrl}${AppConstants.apiVersionPath}',
      connectTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const <String, Object>{'Accept': Headers.jsonContentType},
    ),
  );

  ref.onDispose(dio.close);

  return dio;
}
