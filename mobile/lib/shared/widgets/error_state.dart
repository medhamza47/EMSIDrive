import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'outline_button.dart';

/// Centered failure state with an optional retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.title,
    this.icon = Icons.cloud_off_rounded,
    this.retryLabel,
    this.onRetry,
    super.key,
  });

  /// Human readable error message, already mapped to French.
  final String message;

  /// Optional heading displayed above [message].
  final String? title;

  /// Illustration icon.
  final IconData icon;

  /// Label of the retry button. The button is hidden when `null`.
  final String? retryLabel;

  /// Callback fired when the retry button is tapped.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: theme.colorScheme.error),
          ),
          if (title != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              title!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (retryLabel != null && onRetry != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            OutlineButton(label: retryLabel!, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
