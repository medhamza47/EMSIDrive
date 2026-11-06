import '../domain/ride_summary.dart';
import 'rides_repository.dart';

/// In-memory [RidesRepository] serving realistic French sample data.
///
/// Used until the ride endpoints are wired to the mobile app.
class FakeRidesRepository implements RidesRepository {
  const FakeRidesRepository({this.latency = const Duration(milliseconds: 500)});

  /// Simulated network latency.
  final Duration latency;

  @override
  Future<List<RideSummary>> loadRides() async {
    await Future<void>.delayed(latency);
    return const <RideSummary>[
      RideSummary(
        id: 'ride-1',
        origin: 'Guéliz',
        destination: 'EMSI Marrakech',
        timeLabel: 'Demain, 08:15',
        seatsLeft: 3,
        driverName: 'Salma B.',
      ),
      RideSummary(
        id: 'ride-2',
        origin: 'Massira',
        destination: 'EMSI Marrakech',
        timeLabel: 'Demain, 08:40',
        seatsLeft: 1,
        driverName: 'Omar E.',
      ),
      RideSummary(
        id: 'ride-3',
        origin: 'EMSI Marrakech',
        destination: 'Guéliz',
        timeLabel: 'Demain, 18:00',
        seatsLeft: 2,
        driverName: 'Imane R.',
      ),
    ];
  }
}
