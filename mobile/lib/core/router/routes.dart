/// Route paths used by the app.
///
/// Centralizing them keeps `context.go('/...')` calls free of magic strings and
/// makes deep links easy to audit.
abstract final class AppRoutes {
  // Authentication (outside the bottom navigation shell).
  static const String login = '/login';
  static const String register = '/register';

  // Shell (bottom navigation) destinations.
  static const String home = '/home';
  static const String rides = '/rides';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static const String rideRequest = '$rides/request';
  static const String rideOffer = '$rides/offer';
  static const String nearbyDrivers = '$rides/nearby';
  static const String rideTracking = '$rides/tracking';
  static const String fuelSplit = '$rides/fuel';
  static const String rideReview = '$rides/review';
  static const String scheduleImport = '$rides/schedule';
  static const String scheduleSlots = '$rides/slots';
  static const String suggestions = '$rides/suggestions';

  static String driverDetail(String driverId) => '$rides/driver/$driverId';
  static String trackingFor(String driverId) => '$rideTracking/$driverId';
  static String suggestionDetail(String driverId) => '$suggestions/$driverId';
  static String listing(String kind, String id) => '$rides/listings/$kind/$id';
  static String acceptedRide(String id) => '/trip/$id';

  /// Initial location shown when the app starts.
  ///
  /// The app boots on the login screen until session restore is implemented.
  static const String initial = login;
}

/// The four top level sections reachable from the bottom navigation bar.
enum AppTab {
  home(path: AppRoutes.home),
  rides(path: AppRoutes.rides),
  notifications(path: AppRoutes.notifications),
  profile(path: AppRoutes.profile);

  const AppTab({required this.path});

  /// Absolute route path of the tab.
  final String path;

  /// Resolves the tab matching [location], falling back to [AppTab.home].
  static AppTab fromLocation(String location) {
    for (final tab in AppTab.values) {
      if (location == tab.path || location.startsWith('${tab.path}/')) {
        return tab;
      }
    }
    return AppTab.home;
  }
}
