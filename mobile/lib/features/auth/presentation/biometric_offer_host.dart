import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/biometric_settings_controller.dart';
import '../data/biometric_auth.dart';
import '../data/token_storage_provider.dart';

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
    if (!ref.read(biometricOfferProvider.notifier).consume()) return;
    _offering = true;
    try {
      final tokens = ref.read(tokenStorageProvider);
      final biometrics = ref.read(biometricAuthProvider);
      final session = tokens.session;
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
      final result = await setBiometricUnlock(
        tokens,
        biometrics,
        enabled: true,
        reason: l.biometricEnableReason,
      );
      ref.invalidate(biometricSettingsProvider);
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
    ref.listen<bool>(biometricOfferProvider, (_, pending) {
      if (pending) _maybeOffer();
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
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(
                Icons.fingerprint,
                size: 48,
                color: theme.colorScheme.primary,
              ),
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
};
