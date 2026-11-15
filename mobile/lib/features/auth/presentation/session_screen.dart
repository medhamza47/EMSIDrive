import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import '../data/biometric_auth.dart';
import 'biometric_offer_host.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// The system prompt opens by itself only once per lock; afterwards the
  /// user taps the button, so a cancel does not reopen it in a loop.
  bool _autoPrompted = false;
  String? _unlockError;

  late final SessionController _controller = ref.read(
    sessionControllerProvider,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_statusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _statusChanged());
  }

  @override
  void dispose() {
    _controller.removeListener(_statusChanged);
    super.dispose();
  }

  void _statusChanged() {
    if (!mounted) return;
    if (_controller.status != SessionStatus.locked) {
      _autoPrompted = false;
      return;
    }
    if (_autoPrompted) return;
    _autoPrompted = true;
    _unlock();
  }

  Future<void> _unlock() async {
    final l = AppLocalizations.of(context);
    setState(() => _unlockError = null);
    final result = await _controller.unlock(l.biometricUnlockReason);
    if (!mounted || result == BiometricResult.success) return;
    setState(() => _unlockError = biometricResultMessage(l, result));
  }

  Future<void> _signOut(AppLocalizations l) async {
    try {
      await _controller.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.signOutError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(sessionControllerProvider);
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  ...switch (controller.status) {
                    SessionStatus.unavailable => [
                      Text(
                        l.sessionRestoreUnavailable,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.restore,
                        child: Text(l.sessionRetry),
                      ),
                      TextButton(
                        onPressed: () => _signOut(l),
                        child: Text(l.sessionUseAnotherAccount),
                      ),
                    ],
                    SessionStatus.locked => [
                      Icon(
                        Icons.fingerprint,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.biometricLockedTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l.biometricLockedBody, textAlign: TextAlign.center),
                      if (_unlockError case final error?) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _unlock,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l.biometricUnlockButton),
                      ),
                      TextButton(
                        onPressed: () => _signOut(l),
                        child: Text(l.biometricUsePassword),
                      ),
                    ],
                    _ => [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l.sessionRestoring),
                    ],
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
