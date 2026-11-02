import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/errors/error_mapper.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_api.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/domain/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_api.dart';
import '../../helpers/fake_http_adapter.dart';

void main() {
  late FlutterSecureStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = const FlutterSecureStorage();
  });

  Future<String?> stored(String key) => storage.read(key: key);

  group('AuthRepository with the real HTTP stack', () {
    test('login posts the credentials as a JSON body', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(authResponseJson()),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await repository.login(email: '  yassine.elamrani@emsi-edu.ma  ', password: 'secret123');

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/auth/login');
      expect(request.data, <String, dynamic>{
        'email': 'yassine.elamrani@emsi-edu.ma',
        'password': 'secret123',
      });
    });

    test('login persists both tokens and returns the mapped session', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(authResponseJson()),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      final AuthSession session = await repository.login(
        email: 'yassine.elamrani@emsi-edu.ma',
        password: 'secret123',
      );

      expect(session.accessToken, sampleAccessToken);
      expect(session.refreshToken, sampleRefreshToken);
      expect(session.expiresIn, 900);
      expect(session.user, sampleStudent);
      expect(await stored(StorageKeys.accessToken), sampleAccessToken);
      expect(await stored(StorageKeys.refreshToken), sampleRefreshToken);
    });

    test('register posts the trimmed optional phone number when provided', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(authResponseJson(), statusCode: 201),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await repository.register(
        email: 'yassine.elamrani@emsi-edu.ma',
        password: 'secret123',
        fullName: ' Yassine El Amrani ',
        phoneNumber: ' +212612345678 ',
      );

      final request = adapter.requests.single;
      expect(request.path, '/auth/register');
      expect(request.data, <String, dynamic>{
        'email': 'yassine.elamrani@emsi-edu.ma',
        'password': 'secret123',
        'fullName': 'Yassine El Amrani',
        'phoneNumber': '+212612345678',
      });
    });

    test('register omits the phone number when it is blank', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(authResponseJson(), statusCode: 201),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await repository.register(
        email: 'yassine.elamrani@emsi-edu.ma',
        password: 'secret123',
        fullName: 'Yassine El Amrani',
        phoneNumber: '   ',
      );

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body.containsKey('phoneNumber'), isFalse);
    });

    test('maps a 401 INVALID_CREDENTIALS to UnauthorizedFailure and stores nothing', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(
          apiErrorJson(
            status: 401,
            code: 'INVALID_CREDENTIALS',
            message: 'Email ou mot de passe incorrect.',
          ),
          statusCode: 401,
        ),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await expectLater(
        repository.login(email: 'yassine.elamrani@emsi-edu.ma', password: 'wrong-one'),
        throwsA(
          isA<UnauthorizedFailure>()
              .having((UnauthorizedFailure failure) => failure.code, 'code', 'INVALID_CREDENTIALS')
              .having(
                (UnauthorizedFailure failure) => failure.message,
                'message',
                contains('incorrect'),
              ),
        ),
      );
      expect(await stored(StorageKeys.accessToken), isNull);
      expect(await stored(StorageKeys.refreshToken), isNull);
    });

    test('maps a VALIDATION_ERROR to field errors keyed by field name', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(
          apiErrorJson(
            status: 400,
            code: 'VALIDATION_ERROR',
            message: 'Request validation failed',
            details: <Map<String, String>>[
              <String, String>{'field': 'email', 'message': 'must be a well-formed email address'},
              <String, String>{'field': 'password', 'message': 'size must be between 8 and 72'},
            ],
          ),
          statusCode: 400,
        ),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await expectLater(
        repository.register(
          email: 'not-an-email',
          password: 'short',
          fullName: 'Yassine El Amrani',
        ),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure failure) => failure.code, 'code', 'VALIDATION_ERROR')
              .having((ApiFailure failure) => failure.isValidationError, 'isValidationError', isTrue)
              .having(
                (ApiFailure failure) => failure.fieldErrorsByField,
                'fieldErrorsByField',
                <String, String>{
                  'email': 'must be a well-formed email address',
                  'password': 'size must be between 8 and 72',
                },
              ),
        ),
      );
    });

    test('maps a 409 EMAIL_ALREADY_USED to an ApiFailure carrying the code', () async {
      final adapter = FakeHttpAdapter(
        (RequestOptions options) async => jsonResponse(
          apiErrorJson(
            status: 409,
            code: 'EMAIL_ALREADY_USED',
            message: 'Email already used.',
          ),
          statusCode: 409,
        ),
      );
      final repository = AuthRepository(
        api: AuthApi(dioWithAdapter(adapter)),
        tokenStorage: TokenStorage(storage),
      );

      await expectLater(
        repository.register(
          email: 'yassine.elamrani@emsi-edu.ma',
          password: 'secret123',
          fullName: 'Yassine El Amrani',
        ),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure failure) => failure.code, 'code', 'EMAIL_ALREADY_USED')
              .having((ApiFailure failure) => failure.statusCode, 'statusCode', 409)
              .having((ApiFailure failure) => failure.isValidationError, 'isValidationError', isFalse),
        ),
      );
    });
  });

  group('AuthRepository failure handling', () {
    test('rethrows an AppFailure produced by the API layer unchanged', () async {
      const failure = NetworkFailure(message: 'offline');
      final repository = AuthRepository(
        api: FakeAuthApi(error: failure),
        tokenStorage: TokenStorage(storage),
      );

      await expectLater(
        repository.login(email: 'yassine.elamrani@emsi-edu.ma', password: 'secret123'),
        throwsA(same(failure)),
      );
    });

    test('normalizes a non HTTP error into UnexpectedFailure', () async {
      final repository = AuthRepository(
        api: FakeAuthApi(error: const FormatException('bad payload')),
        tokenStorage: TokenStorage(storage),
      );

      await expectLater(
        repository.login(email: 'yassine.elamrani@emsi-edu.ma', password: 'secret123'),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('signOut clears both stored tokens', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        StorageKeys.accessToken: sampleAccessToken,
        StorageKeys.refreshToken: sampleRefreshToken,
      });
      final repository = AuthRepository(
        api: FakeAuthApi(),
        tokenStorage: TokenStorage(const FlutterSecureStorage()),
      );

      expect(await repository.readAccessToken(), sampleAccessToken);

      await repository.signOut();

      expect(await repository.readAccessToken(), isNull);
      expect(await const FlutterSecureStorage().read(key: StorageKeys.refreshToken), isNull);
    });
  });
}
