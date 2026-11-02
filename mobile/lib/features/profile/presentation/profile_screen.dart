import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

/// Profile tab. Business content is added in a later story.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.profileTitle,
      icon: Icons.person_rounded,
      message: l10n.placeholderMessage,
    );
  }
}
