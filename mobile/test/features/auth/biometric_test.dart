import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/app.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/biometric_auth.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/session_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/widgets/biometric_indicator.dart';
import 'package:emsidrive_mobile/features/auth/presentation/widgets/biometric_quick_login.dart';
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

/// Scripted stand-in for the device sensor.
class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({this.available = true, List<BiometricResult>? results})
    : _results = results ?? [];

  final bool available;
  final List<BiometricResult> _results;
  final List<String> reasons = [];
  final List<BiometricPromptTexts> prompts = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate(BiometricPromptTexts prompt) async {
    prompts.add(prompt);
    reasons.add(prompt.reason);
    return _results.isEmpty ? BiometricResult.success : _results.removeAt(0);
  }
}

const _linkedEmail = 'yassine.elamrani@emsi-edu.ma';

ResponseBody _empty(int status) => ResponseBody.fromString('', status);

/// Fake backend. [biometricLogin] overrides `/auth/biometric/login`.
FakeHttpAdapter _backend({
  Future<ResponseBody> Function()? biometricLogin,
}) => FakeHttpAdapter((options) async {
  switch (options.path) {
    case '/me':
      return jsonResponse(authResponseJson()['user'] as Map<String, dynamic>);
    case '/me/biometric-devices':
      return jsonResponse({
        'deviceId': 'device-1',
        'deviceKey': 'key-1',
      }, statusCode: 201);
    case '/auth/login':
      return jsonResponse(authResponseJson());
    case '/auth/biometric/login':
      return biometricLogin?.call() ??
          jsonResponse({'session': authResponseJson(), 'deviceKey': 'key-2'});
    case '/auth/logout' || '/auth/biometric/revoke':
      return _empty(204);
  }
  return ResponseBody.fromString(
    '[]',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
});

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

/// Stored state: an open session and/or this phone linked for fingerprint.
void _stored({bool session = true, bool linked = true}) =>
    FlutterSecureStorage.setMockInitialValues({
      if (session) StorageKeys.accessToken: 'saved-access',
      if (session) StorageKeys.refreshToken: 'saved-refresh',
      if (linked) ...{
        StorageKeys.biometricDeviceId: 'device-1',
        StorageKeys.biometricDeviceKey: 'key-1',
        StorageKeys.biometricEmail: _linkedEmail,
        StorageKeys.biometricName: 'Yassine El Amrani',
      },
    });

Future<String?> _read(String key) => const FlutterSecureStorage().read(key: key);

Iterable<RequestOptions> _calls(FakeHttpAdapter adapter, String path) =>
    adapter.requests.where((r) => r.path == path);

Map<String, dynamic> _body(RequestOptions request) => request.data is String
    ? jsonDecode(request.data as String) as Map<String, dynamic>
    : request.data as Map<String, dynamic>;

BiometricVisual _visual(WidgetTester tester) => tester
    .widget<BiometricIndicator>(find.byType(BiometricIndicator))
    .visual;

FilledButton _filledButton(WidgetTester tester, String label) => tester.widget(
  find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  ),
);

