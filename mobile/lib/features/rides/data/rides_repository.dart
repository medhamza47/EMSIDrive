import '../domain/ride_summary.dart';

/// Access to the ride offers shown on the Trajets tab.
///
/// Throws `AppFailure` so the presentation layer can render French copy from a
/// single error taxonomy.
abstract interface class RidesRepository {
  /// Loads the rides matching the student's usual route.
  Future<List<RideSummary>> loadRides();
}
