import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Low-emphasis action drawn with an EMSI green outline.
///
/// Used for secondary choices that must stay lighter than `PrimaryButton`
/// while remaining clearly tappable.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    super.key,
  });

  /// Text displayed inside the button. Should come from the localization files.
  final String label;

  /// Callback fired on tap. The button is disabled when `null`.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Stretches the button to the full width of its parent.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final text = Text(label, overflow: TextOverflow.ellipsis);
    final content = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: text),
            ],
          );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.5),
        minimumSize: expanded ? const Size.fromHeight(52) : const Size(0, 52),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlShape,
        ),
      ),
      child: content,
    );
  }
}
