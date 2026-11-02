import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Primary call to action: filled with the EMSI dark green.
///
/// Wraps [FilledButton] so every primary action in the app shares the same
/// height, radius, loading state and icon spacing.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    super.key,
  });

  /// Text displayed inside the button. Should come from the localization files.
  final String label;

  /// Callback fired on tap. The button is disabled when `null` or when
  /// [isLoading] is `true`.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Replaces the label with a spinner and blocks further taps.
  final bool isLoading;

  /// Stretches the button to the full width of its parent.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        disabledBackgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.38),
        disabledForegroundColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: 0.6),
        minimumSize: expanded ? const Size.fromHeight(52) : const Size(0, 52),
      ),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    if (isLoading) {
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }

    final text = Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis);
    if (icon == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

/// Secondary call to action: the EMSI light green.
///
/// Used for supportive actions that must stay visually distinct from
/// [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        minimumSize: expanded ? const Size.fromHeight(52) : const Size(0, 52),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlShape),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
