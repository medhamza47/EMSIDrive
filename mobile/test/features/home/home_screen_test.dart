import 'dart:async';

import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository_provider.dart';
import 'package:emsidrive_mobile/features/home/domain/home_overview.dart';
import 'package:emsidrive_mobile/features/home/domain/upcoming_trip.dart';
import 'package:emsidrive_mobile/features/rides/presentation/ride_request_screen.dart';
import 'package:emsidrive_mobile/shared/widgets/avatar.dart';
import 'package:emsidrive_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const HomeOverview _overview = HomeOverview(
  displayName: 'Yassine',
  upcomingTrips: <UpcomingTrip>[
    UpcomingTrip(
      id: 'trip-1',
      origin: 'Guéliz',
      destination: 'EMSI Marrakech',
      timeLabel: 'Demain, 08:15',
      driverName: 'Salma B.',
    ),
    UpcomingTrip(
      id: 'trip-2',
      origin: 'EMSI Marrakech',
      destination: 'Massira',
      timeLabel: 'Jeudi, 17:30',
      status: TripStatus.pending,
    ),
  ],
);

void main() {
  group('HomeScreen content', () {
    testWidgets('greets the student and shows both actions', (tester) async {
      await _pumpHome(tester, _StubHomeRepository());
      final l10n = l10nOf();

      expect(find.text(l10n.homeGreeting), findsOneWidget);
      expect(find.text('Yassine'), findsOneWidget);
      expect(find.byType(Avatar), findsOneWidget);

      expect(find.text(l10n.homeSearchRideTitle), findsOneWidget);
      expect(find.text(l10n.homeSearchRideSubtitle), findsOneWidget);
      expect(find.text(l10n.homeOfferRideTitle), findsOneWidget);
      expect(find.text(l10n.homeOfferRideSubtitle), findsOneWidget);
    });

    testWidgets('lists the upcoming trips with their status', (tester) async {
      await _pumpHome(tester, _StubHomeRepository());
      final l10n = l10nOf();

      expect(find.text(l10n.homeUpcomingTripsTitle), findsOneWidget);
      expect(
        find.text(l10n.homeTripRoute('Guéliz', 'EMSI Marrakech')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.homeTripWithDriver('Demain, 08:15', 'Salma B.')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.homeTripRoute('EMSI Marrakech', 'Massira')),
        findsOneWidget,
      );
      expect(find.text(l10n.homeTripPending('Jeudi, 17:30')), findsOneWidget);

      expect(find.text(l10n.tripStatusConfirmed), findsOneWidget);
      expect(find.text(l10n.tripStatusPending), findsOneWidget);
    });

    testWidgets('invites the student to ride when there is no trip', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        _StubHomeRepository(
          overview: const HomeOverview(displayName: 'Yassine'),
        ),
      );
      final l10n = l10nOf();

      expect(find.text(l10n.homeNoUpcomingTripsTitle), findsOneWidget);
      expect(find.text(l10n.homeNoUpcomingTripsMessage), findsOneWidget);
      expect(find.text(l10n.tripStatusConfirmed), findsNothing);
    });
  });

  group('HomeScreen states', () {
    testWidgets('shows skeletons until the overview arrives', (tester) async {
      final repository = _PendingHomeRepository();
      final l10n = l10nOf();

      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.home,
        settle: false,
        overrides: <Override>[
          homeRepositoryProvider.overrideWithValue(repository),
        ],
      );

      expect(find.byType(SkeletonLoader), findsWidgets);
      expect(find.text(l10n.homeSearchRideTitle), findsNothing);

      repository.resolve(_overview);
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonLoader), findsNothing);
      expect(find.text(l10n.homeSearchRideTitle), findsOneWidget);
    });

    testWidgets('shows the error state and recovers on retry', (tester) async {
      final repository = _StubHomeRepository(failingCalls: 1);
      await _pumpHome(tester, repository);
      final l10n = l10nOf();

      expect(find.text(l10n.homeErrorTitle), findsOneWidget);
      expect(find.text(l10n.networkErrorMessage), findsOneWidget);
      expect(find.text(l10n.retryLabel), findsOneWidget);
      expect(find.text(l10n.homeSearchRideTitle), findsNothing);

      await tester.tap(find.text(l10n.retryLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.homeErrorTitle), findsNothing);
      expect(find.text(l10n.homeSearchRideTitle), findsOneWidget);
      expect(repository.callCount, 2);
    });

    testWidgets('maps a timeout failure to the French timeout message', (
      tester,
    ) async {
      final repository = _StubHomeRepository(
        failingCalls: 1,
        failure: const TimeoutFailure(message: 'timeout'),
      );
      await _pumpHome(tester, repository);
      final l10n = l10nOf();

      expect(find.text(l10n.homeErrorTitle), findsOneWidget);
      expect(find.text(l10n.timeoutErrorMessage), findsOneWidget);
      expect(find.text(l10n.networkErrorMessage), findsNothing);
    });
  });

  group('HomeScreen interactions', () {
    testWidgets('opens the request form in the rides tab', (tester) async {
      await _pumpHome(tester, _StubHomeRepository());
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.homeSearchRideTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestTitle), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppTab.rides.index,
      );
    });

    testWidgets('opens the ride offer form', (tester) async {
      await _pumpHome(tester, _StubHomeRepository());
      final l10n = l10nOf();

      await tester.tap(find.text(l10n.homeOfferRideTitle));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<RideRequestScreen>(find.byType(RideRequestScreen))
            .isOffer,
        isTrue,
      );
      expect(find.text(l10n.offerTitle), findsOneWidget);
    });

    testWidgets('reloads the overview on pull to refresh', (tester) async {
      final repository = _StubHomeRepository();
      await _pumpHome(tester, repository);
      expect(repository.callCount, 1);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(repository.callCount, 2);
      expect(find.text(l10nOf().homeSearchRideTitle), findsOneWidget);
    });
  });
}

Future<void> _pumpHome(WidgetTester tester, HomeRepository repository) {
  return pumpEmsiDriveApp(
    tester,
    initialLocation: AppRoutes.home,
    overrides: <Override>[homeRepositoryProvider.overrideWithValue(repository)],
  );
}

/// Serves a canned overview and can fail its first calls.
class _StubHomeRepository implements HomeRepository {
  _StubHomeRepository({
    this.overview = _overview,
    this.failingCalls = 0,
    this.failure = const NetworkFailure(message: 'offline'),
  });

  final HomeOverview overview;

  /// Number of leading calls that throw [failure].
  final int failingCalls;

  final AppFailure failure;

  /// Number of times [loadOverview] has been called.
  int callCount = 0;

  @override
  Future<HomeOverview> loadOverview() async {
    callCount++;
    if (callCount <= failingCalls) {
      throw failure;
    }
    return overview;
  }
}

/// Keeps the first load pending until [resolve] is called.
class _PendingHomeRepository implements HomeRepository {
  final Completer<HomeOverview> _completer = Completer<HomeOverview>();

  void resolve(HomeOverview overview) => _completer.complete(overview);

  @override
  Future<HomeOverview> loadOverview() => _completer.future;
}
