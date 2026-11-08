import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import 'marketplace_screens.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({this.initialTab = 1, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return FlowPage(
      title: l.navRides,
      children: [
        Text(l.ridesIntro),
        MarketplaceBoard(initialTab: initialTab),
        ExpansionTile(title:Text(l.ridesTools),tilePadding:EdgeInsets.zero,children:[
          ListTile(leading:const Icon(Icons.local_gas_station_outlined),title:Text(l.fuelTitle),onTap:()=>context.push(AppRoutes.fuelSplit)),
          ListTile(leading:const Icon(Icons.star_outline),title:Text(l.reviewTitle),onTap:()=>context.push(AppRoutes.rideReview)),
        ]),
      ],
    );
  }
}
