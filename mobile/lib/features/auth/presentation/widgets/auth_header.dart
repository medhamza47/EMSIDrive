import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';

/// Branded header shared by the login and register screens.
///
/// Renders the EMSIDrive wordmark, the screen title and its subtitle, matching
/// the first mockup screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  /// Screen title, already localized.
  final String title;

  /// Supporting sentence displayed under the title.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
            child: Image.asset(
              AppAssets.logo,
              width: 220,
              fit: BoxFit.contain,
              semanticLabel: title,
            ),
          ),
        ),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
