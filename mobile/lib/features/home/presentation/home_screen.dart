import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

/// Home tab. Business content is added in a later story.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.homeTitle,
      icon: Icons.home_rounded,
      message: l10n.placeholderMessage,
    );
  }
}
