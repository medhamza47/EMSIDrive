import '../domain/home_overview.dart';
import '../domain/upcoming_trip.dart';
import 'home_repository.dart';

/// In-memory [HomeRepository] serving realistic French sample data.
///
/// Used while the ride endpoints are not wired to the mobile app. It keeps a
/// short delay so loading and pull-to-refresh states stay observable.
class FakeHomeRepository implements HomeRepository {
  const FakeHomeRepository({this.latency = const Duration(milliseconds: 600)});

  /// Simulated network latency.
  final Duration latency;

  @override
  Future<HomeOverview> loadOverview() async {
    await Future<void>.delayed(latency);
    return const HomeOverview(
      displayName: 'Yassine',
      upcomingTrips: <UpcomingTrip>[
        UpcomingTrip(
          id: 'trip-1',
          origin: 'Guéliz',
          destination: 'EMSI Marrakech',
          timeLabel: 'Demain, 08:15',
          driverName: 'Salma B.',
          status: TripStatus.confirmed,
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
  }
}
