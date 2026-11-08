import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/features/auth/presentation/login_screen.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository_provider.dart';
import 'package:emsidrive_mobile/features/home/domain/home_overview.dart';
import 'package:emsidrive_mobile/features/home/presentation/home_screen.dart';
import 'package:emsidrive_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/fake_http_adapter.dart';

const HomeOverview _overview = HomeOverview(displayName: 'Yassine');

class _StubHomeRepository implements HomeRepository {
  @override
  Future<HomeOverview> loadOverview() async => _overview;
}

List<Override> get _homeOverrides => <Override>[
  homeRepositoryProvider.overrideWithValue(_StubHomeRepository()),
];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('AppTab', () {
    test('follows the bottom navigation order', () {
      expect(AppTab.values, <AppTab>[
        AppTab.home,
        AppTab.rides,
        AppTab.planning,
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
    testWidgets('starts on the home tab with four destinations', (
      tester,
    ) async {
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
      expect(find.text(l10n.navPlanning), findsOneWidget);
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
      expect(find.text(l10n.offerTitle), findsOneWidget);
    });

    testWidgets('switches to the planning tab', (tester) async {
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        overrides: _homeOverrides,
      );
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.navPlanning));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, AppTab.planning.index);
    });

    testWidgets(
      'opens notifications from the bell and returns to the current tab',
      (tester) async {
        await pumpEmsiDriveApp(
          tester,
          initialLocation: AppRoutes.home,
          overrides: _homeOverrides,
        );
        await tester.tap(find.byTooltip(l10nOf().navNotifications));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          AppTab.home.index,
        );
      },
    );

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

    testWidgets('signing out removes both tokens and returns to login', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'access-token',
        StorageKeys.refreshToken: 'refresh-token',
      });
      await pumpEmsiDriveApp(tester, initialLocation: AppRoutes.profile);

      await tester.tap(find.text(l10nOf().signOutLabel));
      await tester.pumpAndSettle();

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: StorageKeys.accessToken), isNull);
      expect(await storage.read(key: StorageKeys.refreshToken), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('publishes a request with the selected city point', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'test-token',
      });
      final adapter = FakeHttpAdapter((options) async {
        if (options.method == 'POST') {
          return jsonResponse({'id': 'test-request'});
        }
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.rideRequest,
        overrides: [
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        ],
      );
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.fromCampus));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.chooseMapPoint));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(33.57, -7.59),
      );
      await tester.pump();
      expect(find.text(l10n.pointOutsideMarrakech), findsOneWidget);

      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(31.632, -8.0111),
      );
      await tester.pump();
      await tester.tap(find.text(l10n.confirmMapPoint));
      await tester.pumpAndSettle();
      expect(find.text(l10n.changeMapPoint), findsOneWidget);

      await tester.ensureVisible(find.text(l10n.publishRequest));
      await tester.tap(find.text(l10n.publishRequest));
      await tester.pumpAndSettle();
      expect(find.text(l10n.rideRequests), findsOneWidget);
      expect(find.text(l10n.rideOffers), findsOneWidget);
      final request = adapter.requests.singleWhere(
        (request) => request.method == 'POST',
      );
      expect(request.path, '/marketplace/listings');
      expect(request.data['kind'], 'REQUEST');
      expect(request.data['toCampus'], isFalse);
      expect(request.data['point'], {'latitude': 31.632, 'longitude': -8.0111});
    });

    testWidgets('does not offer a fake timetable or analyze without a file', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpEmsiDriveApp(tester, initialLocation: AppRoutes.scheduleImport);
      final l10n = l10nOf();

      expect(find.text(l10n.searchSharedTrips), findsNothing);
      expect(find.text(l10n.timetableSignIn), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text(l10n.analyzeSchedule),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });
}
