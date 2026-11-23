import 'package:emsidrive_mobile/core/constants/auth_error_codes.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository_provider.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/presentation/auth_validators.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/auth/presentation/password_reset_screens.dart';
import 'package:emsidrive_mobile/features/auth/presentation/widgets/email_code_widgets.dart';
import 'package:emsidrive_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_api.dart';
import '../../helpers/pump_app.dart';

void main() {
  const email = 'yassine.elamrani@emsi-edu.ma';
  late AppLocalizations l10n;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    l10n = l10nOf();
  });

  List<Override> overrides(FakeAuthApi api) => <Override>[
    authRepositoryProvider.overrideWithValue(
      AuthRepository(api: api, tokenStorage: TokenStorage(const FlutterSecureStorage())),
    ),
  ];

  Finder input(int index) => find.byType(TextFormField).at(index);

  Future<void> open(WidgetTester tester, FakeAuthApi api, String location) async {
    await tester.binding.setSurfaceSize(const Size(720, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmsiDriveApp(tester, overrides: overrides(api), initialLocation: location);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  group('ForgotPasswordScreen', () {
    testWidgets('validates the email before calling the API', (tester) async {
      final api = FakeAuthApi();
      await open(tester, api, AppRoutes.forgotPassword);

      await tapButton(tester, l10n.forgotPasswordSubmitLabel);
      expect(find.text(l10n.validationEmailRequired), findsOneWidget);

      await tester.enterText(input(0), 'someone@gmail.com');
      await tapButton(tester, l10n.forgotPasswordSubmitLabel);
      expect(
        find.text(l10n.validationEmailDomain(AuthValidators.defaultStudentEmailDomain)),
        findsOneWidget,
      );
      expect(api.passwordResetRequests, isEmpty);
    });

    testWidgets('requests a code and opens the code screen', (tester) async {
      final api = FakeAuthApi();
      await open(tester, api, AppRoutes.forgotPasswordFor(email));

      expect(find.text(email), findsOneWidget);
      await tapButton(tester, l10n.forgotPasswordSubmitLabel);

      expect(api.passwordResetRequests, <String>[email]);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text(l10n.resetPasswordSubtitle(email)), findsOneWidget);
    });

    testWidgets('shows the network error and stays on the screen', (tester) async {
      final api = FakeAuthApi(error: const NetworkFailure(message: 'offline'));
      await open(tester, api, AppRoutes.forgotPasswordFor(email));

      await tapButton(tester, l10n.forgotPasswordSubmitLabel);

      expect(find.text(l10n.networkErrorMessage), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('needs an email in the link', (tester) async {
      await open(tester, FakeAuthApi(), AppRoutes.resetPassword);

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('checks the code and the confirmation locally', (tester) async {
      final api = FakeAuthApi();
      await open(tester, api, AppRoutes.resetPasswordFor(email));

      await tester.enterText(input(0), '12a4');
      await tester.enterText(input(1), 'NewStrongPass1!');
      await tester.enterText(input(2), 'Different1!');
      await tapButton(tester, l10n.resetPasswordSubmitLabel);

      expect(find.text(l10n.validationResetCodeInvalid), findsOneWidget);
      expect(find.text(l10n.validationPasswordMismatch), findsOneWidget);
      expect(api.resetRequests, isEmpty);
    });

    testWidgets('resets the password and returns to the login', (tester) async {
      final api = FakeAuthApi();
      await open(tester, api, AppRoutes.resetPasswordFor(email));

      await tester.enterText(input(0), '482913');
      await tester.enterText(input(1), 'NewStrongPass1!');
      await tester.enterText(input(2), 'NewStrongPass1!');
      await tapButton(tester, l10n.resetPasswordSubmitLabel);

      expect(api.resetRequests, hasLength(1));
      expect(api.resetRequests.single.email, email);
      expect(api.resetRequests.single.code, '482913');
      expect(api.resetRequests.single.newPassword, 'NewStrongPass1!');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(l10n.resetPasswordSuccessMessage), findsOneWidget);
    });

    testWidgets('explains a rejected code', (tester) async {
      final api = FakeAuthApi(
        error: const ApiFailure(
          message: 'The code is invalid or expired',
          code: AuthErrorCodes.invalidResetCode,
          statusCode: 400,
        ),
      );
      await open(tester, api, AppRoutes.resetPasswordFor(email));

      await tester.enterText(input(0), '000000');
      await tester.enterText(input(1), 'NewStrongPass1!');
      await tester.enterText(input(2), 'NewStrongPass1!');
      await tapButton(tester, l10n.resetPasswordSubmitLabel);

      expect(find.text(l10n.invalidResetCodeErrorMessage), findsOneWidget);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('lets a new code be requested after the cooldown', (tester) async {
      final api = FakeAuthApi();
      await open(tester, api, AppRoutes.resetPasswordFor(email));

      final countdown = find.widgetWithText(
        TextButton,
        l10n.resendCodeCountdown(codeResendCooldownSeconds),
      );
      expect(countdown, findsOneWidget);
      expect(tester.widget<TextButton>(countdown).onPressed, isNull);

      await tester.pump(const Duration(seconds: codeResendCooldownSeconds));
      await tester.pump();
      final resend = find.widgetWithText(TextButton, l10n.resendCodeLabel);
      expect(tester.widget<TextButton>(resend).onPressed, isNotNull);

      await tester.tap(resend);
      await tester.pumpAndSettle();

      expect(api.passwordResetRequests, <String>[email]);
      expect(find.text(l10n.resetCodeResentMessage), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, l10n.resendCodeCountdown(codeResendCooldownSeconds)),
        findsOneWidget,
      );
    });
  });
}
