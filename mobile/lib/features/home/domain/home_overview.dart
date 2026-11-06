import 'package:flutter/foundation.dart';

import 'upcoming_trip.dart';

/// Everything the Accueil tab needs to render its first screen.
///
/// Bundling the display name with the trips keeps the screen a pure function of
/// a single repository call instead of requiring an authentication lookup.
@immutable
class HomeOverview {
  const HomeOverview({
    required this.displayName,
    this.upcomingTrips = const <UpcomingTrip>[],
  });

  /// Name greeted in the header.
  final String displayName;

  /// Trips sorted by departure time, soonest first.
  final List<UpcomingTrip> upcomingTrips;

  /// Whether the student has no upcoming trip to display.
  bool get hasNoUpcomingTrips => upcomingTrips.isEmpty;

  @override
  bool operator ==(Object other) {
    return other is HomeOverview &&
        other.displayName == displayName &&
        listEquals(other.upcomingTrips, upcomingTrips);
  }

  @override
  int get hashCode => Object.hash(displayName, Object.hashAll(upcomingTrips));
}
