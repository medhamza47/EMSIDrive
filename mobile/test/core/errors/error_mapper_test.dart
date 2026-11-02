import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions options(String path) => RequestOptions(path: path);

  DioException httpError(
    String path,
    int statusCode,
    Map<String, dynamic>? data, {
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    return DioException(
      requestOptions: options(path),
      type: type,
      response: Response<Map<String, dynamic>>(
        requestOptions: options(path),
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  group('ErrorMapper', () {
    test('maps every timeout flavour to TimeoutFailure', () {
      const timeouts = <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];

      for (final type in timeouts) {
        expect(
          ErrorMapper.map(DioException(requestOptions: options('/health'), type: type)),
          isA<TimeoutFailure>(),
          reason: '$type should map to TimeoutFailure',
        );
      }
    });

    test('maps connection errors to NetworkFailure', () {
      final failure = ErrorMapper.map(
        DioException(
          requestOptions: options('/health'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('parses the backend ApiError payload including field details', () {
      final failure = ErrorMapper.map(
        httpError('/api/v1/auth/register', 400, <String, dynamic>{
          'timestamp': '2024-01-01T10:00:00Z',
          'status': 400,
          'code': 'VALIDATION_ERROR',
          'message': 'Requête invalide',
          'details': <Map<String, String>>[
            <String, String>{'field': 'email', 'message': 'Domaine non autorisé'},
          ],
        }),
      );

      expect(failure, isA<ApiFailure>());
      final apiFailure = failure as ApiFailure;
      expect(apiFailure.message, 'Requête invalide');
      expect(apiFailure.code, 'VALIDATION_ERROR');
      expect(apiFailure.statusCode, 400);
      expect(apiFailure.isValidationError, isTrue);
      expect(apiFailure.fieldErrors, hasLength(1));
      expect(apiFailure.fieldErrorsByField, <String, String>{
        'email': 'Domaine non autorisé',
      });
    });

    test('maps 401 responses to UnauthorizedFailure', () {
      final failure = ErrorMapper.map(
        httpError('/api/v1/auth/refresh', 401, <String, dynamic>{
          'message': 'Refresh token invalide',
        }),
      );

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Refresh token invalide');
    });

    test('keeps the fallback message when the payload has none', () {
      final failure = ErrorMapper.map(
        httpError('/api/v1/rides', 500, null),
        fallbackMessage: 'Une erreur est survenue.',
      );

      expect(failure, isA<ApiFailure>());
      expect(failure.message, 'Une erreur est survenue.');
      expect(failure.statusCode, 500);
    });

    test('a payload without validation details is not a validation error', () {
      final failure = ErrorMapper.map(
        httpError('/api/v1/rides', 409, <String, dynamic>{'message': 'Trajet complet'}),
      );

      expect(failure.isValidationError, isFalse);
      expect(failure.fieldErrorsByField, isEmpty);
    });

    test('returns AppFailure instances untouched', () {
      const original = NetworkFailure(message: 'Hors ligne');

      expect(ErrorMapper.map(original), same(original));
    });

    test('wraps unknown errors into UnexpectedFailure', () {
      final failure = ErrorMapper.map(StateError('boom'), fallbackMessage: 'Erreur');

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'Erreur');
    });
  });
}
