import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'app_failure.dart';

/// Translates [DioException]s and raw [Error]s into [AppFailure] instances.
///
/// Keeping this mapping in one place guarantees every screen receives the same
/// failure taxonomy regardless of the endpoint it calls.
abstract final class ErrorMapper {
  /// Converts [error] into an [AppFailure].
  ///
  /// [fallbackMessage] is used when the server did not provide a usable message
  /// (offline device, malformed payload, unknown state).
  static AppFailure map(Object error, {String? fallbackMessage}) {
    if (error is AppFailure) {
      return error;
    }
    if (error is! DioException) {
      return UnexpectedFailure(message: fallbackMessage ?? 'Unexpected error.');
    }

    final response = error.response;
    final apiError = _parseApiError(response?.data);
    final message = apiError?.message ?? fallbackMessage ?? _defaultMessage(error);

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => TimeoutFailure(message: message),
      DioExceptionType.connectionError => NetworkFailure(message: message),
      DioExceptionType.badCertificate => NetworkFailure(message: message),
      DioExceptionType.cancel => UnexpectedFailure(message: message),
      DioExceptionType.badResponse =>
        response?.statusCode == 401
            ? UnauthorizedFailure(message: message, code: apiError?.code)
            : ApiFailure(
                message: message,
                code: apiError?.code,
                statusCode: response?.statusCode,
                fieldErrors: apiError?.fieldErrors ?? const <FieldError>[],
              ),
      DioExceptionType.unknown => error.error is NetworkFailure
          ? error.error! as NetworkFailure
          : NetworkFailure(message: message),
    };
  }

  static _ApiErrorPayload? _parseApiError(Object? data) {
    if (data is! Map) {
      return null;
    }
    final message = data['message'];
    if (message is! String) {
      return null;
    }
    final details = data['details'];
    final fieldErrors = <FieldError>[];
    if (details is List) {
      for (final detail in details) {
        if (detail is Map && detail['field'] is String && detail['message'] is String) {
          fieldErrors.add(
            FieldError(
              field: detail['field'] as String,
              message: detail['message'] as String,
            ),
          );
        }
      }
    }
    return _ApiErrorPayload(
      message: message,
      code: data['code'] is String ? data['code'] as String : null,
      fieldErrors: List<FieldError>.unmodifiable(fieldErrors),
    );
  }

  static String _defaultMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'The request timed out.',
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => 'Unable to reach the server.',
      _ => error.message ?? 'Unexpected error.',
    };
  }
}

/// Internal shape of the backend `ApiError` record.
class _ApiErrorPayload {
  const _ApiErrorPayload({
    required this.message,
    required this.code,
    required this.fieldErrors,
  });

  final String message;
  final String? code;
  final List<FieldError> fieldErrors;
}

/// Convenience helpers to detect validation failures.
extension ApiFailureX on AppFailure {
  /// Whether this failure is a field level validation error.
  bool get isValidationError =>
      this is ApiFailure &&
      code == AppConstants.validationErrorCode &&
      (this as ApiFailure).fieldErrors.isNotEmpty;

  /// Validation errors keyed by field name, ready for `TextFormField` wiring.
  Map<String, String> get fieldErrorsByField {
    final self = this;
    if (self is! ApiFailure) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final error in self.fieldErrors) error.field: error.message,
    };
  }
}
