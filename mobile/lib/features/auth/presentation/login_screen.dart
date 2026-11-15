import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_submission_state.dart';
import '../application/biometric_link_service.dart';
import '../application/login_controller.dart';
import '../application/session_controller.dart';
import '../domain/biometric_link.dart';
import 'widgets/biometric_quick_login.dart';
import 'auth_error_presenter.dart';
import 'auth_validators.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';

/// Login screen matching the first mockup of `EMSIDrive_maquettes_mobile.html`.
///
/// Submits the credentials through [LoginController], which persists the token
/// pair in secure storage before the router sends the student to the home tab.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// The fingerprint prompt opens by itself once per app run, on the first
/// login screen, not again after each sign-out.
bool _autoPromptedThisRun = false;

/// Lets each widget test start like a fresh app run.
@visibleForTesting
void resetLoginAutoPrompt() => _autoPromptedThisRun = false;

class _LoginScreenState extends ConsumerState<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitted = false;
  String? _bannerMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  /// The student chose the email and password form over the fingerprint.
  bool _usePassword = false;

  void _showPasswordForm(BiometricLink? link, {String? banner}) {
    setState(() {
      _usePassword = true;
      _bannerMessage = banner;
      if (link != null && _emailController.text.isEmpty) {
        _emailController.text = link.email;
      }
    });
  }

  Future<void> _switchAccount() async {
    await ref.read(biometricLinkServiceProvider).unlink();
    ref.invalidate(biometricLinkProvider);
    if (!mounted) return;
    _emailController.clear();
    _passwordController.clear();
    _showPasswordForm(null);
  }

  /// Panel shown instead of the form when this phone is linked.
  Widget _quickLogin(BiometricLink link) {
    // Prompt by itself only when the app opened signed out, never right after
    // the student chose to sign out.
    final autoPrompt =
        !_autoPromptedThisRun &&
        !ref.read(sessionControllerProvider).wasSignedIn;
    _autoPromptedThisRun = true;
    return BiometricQuickLogin(
      link: link,
      autoPrompt: autoPrompt,
      onUsePassword: () => _showPasswordForm(link),
      onSwitchAccount: _switchAccount,
      onUnlinked: (message) {
        ref.invalidate(biometricLinkProvider);
        _showPasswordForm(link, banner: message);
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthValidators get _validators =>
      AuthValidators(AppLocalizations.of(context));

  void _clearServerErrors() {
    if (_serverErrors.isEmpty && _bannerMessage == null) {
      return;
    }
    setState(() {
      _serverErrors = const <String, String>{};
      _bannerMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _bannerMessage = null;
      _serverErrors = const <String, String>{};
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _handleFailure(AppFailure failure) {
    final presenter = AuthErrorPresenter(AppLocalizations.of(context));
    setState(() {
      _serverErrors = presenter.fieldErrors(failure);
      _bannerMessage = presenter.bannerMessage(failure);
    });
  }

  void _showForgotPasswordPlaceholder() {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordUnavailableMessage)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(loginControllerProvider);
    final link = ref.watch(biometricLinkProvider).value;

    ref.listen<AuthSubmissionState>(loginControllerProvider, (previous, next) {
      switch (next) {
        case AuthSucceeded():
          context.go(AppRoutes.home);
        case AuthFailed(:final failure):
          _handleFailure(failure);
        case AuthIdle() || AuthSubmitting():
          break;
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.pageVertical,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: link != null && !_usePassword
                  ? _quickLogin(link)
                  : AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _submitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AuthHeader(
                              title: l10n.loginTitle,
                              subtitle: l10n.loginSubtitle,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppTextField(
                              label: l10n.emailLabel,
                              controller: _emailController,
                              hint: l10n.emailHint,
                              prefixIcon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              validator: _validators.email,
                              errorText: _serverErrors['email'],
                              onChanged: (_) => _clearServerErrors(),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: l10n.passwordLabel,
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              validator: _validators.loginPassword,
                              errorText: _serverErrors['password'],
                              onChanged: (_) => _clearServerErrors(),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: state.isSubmitting
                                    ? null
                                    : _showForgotPasswordPlaceholder,
                                child: Text(l10n.forgotPasswordLabel),
                              ),
                            ),
                            if (_bannerMessage case final message?) ...<Widget>[
                              AuthErrorBanner(message: message),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            PrimaryButton(
                              label: l10n.loginSubmitLabel,
                              expanded: true,
                              isLoading: state.isSubmitting,
                              onPressed: _submit,
                            ),
                            if (link != null) ...<Widget>[
                              const SizedBox(height: AppSpacing.sm),
                              TextButton.icon(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => setState(() {
                                        _usePassword = false;
                                        _bannerMessage = null;
                                      }),
                                icon: const Icon(Icons.fingerprint),
                                label: Text(l10n.biometricSignInButton),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            AuthFooterLink(
                              prompt: l10n.loginNoAccountPrompt,
                              action: l10n.createAccountLinkLabel,
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => context.push(AppRoutes.register),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.appName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
