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
import '../data/dto/auth_requests.dart';
import 'auth_error_presenter.dart';
import 'auth_validators.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';

/// Registration screen.
///
/// Follows the visual language of the login mockup while adding the two extra
/// fields the backend requires (full name and optional phone number). The
/// server checks the form and emails a code; the account is only created on
/// the next screen, once that code proves the address exists.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitted = false;
  bool _sending = false;
  String? _bannerMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthValidators get _validators => AuthValidators(AppLocalizations.of(context));

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

    if (_sending || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final phone = _phoneController.text.trim();
    final form = RegisterRequestDto(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phoneNumber: phone.isEmpty ? null : phone,
    );
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).requestRegistrationCode(form);
      if (!mounted) return;
      // Pushed, so going back keeps the form filled to fix the address.
      await context.push(AppRoutes.verifyEmail, extra: form);
    } on AppFailure catch (failure) {
      if (mounted) _handleFailure(failure);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleFailure(AppFailure failure) {
    final presenter = AuthErrorPresenter(AppLocalizations.of(context));
    setState(() {
      _serverErrors = presenter.fieldErrors(failure);
      _bannerMessage = presenter.bannerMessage(failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _sending
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
                        title: l10n.registerTitle,
                        subtitle: l10n.registerSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        label: l10n.fullNameLabel,
                        controller: _fullNameController,
                        hint: l10n.fullNameHint,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const <String>[AutofillHints.name],
                        validator: _validators.fullName,
                        errorText: _serverErrors['fullName'],
                        onChanged: (_) => _clearServerErrors(),
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: l10n.emailLabel,
                        controller: _emailController,
                        hint: l10n.emailHint,
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: _validators.email,
                        errorText: _serverErrors['email'],
                        onChanged: (_) => _clearServerErrors(),
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: l10n.phoneNumberLabel,
                        controller: _phoneController,
                        hint: l10n.phoneNumberHint,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.telephoneNumber],
                        validator: _validators.phoneNumber,
                        errorText: _serverErrors['phoneNumber'],
                        onChanged: (_) => _clearServerErrors(),
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: l10n.passwordLabel,
                        controller: _passwordController,
                        hint: l10n.passwordHelper,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.newPassword],
                        validator: _validators.registerPassword,
                        errorText: _serverErrors['password'],
                        onChanged: (_) => _clearServerErrors(),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_bannerMessage case final message?) ...<Widget>[
                        AuthErrorBanner(message: message),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      PrimaryButton(
                        label: l10n.registerSubmitLabel,
                        expanded: true,
                        isLoading: _sending,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AuthFooterLink(
                        prompt: l10n.registerHasAccountPrompt,
                        action: l10n.loginLinkLabel,
                        onPressed: _sending
                            ? null
                            : () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.login);
                                }
                              },
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
