/// Normalized failure surfaced to the presentation layer.
///
/// Mirrors the backend `ApiError` contract so screens can display the server
/// `message` (already localized server side) without leaking transport types.
sealed class AppFailure {
  const AppFailure({required this.message, this.code, this.statusCode});

  /// Human readable message safe to display to the user.
  final String message;

  /// Machine readable code, `ApiError.code` when coming from the API.
  final String? code;

  /// HTTP status, when the failure originated from an HTTP response.
  final int? statusCode;

  @override
  String toString() => '$runtimeType(code: $code, statusCode: $statusCode, message: $message)';
}

/// The API could not be reached at all (DNS, timeout, connection refused).
final class NetworkFailure extends AppFailure {
  const NetworkFailure({required super.message});
}

/// The API answered with a non 2xx status.
final class ApiFailure extends AppFailure {
  const ApiFailure({
    required super.message,
    super.code,
    super.statusCode,
    this.fieldErrors = const <FieldError>[],
  });

  /// Per-field validation errors, populated when [code] is a validation error.
  final List<FieldError> fieldErrors;
}

/// A request timed out.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({required super.message});
}

/// The request was rejected because the caller is not authenticated.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({required super.message, super.code});
}

/// An unexpected, non-HTTP failure.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({required super.message});
}

/// Single validation message attached to a request field.
class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FieldError && other.field == field && other.message == message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => 'FieldError($field: $message)';
}
