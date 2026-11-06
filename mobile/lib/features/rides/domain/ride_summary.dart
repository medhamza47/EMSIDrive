import 'package:flutter/foundation.dart';

/// A ride offer the student can join, as listed on the Trajets tab.
@immutable
class RideSummary {
  const RideSummary({
    required this.id,
    required this.origin,
    required this.destination,
    required this.timeLabel,
    required this.seatsLeft,
    this.driverName,
  });

  /// Stable identifier of the ride offer.
  final String id;

  /// Departure place.
  final String origin;

  /// Arrival place.
  final String destination;

  /// Human readable departure, already formatted by the data layer.
  final String timeLabel;

  /// Remaining seats on the vehicle.
  final int seatsLeft;

  /// Driver display name.
  final String? driverName;

  @override
  bool operator ==(Object other) {
    return other is RideSummary &&
        other.id == id &&
        other.origin == origin &&
        other.destination == destination &&
        other.timeLabel == timeLabel &&
        other.seatsLeft == seatsLeft &&
        other.driverName == driverName;
  }

  @override
  int get hashCode =>
      Object.hash(id, origin, destination, timeLabel, seatsLeft, driverName);
}
