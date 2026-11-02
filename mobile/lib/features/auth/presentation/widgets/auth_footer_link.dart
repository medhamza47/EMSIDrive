import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Prompt followed by a tappable link, used at the bottom of the auth screens to
/// switch between login and registration.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
  });

  /// Sentence introducing the link, for example "Pas encore de compte ?".
  final String prompt;

  /// Label of the tappable link.
  final String action;

  /// Called when the link is tapped; `null` disables it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          prompt,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