Future<void> _logIn(WidgetTester tester, {String email = _linkedEmail}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'DemoPass123!');
  await tester.ensureVisible(find.text(l10nOf().loginSubmitLabel));
  await tester.tap(find.text(l10nOf().loginSubmitLabel));
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetLoginAutoPrompt);

  group('open session', () {
    testWidgets('goes straight home even when the phone is linked', (
      tester,
    ) async {
      _stored();
      final adapter = _backend();
      final biometrics = FakeBiometricAuth();
      await _pump(tester, adapter, biometrics);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SessionScreen), findsNothing);
      expect(biometrics.reasons, isEmpty);
      expect(_calls(adapter, '/auth/biometric/login'), isEmpty);
    });

    testWidgets('without a link it goes straight home too', (tester) async {
      _stored(linked: false);
      final biometrics = FakeBiometricAuth();
      await _pump(tester, _backend(), biometrics);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(biometrics.reasons, isEmpty);
    });
  });

  group('fingerprint feedback on the login panel', () {
    testWidgets('a wrong finger shakes, shows the error, allows a retry', (
      tester,
    ) async {
      _stored(session: false);
      await _pump(
        tester,
        _backend(),
        FakeBiometricAuth(results: [BiometricResult.failed]),
      );
      expect(_visual(tester), BiometricVisual.failure);
      expect(find.text(l10nOf().biometricFailed), findsOneWidget);
      expect(
        _filledButton(tester, l10nOf().biometricSignInButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('success shows the check before opening home', (tester) async {
      _stored(session: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioClientProvider.overrideWithValue(dioWithAdapter(_backend())),
            biometricAuthProvider.overrideWithValue(FakeBiometricAuth()),
          ],
          child: const EmsiDriveApp(),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(_visual(tester), BiometricVisual.success);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('locked out disables the fingerprint button', (tester) async {
      _stored(session: false);
      await _pump(
        tester,
        _backend(),
        FakeBiometricAuth(results: [BiometricResult.lockedOut]),
      );
      expect(_visual(tester), BiometricVisual.lockedOut);
      expect(find.text(l10nOf().biometricLockedOut), findsOneWidget);
      expect(
        _filledButton(tester, l10nOf().biometricSignInButton).onPressed,
        isNull,
      );
    });

    testWidgets('a missing sensor shows the unavailable state', (tester) async {
      _stored(session: false);
      await _pump(
        tester,
        _backend(),
        FakeBiometricAuth(results: [BiometricResult.unavailable]),
      );
      expect(_visual(tester), BiometricVisual.unavailable);
      expect(find.text(l10nOf().biometricUnavailable), findsOneWidget);
    });

    testWidgets('reduce motion still reaches home', (tester) async {
      _stored(session: false);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pump(tester, _backend(), FakeBiometricAuth());
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('"use password" opens the form with the linked email', (
      tester,
    ) async {
      _stored(session: false);
      await _pump(
        tester,
        _backend(),
        FakeBiometricAuth(results: [BiometricResult.cancelled]),
      );
      await tester.ensureVisible(find.text(l10nOf().biometricUsePassword));
      await tester.tap(find.text(l10nOf().biometricUsePassword));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(BiometricQuickLogin), findsNothing);
      expect(find.text(_linkedEmail), findsOneWidget);
      // The link stays: the form offers to come back to the fingerprint.
      expect(find.text(l10nOf().biometricSignInButton), findsOneWidget);
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-1');
    });
  });

  group('login screen with a linked phone', () {
    testWidgets('greets the student and signs in with the fingerprint', (
      tester,
    ) async {
      _stored(session: false);
      final adapter = _backend();
      final biometrics = FakeBiometricAuth();
      await _pump(tester, adapter, biometrics);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(biometrics.reasons, [l10nOf().biometricSignInReason]);
      expect(_body(_calls(adapter, '/auth/biometric/login').single), {
        'deviceId': 'device-1',
        'deviceKey': 'key-1',
      });
      // The rotated key replaced the old one, and the session is stored.
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-2');
      expect(await _read(StorageKeys.refreshToken), isNotNull);
      expect(_calls(adapter, '/auth/login'), isEmpty);
    });

    testWidgets('shows the panel and waits when the prompt is cancelled', (
      tester,
    ) async {
      _stored(session: false);
      final adapter = _backend();
      await _pump(
        tester,
        adapter,
        FakeBiometricAuth(results: [BiometricResult.cancelled]),
      );
      expect(find.byType(BiometricQuickLogin), findsOneWidget);
      expect(find.text(l10nOf().biometricWelcomeBack('Yassine')), findsOneWidget);
      expect(find.text(_linkedEmail), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('a revoked link falls back to the password form', (
      tester,
    ) async {
      _stored(session: false);
      final adapter = _backend(
        biometricLogin: () async => jsonResponse(
          apiErrorJson(
            status: 401,
            code: 'INVALID_DEVICE_KEY',
            message: 'This phone is no longer linked',
          ),
          statusCode: 401,
        ),
      );
      await _pump(tester, adapter, FakeBiometricAuth());

      expect(find.byType(BiometricQuickLogin), findsNothing);
      expect(find.text(l10nOf().biometricUnlinked), findsOneWidget);
      expect(find.text(_linkedEmail), findsOneWidget);
      expect(await _read(StorageKeys.biometricDeviceKey), isNull);
    });

    testWidgets('a server outage keeps the link and explains', (tester) async {
      _stored(session: false);
      final adapter = _backend(biometricLogin: () async => _empty(503));
      await _pump(tester, adapter, FakeBiometricAuth());

      expect(find.byType(BiometricQuickLogin), findsOneWidget);
      expect(find.text(l10nOf().biometricNetworkError), findsOneWidget);
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-1');
    });

    testWidgets('"switch account" unlinks the phone on the server', (
      tester,
    ) async {
      _stored(session: false);
      final adapter = _backend();
      await _pump(
        tester,
        adapter,
        FakeBiometricAuth(results: [BiometricResult.cancelled]),
      );
      await tester.ensureVisible(find.text(l10nOf().biometricSwitchAccount));
      await tester.tap(find.text(l10nOf().biometricSwitchAccount));
      await tester.pumpAndSettle();
      // Asks first; the dialog's confirm button carries the same label.
      expect(find.text(l10nOf().biometricSwitchTitle), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10nOf().biometricSwitchAccount),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BiometricQuickLogin), findsNothing);
      expect(find.text(_linkedEmail), findsNothing);
      expect(_body(_calls(adapter, '/auth/biometric/revoke').single), {
        'deviceId': 'device-1',
        'deviceKey': 'key-1',
      });
      expect(await _read(StorageKeys.biometricDeviceId), isNull);
    });

    testWidgets('cancelling "switch account" keeps the link', (tester) async {
      _stored(session: false);
      final adapter = _backend();
      await _pump(
        tester,
        adapter,
        FakeBiometricAuth(results: [BiometricResult.cancelled]),
      );
      await tester.ensureVisible(find.text(l10nOf().biometricSwitchAccount));
      await tester.tap(find.text(l10nOf().biometricSwitchAccount));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf().biometricCancel));
      await tester.pumpAndSettle();

      expect(find.byType(BiometricQuickLogin), findsOneWidget);
      expect(_calls(adapter, '/auth/biometric/revoke'), isEmpty);
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-1');
    });

    testWidgets('a cancelled prompt leaves a hint, in French texts', (
      tester,
    ) async {
      _stored(session: false);
      final biometrics = FakeBiometricAuth(
        results: [BiometricResult.cancelled],
      );
      await _pump(tester, _backend(), biometrics);

      expect(find.text(l10nOf().biometricCancelledHint), findsOneWidget);
      final prompt = biometrics.prompts.single;
      expect(prompt.title, l10nOf().biometricPromptTitle);
      expect(prompt.cancel, l10nOf().biometricUsePassword);
    });

    testWidgets('signing out from the profile returns to the panel', (
      tester,
    ) async {
      _stored(linked: false);
      final adapter = _backend();
      await _pump(tester, adapter, FakeBiometricAuth());
      // Link from the profile switch.
      GoRouter.of(
        tester.element(find.byType(HomeScreen)),
      ).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10nOf().biometricSettingTitle));
      await tester.tap(find.text(l10nOf().biometricSettingTitle));
      await tester.pumpAndSettle();
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-1');
      // Let the confirmation snackbar leave; it covers the sign-out button.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // A stray tap on the switch asks first; cancelling keeps the link.
      await tester.tap(find.text(l10nOf().biometricSettingTitle));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().biometricDisableTitle), findsOneWidget);
      await tester.tap(find.text(l10nOf().biometricCancel));
      await tester.pumpAndSettle();
      expect(await _read(StorageKeys.biometricDeviceKey), 'key-1');
      expect(_calls(adapter, '/auth/biometric/revoke'), isEmpty);

      await tester.ensureVisible(find.text(l10nOf().signOutLabel));
      await tester.tap(find.text(l10nOf().signOutLabel));
      await tester.pumpAndSettle();

      expect(_calls(adapter, '/auth/logout'), hasLength(1));
      expect(find.byType(BiometricQuickLogin), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });
  });

  group('offer after a password login', () {
    testWidgets('links the phone when accepted', (tester) async {
      _stored(session: false, linked: false);
      final adapter = _backend();
      final biometrics = FakeBiometricAuth();
      await _pump(tester, adapter, biometrics);
      await _logIn(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(l10nOf().biometricOfferTitle), findsOneWidget);
      await tester.tap(find.text(l10nOf().biometricOfferAccept));
      await tester.pumpAndSettle();

      expect(biometrics.reasons, [l10nOf().biometricEnableReason]);
      expect(_calls(adapter, '/me/biometric-devices'), hasLength(1));
      expect(await _read(StorageKeys.biometricDeviceId), 'device-1');
      expect(await _read(StorageKeys.biometricEmail), _linkedEmail);
      expect(find.text(l10nOf().biometricEnabledMessage), findsOneWidget);
    });

    testWidgets('declining keeps the phone unlinked', (tester) async {
      _stored(session: false, linked: false);
      final adapter = _backend();
      final biometrics = FakeBiometricAuth();
      await _pump(tester, adapter, biometrics);
      await _logIn(tester);
      await tester.tap(find.text(l10nOf().biometricOfferLater));
      await tester.pumpAndSettle();
      expect(biometrics.reasons, isEmpty);
      expect(_calls(adapter, '/me/biometric-devices'), isEmpty);
      expect(await _read(StorageKeys.biometricDeviceId), isNull);
    });

    testWidgets('no offer on a phone without an enrolled fingerprint', (
      tester,
    ) async {
      _stored(session: false, linked: false);
      await _pump(tester, _backend(), FakeBiometricAuth(available: false));
      await _logIn(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(l10nOf().biometricOfferTitle), findsNothing);
    });

    testWidgets('another account signing in removes the previous link', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.biometricDeviceId: 'old-device',
        StorageKeys.biometricDeviceKey: 'old-key',
        StorageKeys.biometricEmail: 'someone.else@emsi-edu.ma',
        StorageKeys.biometricName: 'Someone Else',
      });
      final adapter = _backend();
      await _pump(
        tester,
        adapter,
        FakeBiometricAuth(results: [BiometricResult.cancelled]),
      );
      await tester.ensureVisible(find.text(l10nOf().biometricUsePassword));
      await tester.tap(find.text(l10nOf().biometricUsePassword));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await _logIn(tester);

      expect(_body(_calls(adapter, '/auth/biometric/revoke').single), {
        'deviceId': 'old-device',
        'deviceKey': 'old-key',
      });
      expect(await _read(StorageKeys.biometricDeviceId), isNull);
      // The new account is offered its own link.
      expect(find.text(l10nOf().biometricOfferTitle), findsOneWidget);
    });
  });
}
