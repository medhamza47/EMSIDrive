import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_submission_state.dart';
import '../application/register_controller.dart';
import '../data/auth_repository_provider.dart';
import '../data/dto/auth_requests.dart';
import 'auth_error_presenter.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';
import 'widgets/email_code_widgets.dart';

/// Second step of the registration: the code emailed to [form]'s address
/// proves the address exists and belongs to the student. The account is only
/// created once the server accepts that code.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({required this.form, super.key});

  /// Registration form already accepted by the server.
  final RegisterRequestDto form;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _submitted = false;
  String? _bannerMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_serverErrors.isEmpty && _bannerMessage == null) return;
    setState(() {
      _serverErrors = const <String, String>{};
      _bannerMessage = null;
    });
  }

  void _showFailure(AppFailure failure) {
    final presenter = AuthErrorPresenter(AppLocalizations.of(context));
    setState(() {
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final form = widget.form;
    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          email: form.email,
          password: form.password,
          fullName: form.fullName,
          phoneNumber: form.phoneNumber,
          verificationCode: _codeController.text.trim(),
        );
  }

  Future<bool> _resend() async {
    _clearErrors();
    try {
      await ref.read(authRepositoryProvider).requestRegistrationCode(widget.form);
      if (!mounted) return false;
      _codeController.clear();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.verifyEmailCodeResentMessage)));
      return true;
    } on AppFailure catch (failure) {
      if (mounted) _showFailure(failure);
      return false;
    }
  }

  void _changeAddress() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(registerControllerProvider);

    ref.listen<AuthSubmissionState>(registerControllerProvider, (previous, next) {
      switch (next) {
        case AuthSucceeded():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.registerSuccessMessage)));
          context.go(AppRoutes.home);
        case AuthFailed(:final failure):
          _showFailure(failure);
        case AuthIdle() || AuthSubmitting():
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: state.isSubmitting ? null : _changeAddress,
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
                        title: l10n.verifyEmailTitle,
                        subtitle: l10n.verifyEmailSubtitle(widget.form.email),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      EmailCodeField(
                        controller: _codeController,
                        errorText: _serverErrors['verificationCode'],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearErrors(),
                        onSubmitted: (_) => _submit(),
                      ),
                      ResendCodeButton(
                        onResend: _resend,
                        enabled: !state.isSubmitting,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_bannerMessage case final message?) ...<Widget>[
                        AuthErrorBanner(message: message),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      PrimaryButton(
                        label: l10n.verifyEmailSubmitLabel,
                        expanded: true,
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: state.isSubmitting ? null : _changeAddress,
                        child: Text(l10n.verifyEmailChangeAddressLabel),
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
