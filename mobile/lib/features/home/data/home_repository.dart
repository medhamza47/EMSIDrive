import '../domain/home_overview.dart';

/// Contract of the Accueil data source.
///
/// The Fake implementation is used until the API endpoints exist; swapping it
/// for an HTTP-backed implementation only requires a new provider override.
abstract interface class HomeRepository {
  /// Loads the greeting name and the upcoming trips of the current student.
  ///
  /// Throws an [AppFailure] from `core/errors` when the data cannot be loaded.
  Future<HomeOverview> loadOverview();
}
