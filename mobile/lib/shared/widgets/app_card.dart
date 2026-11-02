import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Rounded surface used to group related content.
///
/// Provides consistent padding, radius, elevation and an optional tap handler
/// with ripple feedback. Screens should prefer this widget over raw [Card] so
/// the EMSI surface styling lives in a single place.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.trailing,
    this.leading,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// When provided, the whole card becomes tappable.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Optional widget rendered after [child] on the trailing edge.
  final Widget? trailing;

  /// Optional widget rendered before [child] on the leading edge.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: child),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
