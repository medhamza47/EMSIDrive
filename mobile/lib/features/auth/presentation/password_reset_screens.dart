import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/auth_repository_provider.dart';
import 'auth_error_presenter.dart';
import 'auth_validators.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';
import 'widgets/email_code_widgets.dart';

/// First step of the forgotten password flow: asks for the EMSI email and
/// requests a 6-digit code. The server answers the same way for unknown
/// addresses, so the next screen never confirms that an account exists.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});

  /// Email typed on the login screen, prefilled to save typing.
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);

  bool _submitted = false;
  bool _sending = false;
  String? _bannerMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _bannerMessage = null;
      _serverErrors = const <String, String>{};
    });
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.resetPasswordFor(email));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      final presenter = AuthErrorPresenter(AppLocalizations.of(context));
      setState(() {
        _serverErrors = presenter.fieldErrors(failure);
        _bannerMessage = presenter.bannerMessage(failure);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = AuthValidators(l10n);
    return _ResetScaffold(
      busy: _sending,
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AuthHeader(
              title: l10n.forgotPasswordTitle,
              subtitle: l10n.forgotPasswordSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: l10n.emailLabel,
              controller: _emailController,
              hint: l10n.emailHint,
              prefixIcon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.email],
              validator: validators.email,
              errorText: _serverErrors['email'],
              onChanged: (_) {
                if (_bannerMessage != null || _serverErrors.isNotEmpty) {
                  setState(() {
                    _bannerMessage = null;
                    _serverErrors = const <String, String>{};
                  });
                }
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_bannerMessage case final message?) ...<Widget>[
              AuthErrorBanner(message: message),
              const SizedBox(height: AppSpacing.lg),
            ],
            PrimaryButton(
              label: l10n.forgotPasswordSubmitLabel,
              expanded: true,
              isLoading: _sending,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Second step: the emailed code and the new password. A successful reset
/// ends every session on the server, so the student goes back to the login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.email, super.key});

  /// Address the code was requested for.
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _submitted = false;
  bool _submitting = false;
  String? _bannerMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _clearServerErrors() {
    if (_serverErrors.isEmpty && _bannerMessage == null) return;
    setState(() {
      _serverErrors = const <String, String>{};
      _bannerMessage = null;
    });
  }

  void _showFailure(AppFailure failure) {
    final presenter = AuthErrorPresenter(AppLocalizations.of(context));
    setState(() {
      // Keyed by the server field names: `code` and `newPassword`.
      _serverErrors = presenter.fieldErrors(failure);
      _bannerMessage = presenter.bannerMessage(failure);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _bannerMessage = null;
      _serverErrors = const <String, String>{};
    });
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: widget.email,
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.resetPasswordSuccessMessage)));
      context.go(AppRoutes.login);
    } on AppFailure catch (failure) {
      if (mounted) _showFailure(failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _resend() async {
    setState(() => _bannerMessage = null);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(widget.email);
      if (!mounted) return false;
      _codeController.clear();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.resetCodeResentMessage)));
      return true;
    } on AppFailure catch (failure) {
      if (mounted) _showFailure(failure);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final validators = AuthValidators(l10n);
    return _ResetScaffold(
      busy: _submitting,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AuthHeader(
                title: l10n.resetPasswordTitle,
                subtitle: l10n.resetPasswordSubtitle(widget.email),
              ),
              const SizedBox(height: AppSpacing.xl),
              EmailCodeField(
                controller: _codeController,
                errorText: _serverErrors['code'],
                onChanged: (_) => _clearServerErrors(),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              ResendCodeButton(onResend: _resend, enabled: !_submitting),
              AppTextField(
                label: l10n.newPasswordLabel,
                controller: _passwordController,
                hint: l10n.passwordHelper,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: validators.registerPassword,
                errorText: _serverErrors['newPassword'],
                onChanged: (_) => _clearServerErrors(),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.confirmPasswordLabel,
                controller: _confirmationController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: validators.passwordConfirmation(
                  () => _passwordController.text,
                ),
                onChanged: (_) => _clearServerErrors(),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.resetPasswordSignOutNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_bannerMessage case final message?) ...<Widget>[
                AuthErrorBanner(message: message),
                const SizedBox(height: AppSpacing.lg),
              ],
              PrimaryButton(
                label: l10n.resetPasswordSubmitLabel,
                expanded: true,
                isLoading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared page frame: back arrow to the login, centered scrollable form.
class _ResetScaffold extends StatelessWidget {
  const _ResetScaffold({required this.busy, required this.child});

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: busy
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.pageVertical,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
