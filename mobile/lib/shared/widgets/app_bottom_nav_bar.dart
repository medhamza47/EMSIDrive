import 'package:flutter/material.dart';

import '../../core/router/routes.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation bar with the four top level destinations.
///
/// Rendered by the router shell so each tab keeps its own navigation stack.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentTab,
    required this.onTabSelected,
    this.hasUnreadNotifications = false,
    super.key,
  });

  /// Tab currently displayed, derived from the active branch.
  final AppTab currentTab;

  /// Invoked with the tapped tab.
  final ValueChanged<AppTab> onTabSelected;
  final bool hasUnreadNotifications;

  /// Icons shown for each tab, in [AppTab] declaration order.
  static const Map<AppTab, ({IconData icon, IconData selectedIcon})> _icons =
      <AppTab, ({IconData icon, IconData selectedIcon})>{
        AppTab.home: (
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        AppTab.rides: (
          icon: Icons.route_outlined,
          selectedIcon: Icons.route_rounded,
        ),
        AppTab.planning: (
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        AppTab.profile: (
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget icon(AppTab tab, IconData data) => Icon(data);

    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) => onTabSelected(AppTab.values[index]),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: <Widget>[
        for (final tab in AppTab.values)
          NavigationDestination(
            icon: icon(tab, _icons[tab]!.icon),
            selectedIcon: icon(tab, _icons[tab]!.selectedIcon),
            label: _label(l10n, tab),
          ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, AppTab tab) {
    return switch (tab) {
      AppTab.home => l10n.navHome,
      AppTab.rides => l10n.navRides,
      AppTab.planning => l10n.navPlanning,
      AppTab.profile => l10n.navProfile,
    };
  }
}
