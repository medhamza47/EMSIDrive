import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppTab', () {
    test('follows the bottom navigation order', () {
      expect(AppTab.values, <AppTab>[
        AppTab.home,
        AppTab.rides,
        AppTab.notifications,
        AppTab.profile,
      ]);
    });

    test('resolves a tab from an exact location', () {
      expect(AppTab.fromLocation(AppRoutes.rides), AppTab.rides);
      expect(AppTab.fromLocation(AppRoutes.profile), AppTab.profile);
    });

    test('resolves a tab from a nested location', () {
      expect(AppTab.fromLocation('/rides/details/42'), AppTab.rides);
    });

    test('falls back to home for unknown locations', () {
      expect(AppTab.fromLocation('/unknown'), AppTab.home);
    });
  });

  group('Navigation shell', () {
    testWidgets('starts on the home tab with four destinations', (tester) async {
      await pumpEmsiDriveApp(tester);
      final l10n = l10nOf();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text(l10n.homeTitle), findsWidgets);
      expect(find.text(l10n.navRides), findsOneWidget);
      expect(find.text(l10n.navNotifications), findsOneWidget);
      expect(find.text(l10n.navProfile), findsOneWidget);
    });

    testWidgets('switches to the rides tab', (tester) async {
      await pumpEmsiDriveApp(tester);
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navRides));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, AppTab.rides.index);
      expect(find.text(l10n.placeholderMessage), findsOneWidget);
    });

    testWidgets('switches to the notifications tab', (tester) async {
      await pumpEmsiDriveApp(tester);
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navNotifications));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, AppTab.notifications.index);
    });

    testWidgets('switches to the profile tab and back to home', (tester) async {
      await pumpEmsiDriveApp(tester);
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navProfile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppTab.profile.index,
      );

      await tester.tap(find.text(l10n.navHome));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppTab.home.index,
      );
    });
  });
}
