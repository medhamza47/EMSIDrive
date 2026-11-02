import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppBottomNavBar', () {
    testWidgets('shows the four French destinations', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentTab: AppTab.home,
            onTabSelected: (_) {},
          ),
        ),
      );
      final l10n = l10nOf();

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text(l10n.navHome), findsOneWidget);
      expect(find.text(l10n.navRides), findsOneWidget);
      expect(find.text(l10n.navNotifications), findsOneWidget);
      expect(find.text(l10n.navProfile), findsOneWidget);
    });

    testWidgets('highlights the current tab', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentTab: AppTab.notifications,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppTab.notifications.index,
      );
    });

    testWidgets('reports the selected tab', (tester) async {
      final selected = <AppTab>[];

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentTab: AppTab.home,
            onTabSelected: selected.add,
          ),
        ),
      );

      await tester.tap(find.text(l10nOf().navRides));
      await tester.pump();

      expect(selected, <AppTab>[AppTab.rides]);
    });
  });
}
