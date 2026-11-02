import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

/// Rides tab. Business content is added in a later story.
class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.ridesTitle,
      icon: Icons.route_rounded,
      message: l10n.placeholderMessage,
    );
  }
}
