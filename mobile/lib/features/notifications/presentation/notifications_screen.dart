import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

/// Notifications tab. Business content is added in a later story.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.notificationsTitle,
      icon: Icons.notifications_rounded,
      message: l10n.placeholderMessage,
    );
  }
}
