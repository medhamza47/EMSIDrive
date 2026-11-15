import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/app.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage_provider.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/session_screen.dart';
import 'package:emsidrive_mobile/features/home/presentation/home_screen.dart';
import 'package:emsidrive_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fake_auth_api.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

ResponseBody profileOrEmpty(RequestOptions options) => options.path == '/me'
    ? jsonResponse(authResponseJson()['user'] as Map<String, dynamic>)
    : ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

Future<void> pumpSessionApp(
  WidgetTester tester,
  FakeHttpAdapter adapter, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [dioClientProvider.overrideWithValue(dioWithAdapter(adapter))],
      child: const EmsiDriveApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void storedSession() => FlutterSecureStorage.setMockInitialValues({
  StorageKeys.accessToken: 'saved-access',
  StorageKeys.refreshToken: 'saved-refresh',
});

void main() {
  for (final key in [StorageKeys.accessToken, StorageKeys.refreshToken]) {
    testWidgets('discards an incomplete stored token pair containing $key', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({key: 'incomplete'});
      final adapter = FakeHttpAdapter(
        (options) async => profileOrEmpty(options),
      );
      await pumpSessionApp(tester, adapter);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await const FlutterSecureStorage().read(key: key), isNull);
      expect(adapter.requests, isEmpty);
    });
  }
  testWidgets('blocks private routes when no session is stored', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = FakeHttpAdapter((options) async => profileOrEmpty(options));
    await pumpSessionApp(tester, adapter);
    expect(find.byType(LoginScreen), findsOneWidget);
    GoRouter.of(tester.element(find.byType(LoginScreen))).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets(
    'login survives app recreation and sign-out survives another restart',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final adapter = FakeHttpAdapter(
        (options) async => options.path == '/auth/login'
            ? jsonResponse(authResponseJson())
            : profileOrEmpty(options),
      );
      await pumpSessionApp(tester, adapter);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'yassine.elamrani@emsi-edu.ma',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'DemoPass123!');
      await tester.ensureVisible(find.text(l10nOf().loginSubmitLabel));
      await tester.tap(find.text(l10nOf().loginSubmitLabel));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpSessionApp(tester, adapter);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/auth/login'),
        hasLength(1),
      );
      GoRouter.of(tester.element(find.byType(HomeScreen)))
          .go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10nOf().signOutLabel));
      await tester.tap(find.text(l10nOf().signOutLabel));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpSessionApp(tester, adapter);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        await const FlutterSecureStorage().read(key: StorageKeys.refreshToken),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refreshes expired access credentials before opening home', (
    tester,
  ) async {
    storedSession();
    final adapter = FakeHttpAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return jsonResponse(authResponseJson());
      }
      if (options.headers['Authorization'] == 'Bearer saved-access') {
        return jsonResponse({}, statusCode: 401);
      }
      return profileOrEmpty(options);
    });
    await pumpSessionApp(tester, adapter);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      adapter.requests.where((r) => r.path == '/auth/refresh'),
      hasLength(1),
    );
    expect(
      await const FlutterSecureStorage().read(key: StorageKeys.accessToken),
      sampleAccessToken,
    );
  });

  testWidgets('keeps saved credentials during a network outage and retries', (
    tester,
  ) async {
    storedSession();
    var online = false;
    final adapter = FakeHttpAdapter((options) async {
      if (!online) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return profileOrEmpty(options);
    });
    await pumpSessionApp(tester, adapter);
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text(l10nOf().sessionRestoreUnavailable), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: StorageKeys.refreshToken),
      'saved-refresh',
    );
    online = true;
    await tester.tap(find.text(l10nOf().sessionRetry));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'rejected refresh redirects to login and clears saved credentials',
    (tester) async {
      storedSession();
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse({}, statusCode: 401),
      );
      await pumpSessionApp(tester, adapter);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        await const FlutterSecureStorage().read(key: StorageKeys.accessToken),
        isNull,
      );
      expect(
        await const FlutterSecureStorage().read(key: StorageKeys.refreshToken),
        isNull,
      );
      expect(adapter.requests, hasLength(2));
    },
  );

  testWidgets(
    'expiration during use locks private routes and clears the previous profile',
    (tester) async {
      storedSession();
      var rejected = false;
      final adapter = FakeHttpAdapter(
        (options) async => rejected
            ? jsonResponse({}, statusCode: 401)
            : profileOrEmpty(options),
      );
      await pumpSessionApp(tester, adapter);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EmsiDriveApp)),
      );
      rejected = true;
      final rejection = expectLater(
        container.read(authenticatedApiProvider).request<Object>('GET', '/me'),
        throwsA(isA<DioException>()),
      );
      await tester.pumpAndSettle();
      await rejection;
      expect(find.byType(LoginScreen), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Yassine El Amrani'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('waits for validation before restoring a protected destination', (
    tester,
  ) async {
    storedSession();
    final release = Completer<void>();
    final adapter = FakeHttpAdapter((options) async {
      if (options.path == '/me') await release.future;
      return profileOrEmpty(options);
    });
    await pumpSessionApp(tester, adapter, settle: false);
    expect(find.byType(HomeScreen), findsNothing);
    GoRouter.of(tester.element(find.byType(SessionScreen)))
        .go(AppRoutes.profile);
    await tester.pump();
    expect(find.byType(ProfileScreen), findsNothing);
    release.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets(
    'a late startup response cannot replace a newly signed-in account',
    (tester) async {
      storedSession();
      final release = Completer<void>();
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/me' &&
            options.headers['Authorization'] == 'Bearer saved-access') {
          await release.future;
          return jsonResponse({
            'id': 'old',
            'fullName': 'Old Account',
            'email': 'old@emsi-edu.ma',
          });
        }
        if (options.path == '/me') {
          return jsonResponse({
            'id': 'new',
            'fullName': 'New Account',
            'email': 'new@emsi-edu.ma',
          });
        }
        return profileOrEmpty(options);
      });
      await pumpSessionApp(tester, adapter, settle: false);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EmsiDriveApp)),
      );
      await container
          .read(tokenStorageProvider)
          .saveTokens(accessToken: 'new-access', refreshToken: 'new-refresh');
      await tester.pumpAndSettle();
      expect(find.text('New Account'), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();
      expect(find.text('Old Account'), findsNothing);
      expect(find.text('New Account'), findsOneWidget);
    },
  );
}
