import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/flow_page.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = [
      (
        Icons.add_location_alt_outlined,
        l.requestTitle,
        l.homeSearchRideSubtitle,
        AppRoutes.rideRequest,
      ),
      (
        Icons.near_me_outlined,
        l.nearbyTitle,
        l.homeSearchRideTitle,
        AppRoutes.nearbyDrivers,
      ),
      (
        Icons.calendar_month_outlined,
        l.scheduleTitle,
        l.scheduleFormats,
        AppRoutes.scheduleImport,
      ),
      (
        Icons.route_outlined,
        l.trackingTitle,
        l.demoRoute,
        AppRoutes.rideTracking,
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
