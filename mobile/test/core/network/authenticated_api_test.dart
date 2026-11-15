import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage tokens;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'old-access',
      StorageKeys.refreshToken: 'old-refresh',
    });
    tokens = TokenStorage(const FlutterSecureStorage());
  });
  tearDown(() => tokens.dispose());

  test(
    'deduplicates refresh requests and rotates tokens without changing account',
    () async {
      final refreshing = Completer<void>();
      final release = Completer<void>();
      var refreshCount = 0;
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCount++;
          if (!refreshing.isCompleted) refreshing.complete();
          await release.future;
          return jsonResponse({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          });
        }
        if (options.headers['Authorization'] == 'Bearer old-access') {
          return jsonResponse({}, statusCode: 401);
        }
        expect(options.headers['Authorization'], 'Bearer new-access');
        return jsonResponse({'id': 'same-account'});
      });
      final api = AuthenticatedApi(dioWithAdapter(adapter), tokens);
      final requests = Future.wait([
        api.request<Map<String, dynamic>>('GET', '/me'),
        api.request<Map<String, dynamic>>('GET', '/me'),
      ]);
      await refreshing.future;
      await Future<void>.delayed(Duration.zero);
      release.complete();
      expect(
        (await requests).map((item) => item!['id']),
        everyElement('same-account'),
      );
      expect(refreshCount, 1);
      expect(tokens.session, 0);
      expect(await tokens.readRefreshToken(), 'new-refresh');
    },
  );

  for (final refreshStatus in [401, 403, 500]) {
    test(
      'handles refresh rejection $refreshStatus without losing transient sessions',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(
            {},
            statusCode: options.path == '/auth/refresh' ? refreshStatus : 401,
          ),
        );
        final api = AuthenticatedApi(dioWithAdapter(adapter), tokens);
        await expectLater(
          api.request<Object>('GET', '/me'),
          throwsA(isA<DioException>()),
        );
        expect(
          await tokens.readAccessToken(),
          refreshStatus == 500 ? 'old-access' : isNull,
        );
        expect(
          await tokens.readRefreshToken(),
          refreshStatus == 500 ? 'old-refresh' : isNull,
        );
      },
    );
  }

  test('clears rejected replacement credentials after one retry', () async {
    final adapter = FakeHttpAdapter(
      (options) async => options.path == '/auth/refresh'
          ? jsonResponse({
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            })
          : jsonResponse({}, statusCode: 401),
    );
    await expectLater(
      AuthenticatedApi(
        dioWithAdapter(adapter),
        tokens,
      ).request<Object>('GET', '/me'),
      throwsA(isA<DioException>()),
    );
    expect(await tokens.readAccessToken(), isNull);
    expect(
      adapter.requests.where((r) => r.path == '/auth/refresh'),
      hasLength(1),
    );
  });

  test(
    'a delayed refresh rejection cannot clear a newly signed-in account',
    () async {
      final refreshing = Completer<void>();
      final release = Completer<void>();
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshing.complete();
          await release.future;
        }
        return jsonResponse({}, statusCode: 401);
      });
      final request = AuthenticatedApi(
        dioWithAdapter(adapter),
        tokens,
      ).request<Object>('GET', '/me');
      final failed = expectLater(request, throwsA(isA<DioException>()));
      await refreshing.future;
      await tokens.saveTokens(
        accessToken: 'other-account',
        refreshToken: 'other-refresh',
      );
      release.complete();
      await failed;
      expect(await tokens.readAccessToken(), 'other-account');
      expect(tokens.signedIn, isTrue);
    },
  );
}
