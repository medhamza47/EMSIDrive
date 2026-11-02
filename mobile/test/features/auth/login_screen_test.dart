import 'dart:async';

import 'package:emsidrive_mobile/core/constants/auth_error_codes.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository_provider.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_response_dto.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/presentation/auth_validators.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/register_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:emsidrive_mobile/l10n/app_localizations.dart';
import 'package:emsidrive_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_api.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FlutterSecureStorage storage;
  late AppLocalizations l10n;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = const FlutterSecureStorage();
    l10n = l10nOf();
  });

  List<Override> repositoryOverrides(FakeAuthApi api) => <Override>[
    authRepositoryProvider.overrideWithValue(
      AuthRepository(api: api, tokenStorage: TokenStorage(storage)),
    ),
  ];

  Finder input(int index) => find.byType(TextFormField).at(index);

  Future<void> openLoginScreen(WidgetTester tester, FakeAuthApi api) async {
    await tester.binding.setSurfaceSize(const Size(720, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmsiDriveApp(
      tester,
      overrides: repositoryOverrides(api),
      initialLocation: AppRoutes.login,
    );
  }

  Future<void> fillCredentials(
    WidgetTester tester, {
    String email = 'yassine.elamrani@emsi-edu.ma',
    String password = 'secret123',
  }) async {
    await tester.enterText(input(0), email);
    await tester.enterText(input(1), password);
    await tester.pump();
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  group('LoginScreen', () {
    testWidgets('renders the mockup copy and the two credential fields', (tester) async {
      await openLoginScreen(tester, FakeAuthApi());

      expect(find.text(l10n.loginTitle), findsOneWidget);
      expect(find.text(l10n.loginSubtitle), findsOneWidget);
      expect(find.text(l10n.emailLabel), findsOneWidget);
      expect(find.text(l10n.emailHint), findsOneWidget);
      expect(find.text(l10n.passwordLabel), findsOneWidget);
      expect(find.text(l10n.forgotPasswordLabel), findsOneWidget);
      expect(find.text(l10n.loginSubmitLabel), findsOneWidget);
      expect(find.text(l10n.loginNoAccountPrompt), findsOneWidget);
      expect(find.text(l10n.createAccountLinkLabel), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
    });

    testWidgets('reports the required field errors on an empty submit', (tester) async {
      final api = FakeAuthApi();
      await openLoginScreen(tester, api);

      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationEmailRequired), findsOneWidget);
      expect(find.text(l10n.validationPasswordRequired), findsOneWidget);
      expect(api.loginRequests, isEmpty);
    });

    testWidgets('rejects a non EMSI email domain before reaching the API', (tester) async {
      final api = FakeAuthApi();
      await openLoginScreen(tester, api);

      await fillCredentials(tester, email: 'yassine.elamrani@gmail.com');
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.validationEmailDomain(AuthValidators.defaultStudentEmailDomain)),
        findsOneWidget,
      );
      expect(api.loginRequests, isEmpty);
    });

    testWidgets('sends the trimmed email when the form is valid', (tester) async {
      final api = FakeAuthApi();
      await openLoginScreen(tester, api);

      await fillCredentials(tester, email: '  yassine.elamrani@emsi-edu.ma  ');
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.loginRequests, hasLength(1));
      expect(api.loginRequests.single.email, 'yassine.elamrani@emsi-edu.ma');
      expect(api.loginRequests.single.password, 'secret123');
    });

    testWidgets('shows a spinner and blocks the actions while submitting', (tester) async {
      final pending = Completer<AuthResponseDto>();
      final api = FakeAuthApi(pending: pending);
      addTearDown(() {
        if (!pending.isCompleted) {
          pending.complete(authResponse());
        }
      });
      await openLoginScreen(tester, api);

      await fillCredentials(tester);
      await tapSubmit(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, l10n.forgotPasswordLabel))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, l10n.createAccountLinkLabel))
            .onPressed,
        isNull,
      );

      await tapSubmit(tester);
      expect(api.loginRequests, hasLength(1));

      pending.complete(authResponse());
      await tester.pumpAndSettle();
    });

    testWidgets('shows the French banner when the credentials are rejected', (tester) async {
      final api = FakeAuthApi(
        error: const UnauthorizedFailure(
          message: 'Invalid credentials',
          code: AuthErrorCodes.invalidCredentials,
        ),
      );
      await openLoginScreen(tester, api);

      await fillCredentials(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(find.text(l10n.invalidCredentialsErrorMessage), findsOneWidget);
      expect(await storage.read(key: StorageKeys.accessToken), isNull);
    });

    testWidgets('maps backend field validation errors under the fields', (tester) async {
      final api = FakeAuthApi(
        error: const ApiFailure(
          message: 'Validation failed',
          code: AuthErrorCodes.validationError,
          statusCode: 400,
          fieldErrors: <FieldError>[
            FieldError(field: 'email', message: 'Adresse email introuvable.'),
          ],
        ),
      );
      await openLoginScreen(tester, api);

      await fillCredentials(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Adresse email introuvable.'), findsOneWidget);
      expect(find.byType(AuthErrorBanner), findsNothing);
    });

    testWidgets('stores the tokens and lands on the home tab after logging in', (tester) async {
      final api = FakeAuthApi();
      await openLoginScreen(tester, api);

      await fillCredentials(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(await storage.read(key: StorageKeys.accessToken), sampleAccessToken);
      expect(await storage.read(key: StorageKeys.refreshToken), sampleRefreshToken);
    });

    testWidgets('opens the registration screen from the footer link', (tester) async {
      await openLoginScreen(tester, FakeAuthApi());

      await tester.tap(find.text(l10n.createAccountLinkLabel));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(l10n.registerTitle), findsOneWidget);
    });

    testWidgets('explains that the password reset is not available yet', (tester) async {
      await openLoginScreen(tester, FakeAuthApi());

      await tester.tap(find.text(l10n.forgotPasswordLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.forgotPasswordUnavailableMessage), findsOneWidget);
    });
  });
}
