import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/flow_page.dart';
import 'marketplace_screens.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = [
      (
        Icons.calendar_month_outlined,
        l.scheduleTitle,
        l.scheduleFormats,
        AppRoutes.scheduleImport,
      ),
      (
        Icons.local_gas_station_outlined,
        l.fuelTitle,
        l.fuelSummary,
        AppRoutes.fuelSplit,
      ),
      (Icons.star_outline, l.reviewTitle, l.reviewPrompt, AppRoutes.rideReview),
    ];

    return FlowPage(
      title: l.navRides,
      children: [
        MarketplaceBoard(initialTab: initialTab),
        const Divider(),
        for (final (icon, title, subtitle, route) in entries)
          AppCard(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            trailing: const Icon(Icons.chevron_right),
            crossAxisAlignment: CrossAxisAlignment.center,
            onTap: () => context.push(route),
            child: FlowCopy(title, subtitle),
          ),
      ],
    );
  }
}
