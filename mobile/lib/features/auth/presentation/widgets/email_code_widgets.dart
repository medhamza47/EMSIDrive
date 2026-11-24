import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../auth_validators.dart';

/// Seconds before another code can be requested, matching the server cooldown.
const int codeResendCooldownSeconds = 60;

/// Field for a 6-digit code received by email: digits only, one-time-code
/// autofill, validated locally before reaching the server.
class EmailCodeField extends StatelessWidget {
  const EmailCodeField({
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppTextField(
      label: l10n.resetCodeLabel,
      controller: controller,
      hint: l10n.resetCodeHint,
      prefixIcon: Icons.pin_outlined,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      autofillHints: const <String>[AutofillHints.oneTimeCode],
      validator: AuthValidators(l10n).resetCode,
      errorText: errorText,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

/// "Renvoyer le code" with a countdown. The countdown starts when the button
/// appears, since a code was sent just before, and again after each resend.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({required this.onResend, this.enabled = true, super.key});

  /// Asks for a new code; returns `true` when one was sent.
  final Future<bool> Function() onResend;

  /// `false` while the screen is busy with another request.
  final bool enabled;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _remaining = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _remaining = codeResendCooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final sent = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (sent) _startCooldown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waiting = _remaining > 0;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: !widget.enabled || waiting || _sending ? null : _resend,
        child: Text(
          waiting ? l10n.resendCodeCountdown(_remaining) : l10n.resendCodeLabel,
        ),
      ),
    );
  }
}
