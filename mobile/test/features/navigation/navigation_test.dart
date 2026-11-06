import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository_provider.dart';
import 'package:emsidrive_mobile/features/home/domain/home_overview.dart';
import 'package:emsidrive_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const HomeOverview _overview = HomeOverview(displayName: 'Yassine');

class _StubHomeRepository implements HomeRepository {
  @override
  Future<HomeOverview> loadOverview() async => _overview;
}

List<Override> get _homeOverrides => <Override>[
  homeRepositoryProvider.overrideWithValue(_StubHomeRepository()),
];

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
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        overrides: _homeOverrides,
      );
      final l10n = l10nOf();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(l10n.homeGreeting), findsOneWidget);
      expect(find.text(l10n.navRides), findsOneWidget);
      expect(find.text(l10n.navNotifications), findsOneWidget);
      expect(find.text(l10n.navProfile), findsOneWidget);
    });

    testWidgets('switches to the rides tab', (tester) async {
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        overrides: _homeOverrides,
      );
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navRides));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, AppTab.rides.index);
      expect(find.text(l10n.placeholderMessage), findsOneWidget);
    });

    testWidgets('switches to the notifications tab', (tester) async {
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        overrides: _homeOverrides,
      );
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navNotifications));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, AppTab.notifications.index);
    });

    testWidgets('switches to the profile tab and back to home', (tester) async {
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        overrides: _homeOverrides,
      );
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
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
