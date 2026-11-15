import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/app.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/biometric_auth.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/session_screen.dart';
import 'package:emsidrive_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fake_auth_api.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

/// Scripted stand-in for the device sensor.
class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({this.available = true, List<BiometricResult>? results})
    : _results = results ?? [];

  final bool available;
  final List<BiometricResult> _results;
  final List<String> reasons = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate(String reason) async {
    reasons.add(reason);
    return _results.isEmpty ? BiometricResult.success : _results.removeAt(0);
  }
}

ResponseBody _profileOrEmpty(RequestOptions options) => options.path == '/me'
    ? jsonResponse(authResponseJson()['user'] as Map<String, dynamic>)
    : ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

Future<void> _pump(
  WidgetTester tester,
  FakeHttpAdapter adapter,
  FakeBiometricAuth biometrics,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        biometricAuthProvider.overrideWithValue(biometrics),
      ],
      child: const EmsiDriveApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void _storedSession({bool biometric = true}) =>
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'saved-access',
      StorageKeys.refreshToken: 'saved-refresh',
      if (biometric) StorageKeys.biometricEnabled: 'true',
    });

Future<String?> _read(String key) => const FlutterSecureStorage().read(key: key);

void main() {
  testWidgets('a locked session opens home only after the fingerprint', (
    tester,
  ) async {
    _storedSession();
    final adapter = FakeHttpAdapter((options) async => _profileOrEmpty(options));
    final biometrics = FakeBiometricAuth(
      results: [BiometricResult.cancelled, BiometricResult.success],
    );
    await _pump(tester, adapter, biometrics);

    // The prompt opened by itself once, was cancelled, and nothing reached
    // the API while locked.
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text(l10nOf().biometricLockedTitle), findsOneWidget);
    expect(biometrics.reasons, [l10nOf().biometricUnlockReason]);
    expect(adapter.requests, isEmpty);

    // Private routes stay closed while locked.
    GoRouter.of(
      tester.element(find.byType(SessionScreen)),
    ).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);

    await tester.tap(find.text(l10nOf().biometricUnlockButton));
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsNothing);
    expect(adapter.requests.where((r) => r.path == '/me'), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows why the fingerprint failed and keeps the lock', (
    tester,
  ) async {
    _storedSession();
    final adapter = FakeHttpAdapter((options) async => _profileOrEmpty(options));
    await _pump(
      tester,
      adapter,
      FakeBiometricAuth(results: [BiometricResult.lockedOut]),
    );
    expect(find.text(l10nOf().biometricLockedOut), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('using the password clears the session and the fingerprint', (
    tester,
  ) async {
    _storedSession();
    final adapter = FakeHttpAdapter((options) async => _profileOrEmpty(options));
    await _pump(
      tester,
      adapter,
      FakeBiometricAuth(results: [BiometricResult.cancelled]),
    );
    await tester.tap(find.text(l10nOf().biometricUsePassword));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await _read(StorageKeys.refreshToken), isNull);
    expect(await _read(StorageKeys.biometricEnabled), isNull);
  });

  testWidgets('without the option the saved session opens home directly', (
    tester,
  ) async {
    _storedSession(biometric: false);
    final adapter = FakeHttpAdapter((options) async => _profileOrEmpty(options));
    final biometrics = FakeBiometricAuth();
    await _pump(tester, adapter, biometrics);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(biometrics.reasons, isEmpty);
  });

  Future<void> logIn(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'yassine.elamrani@emsi-edu.ma',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'DemoPass123!');
    await tester.ensureVisible(find.text(l10nOf().loginSubmitLabel));
    await tester.tap(find.text(l10nOf().loginSubmitLabel));
    await tester.pumpAndSettle();
  }

  FakeHttpAdapter loginAdapter() => FakeHttpAdapter(
    (options) async => options.path == '/auth/login'
        ? jsonResponse(authResponseJson())
        : _profileOrEmpty(options),
  );

  testWidgets('offers the fingerprint after a password login', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = loginAdapter();
    final biometrics = FakeBiometricAuth();
    await _pump(tester, adapter, biometrics);
    await logIn(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(l10nOf().biometricOfferTitle), findsOneWidget);
    await tester.tap(find.text(l10nOf().biometricOfferAccept));
    await tester.pumpAndSettle();
    expect(biometrics.reasons, [l10nOf().biometricEnableReason]);
    expect(await _read(StorageKeys.biometricEnabled), 'true');
    expect(find.text(l10nOf().biometricEnabledMessage), findsOneWidget);

    // Next launch is locked behind the fingerprint.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(
      tester,
      adapter,
      FakeBiometricAuth(results: [BiometricResult.cancelled]),
    );
    expect(find.text(l10nOf().biometricLockedTitle), findsOneWidget);
  });

  testWidgets('declining the offer keeps the plain session', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final biometrics = FakeBiometricAuth();
    await _pump(tester, loginAdapter(), biometrics);
    await logIn(tester);
    await tester.tap(find.text(l10nOf().biometricOfferLater));
    await tester.pumpAndSettle();
    expect(biometrics.reasons, isEmpty);
    expect(await _read(StorageKeys.biometricEnabled), isNull);
  });

  testWidgets('no offer on a phone without an enrolled fingerprint', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await _pump(tester, loginAdapter(), FakeBiometricAuth(available: false));
    await logIn(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(l10nOf().biometricOfferTitle), findsNothing);
  });
}
