import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/biometric_link_service.dart';
import '../../data/biometric_auth.dart';
import '../../domain/biometric_link.dart';
import '../biometric_offer_host.dart';
import 'auth_header.dart';
import 'biometric_indicator.dart';

/// Login with the fingerprint for the account linked on this phone.
///
/// Shows who is signing in, the animated fingerprint badge and its status,
/// and the two ways out: the password form, or another account.
class BiometricQuickLogin extends ConsumerStatefulWidget {
  const BiometricQuickLogin({
    required this.link,
    required this.onUsePassword,
    required this.onSwitchAccount,
    required this.onUnlinked,
    this.autoPrompt = false,
    super.key,
  });

  final BiometricLink link;
  final VoidCallback onUsePassword;
  final Future<void> Function() onSwitchAccount;

  /// The server refused the link; the parent falls back to the password form.
  final ValueChanged<String> onUnlinked;

  /// Opens the system prompt as soon as the panel appears.
  final bool autoPrompt;

  @override
  ConsumerState<BiometricQuickLogin> createState() =>
      _BiometricQuickLoginState();
}

class _BiometricQuickLoginState extends ConsumerState<BiometricQuickLogin> {
  static const _successHold = Duration(milliseconds: 450);

  BiometricVisual _visual = BiometricVisual.idle;
  int _attempt = 0;
  String? _message;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _signIn();
      });
    }
  }

  Future<void> _signIn() async {
    final l = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _visual = BiometricVisual.scanning;
      _message = null;
    });
    final result = await ref
        .read(biometricLinkServiceProvider)
        .signIn(
          prompt: l.biometricSignInPrompt,
          beforeSession: () async {
            if (!mounted) return;
            setState(() => _visual = BiometricVisual.success);
            if (!reduceMotion) await Future<void>.delayed(_successHold);
          },
        );
    if (!mounted || result == BiometricResult.success) return;
    final message = biometricResultMessage(l, result);
    if (result == BiometricResult.unlinked) {
      widget.onUnlinked(message ?? l.biometricUnlinked);
      return;
    }
    setState(() {
      _attempt++;
      // Android reports failed tries inside its own prompt and only tells the
      // app "cancelled"; a gentle hint covers both a real cancel and giving up.
      _message = result == BiometricResult.cancelled
          ? l.biometricCancelledHint
          : message;
      _visual = switch (result) {
        BiometricResult.cancelled => BiometricVisual.idle,
        BiometricResult.lockedOut => BiometricVisual.lockedOut,
        BiometricResult.unavailable => BiometricVisual.unavailable,
        _ => BiometricVisual.failure,
      };
    });
  }

  Future<void> _switchAccount() async {
    final l = AppLocalizations.of(context);
    final confirmed = await confirmBiometricUnlink(
      context,
      title: l.biometricSwitchTitle,
      body: l.biometricSwitchBody(widget.link.email),
      confirm: l.biometricSwitchAccount,
    );
    if (!confirmed || !mounted) return;
    setState(() => _switching = true);
    await widget.onSwitchAccount();
    if (mounted) setState(() => _switching = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy =
        _switching ||
        _visual == BiometricVisual.scanning ||
        _visual == BiometricVisual.success;
    final canPrompt =
        !_switching &&
        (_visual == BiometricVisual.idle || _visual == BiometricVisual.failure);
    final status = switch (_visual) {
      BiometricVisual.scanning => l.biometricScanning,
      BiometricVisual.success => l.biometricUnlocked,
      BiometricVisual.idle => _message,
      _ => _message,
    };
    final isError = switch (_visual) {
      BiometricVisual.failure ||
      BiometricVisual.lockedOut ||
      BiometricVisual.unavailable => true,
      _ => false,
    };
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: l.biometricWelcomeBack(widget.link.firstName),
          subtitle: widget.link.email,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: BiometricIndicator(visual: _visual, attempt: _attempt),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: motion,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              status ?? '',
              key: ValueKey(status),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isError ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedOpacity(
          duration: motion,
          opacity: canPrompt ? 1 : 0.5,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: canPrompt ? _signIn : null,
            icon: const Icon(Icons.fingerprint),
            label: Text(l.biometricSignInButton),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: busy ? null : widget.onUsePassword,
          child: Text(l.biometricUsePassword),
        ),
        TextButton(
          onPressed: busy ? null : _switchAccount,
          child: Text(l.biometricSwitchAccount),
        ),
      ],
    );
  }
}
