import 'dart:async';

import 'package:emsidrive_mobile/core/constants/auth_error_codes.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository_provider.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_requests.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_response_dto.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
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

  Future<void> openRegisterScreen(WidgetTester tester, FakeAuthApi api) async {
    await tester.binding.setSurfaceSize(const Size(720, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmsiDriveApp(
      tester,
      overrides: repositoryOverrides(api),
      initialLocation: AppRoutes.register,
    );
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String fullName = 'Yassine El Amrani',
    String email = 'yassine.elamrani@emsi-edu.ma',
    String phoneNumber = '+212612345678',
    String password = 'secret123',
  }) async {
    await tester.enterText(input(0), fullName);
    await tester.enterText(input(1), email);
    await tester.enterText(input(2), phoneNumber);
    await tester.enterText(input(3), password);
    await tester.pump();
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  group('RegisterScreen', () {
    testWidgets('renders the mockup copy and the four registration fields', (tester) async {
      await openRegisterScreen(tester, FakeAuthApi());

      expect(find.text(l10n.registerTitle), findsOneWidget);
      expect(find.text(l10n.registerSubtitle), findsOneWidget);
      expect(find.text(l10n.fullNameLabel), findsOneWidget);
      expect(find.text(l10n.emailLabel), findsOneWidget);
      expect(find.text(l10n.phoneNumberLabel), findsOneWidget);
      expect(find.text(l10n.passwordLabel), findsOneWidget);
      expect(find.text(l10n.registerSubmitLabel), findsOneWidget);
      expect(find.text(l10n.registerHasAccountPrompt), findsOneWidget);
      expect(find.text(l10n.loginLinkLabel), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(4));
    });

    testWidgets('reports the required field errors on an empty submit', (tester) async {
      final api = FakeAuthApi();
      await openRegisterScreen(tester, api);

      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationFullNameRequired), findsOneWidget);
      expect(find.text(l10n.validationEmailRequired), findsOneWidget);
      expect(find.text(l10n.validationPasswordRequired), findsOneWidget);
      expect(api.registerRequests, isEmpty);
    });

    testWidgets('rejects a password shorter than the backend minimum', (tester) async {
      final api = FakeAuthApi();
      await openRegisterScreen(tester, api);

      await fillForm(tester, password: 'short1');
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          l10n.validationPasswordTooShort(RegisterRequestDto.passwordMinLength),
        ),
        findsOneWidget,
      );
      expect(api.registerRequests, isEmpty);
    });

    testWidgets('creates the account, stores the tokens and lands on the home tab', (
      tester,
    ) async {
      final api = FakeAuthApi();
      await openRegisterScreen(tester, api);

      await fillForm(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.registerRequests, hasLength(1));
      expect(api.registerRequests.single.email, 'yassine.elamrani@emsi-edu.ma');
      expect(api.registerRequests.single.fullName, 'Yassine El Amrani');
      expect(api.registerRequests.single.password, 'secret123');
      expect(api.registerRequests.single.phoneNumber, '+212612345678');

      expect(find.text(l10n.registerSuccessMessage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(await storage.read(key: StorageKeys.accessToken), sampleAccessToken);
      expect(await storage.read(key: StorageKeys.refreshToken), sampleRefreshToken);
    });

    testWidgets('omits the phone number when the optional field is blank', (tester) async {
      final api = FakeAuthApi();
      await openRegisterScreen(tester, api);

      await fillForm(tester, phoneNumber: '');
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.registerRequests, hasLength(1));
      expect(api.registerRequests.single.phoneNumber, isNull);
    });

    testWidgets('shows the French banner when the email is already used', (tester) async {
      final api = FakeAuthApi(
        error: const ApiFailure(
          message: 'Email already used',
          code: AuthErrorCodes.emailAlreadyUsed,
          statusCode: 409,
        ),
      );
      await openRegisterScreen(tester, api);

      await fillForm(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(find.text(l10n.emailAlreadyUsedErrorMessage), findsOneWidget);
      expect(await storage.read(key: StorageKeys.accessToken), isNull);
    });

    testWidgets('maps backend field validation errors under the fields', (tester) async {
      final api = FakeAuthApi(
        error: const ApiFailure(
          message: 'Validation failed',
          code: AuthErrorCodes.validationError,
          statusCode: 400,
          fieldErrors: <FieldError>[
            FieldError(field: 'phoneNumber', message: 'Numéro introuvable.'),
          ],
        ),
      );
      await openRegisterScreen(tester, api);

      await fillForm(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Numéro introuvable.'), findsOneWidget);
      expect(find.byType(AuthErrorBanner), findsNothing);
    });

    testWidgets('shows a spinner and blocks the actions while submitting', (tester) async {
      final pending = Completer<AuthResponseDto>();
      final api = FakeAuthApi(pending: pending);
      addTearDown(() {
        if (!pending.isCompleted) {
          pending.complete(authResponse());
        }
      });
      await openRegisterScreen(tester, api);

      await fillForm(tester);
      await tapSubmit(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_back)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, l10n.loginLinkLabel))
            .onPressed,
        isNull,
      );
      expect(api.registerRequests, hasLength(1));

      pending.complete(authResponse());
      await tester.pumpAndSettle();
    });

    testWidgets('returns to the login screen from the back button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpEmsiDriveApp(
        tester,
        overrides: repositoryOverrides(FakeAuthApi()),
        initialLocation: AppRoutes.login,
      );

      await tester.tap(find.text(l10n.createAccountLinkLabel));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });
  });
}
