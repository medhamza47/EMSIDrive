import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/biometric_link_service.dart';
import '../application/biometric_settings_controller.dart';
import '../data/biometric_auth.dart';
import '../data/token_storage_provider.dart';
import 'widgets/biometric_indicator.dart';

/// Offers once, right after a password login, to unlock the app with a
/// fingerprint next time.
///
/// Lives in the tab shell rather than on the login screen: the router leaves
/// the login screen as soon as the tokens are saved, which would close a
/// dialog opened there.
class BiometricOfferHost extends ConsumerStatefulWidget {
  const BiometricOfferHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricOfferHost> createState() => _BiometricOfferHostState();
}

class _BiometricOfferHostState extends ConsumerState<BiometricOfferHost> {
  bool _offering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  Future<void> _maybeOffer() async {
    if (!mounted || _offering) return;
    final email = ref.read(biometricOfferProvider.notifier).consume();
    if (email == null) return;
    _offering = true;
    try {
      final tokens = ref.read(tokenStorageProvider);
      final biometrics = ref.read(biometricAuthProvider);
      final session = tokens.session;
      // Another account was linked on this phone: that link goes away.
      await ref.read(biometricLinkServiceProvider).unlinkIfOtherAccount(email);
      ref.invalidate(biometricLinkProvider);
      if (!mounted) return;
      if (!await biometrics.isAvailable() ||
          await tokens.readBiometricEnabled() ||
          !mounted ||
          tokens.session != session) {
        return;
      }
      final l = AppLocalizations.of(context);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (_) => const BiometricOfferDialog(),
      );
      if (accepted != true || !mounted || tokens.session != session) return;
      final result = await ref
          .read(biometricLinkServiceProvider)
          .link(prompt: l.biometricEnablePrompt);
      ref
        ..invalidate(biometricSettingsProvider)
        ..invalidate(biometricLinkProvider);
      if (!mounted) return;
      final message = biometricResultMessage(l, result, enabling: true);
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      _offering = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(biometricOfferProvider, (_, pending) {
      if (pending != null) _maybeOffer();
    });
    return widget.child;
  }
}

/// Offer dialog: primary action full width, and the "later" choice as a quiet
/// text button centered below it.
///
/// Pops `true` when accepted; `false` or `null` otherwise.
class BiometricOfferDialog extends StatelessWidget {
  const BiometricOfferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: BiometricIndicator(visual: BiometricVisual.idle, size: 96),
            ),
            const SizedBox(height: 16),
            Text(
              l.biometricOfferTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l.biometricOfferBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => navigator.pop(true),
                child: Text(l.biometricOfferAccept),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => navigator.pop(false),
              child: Text(l.biometricOfferLater),
            ),
          ],
        ),
      ),
    );
  }
}

/// French texts of the system fingerprint prompt, one set per use.
extension BiometricPrompts on AppLocalizations {
  /// Unlocking the app at startup, or signing in from the login screen.
  BiometricPromptTexts get biometricSignInPrompt => BiometricPromptTexts(
    reason: biometricSignInReason,
    title: biometricPromptTitle,
    hint: biometricPromptHint,
    cancel: biometricUsePassword,
  );

  /// Linking this phone, from the offer or the profile switch.
  BiometricPromptTexts get biometricEnablePrompt => BiometricPromptTexts(
    reason: biometricEnableReason,
    title: biometricOfferTitle,
    hint: biometricPromptHint,
    cancel: biometricCancel,
  );
}

/// Asks before unlinking the phone, so a stray tap cannot remove it.
Future<bool> confirmBiometricUnlink(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
}) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.biometricCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// User-facing message for [result], or `null` when nothing should be shown.
String? biometricResultMessage(
  AppLocalizations l,
  BiometricResult result, {
  bool enabling = false,
}) => switch (result) {
  BiometricResult.success => enabling ? l.biometricEnabledMessage : null,
  BiometricResult.cancelled => null,
  BiometricResult.lockedOut => l.biometricLockedOut,
  BiometricResult.unavailable => l.biometricUnavailable,
  BiometricResult.failed => l.biometricFailed,
  BiometricResult.unlinked => l.biometricUnlinked,
  BiometricResult.networkError => l.biometricNetworkError,
};
