import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_semantic_colors.dart';

/// Semantic intent of an [AppBadge].
enum AppBadgeTone {
  /// EMSI light green: confirmations, active states.
  accent,

  /// EMSI dark green: neutral emphasis.
  primary,

  /// Green success tone.
  success,

  /// Amber warning tone.
  warning,

  /// Red error tone.
  error,

  /// Blue informational tone.
  info,

  /// Muted tone for inactive or draft content.
  neutral,
}

/// Compact status label, e.g. "Confirmé", "En attente", "3 places".
///
/// Colors come from the theme so light and dark modes stay readable.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.accent,
    this.icon,
    super.key,
  });

  /// Text displayed in the badge. Should come from the localization files.
  final String label;

  /// Visual intent of the badge.
  final AppBadgeTone tone;

  /// Optional leading icon rendered at 14 px.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = _colors(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.badge),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(ThemeData theme) {
    final scheme = theme.colorScheme;
    final semantic = theme.semanticColors;
    return switch (tone) {
      AppBadgeTone.accent => (scheme.secondary, scheme.onSecondary),
      AppBadgeTone.primary => (scheme.primary, scheme.onPrimary),
      AppBadgeTone.success => (semantic.successContainer, semantic.onSuccessContainer),
      AppBadgeTone.warning => (semantic.warningContainer, semantic.onWarningContainer),
      AppBadgeTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      AppBadgeTone.info => (semantic.infoContainer, semantic.onInfoContainer),
      AppBadgeTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
    };
  }
}
