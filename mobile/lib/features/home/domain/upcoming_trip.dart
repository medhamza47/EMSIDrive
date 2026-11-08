import 'package:flutter/foundation.dart';

/// Outcome of a ride request shown on the Accueil tab.
enum TripStatus {
  /// The driver accepted the request.
  confirmed,

  /// The request is still waiting for the driver.
  pending,
}

/// A trip the student is involved in, as summarised on the Accueil tab.
@immutable
class UpcomingTrip {
  const UpcomingTrip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.timeLabel,
    this.driverName,
    this.status = TripStatus.confirmed,
  });

  /// Stable identifier, used as list key and for future navigation.
  final String id;

  /// Departure place.
  final String origin;

  /// Arrival place.
  final String destination;

  /// Human readable departure, already formatted by the data layer
  /// (for example `Demain, 08:15`).
  final String timeLabel;

  /// Driver display name, absent while the request is pending.
  final String? driverName;

  /// Current status of the request.
  final TripStatus status;

  @override
  bool operator ==(Object other) {
    return other is UpcomingTrip &&
        other.id == id &&
        other.origin == origin &&
        other.destination == destination &&
        other.timeLabel == timeLabel &&
        other.driverName == driverName &&
        other.status == status;
  }

  @override
  int get hashCode =>
      Object.hash(id, origin, destination, timeLabel, driverName, status);
}
