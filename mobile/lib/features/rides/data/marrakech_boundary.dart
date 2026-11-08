import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarrakechBoundary {
  MarrakechBoundary(this.polygons);

  final List<List<List<LatLng>>> polygons;

  static Future<MarrakechBoundary> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/maps/marrakech.geojson'),
    ) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;

    return MarrakechBoundary([
      for (final feature in features)
        [
          for (final ring
              in feature['geometry']['coordinates'] as List<dynamic>)
            [
              for (final coordinate in ring as List<dynamic>)
                LatLng(
                  (coordinate[1] as num).toDouble(),
                  (coordinate[0] as num).toDouble(),
                ),
            ],
        ],
    ]);
  }

  LatLngBounds get bounds => LatLngBounds.fromPoints([
    for (final polygon in polygons) ...polygon.first,
  ]);

  bool contains(LatLng point) => polygons.any(
    (polygon) =>
        _insideRing(point, polygon.first) &&
        !polygon.skip(1).any((hole) => _insideRing(point, hole)),
  );

  static bool _insideRing(LatLng point, List<LatLng> ring) {
    var inside = false;
    for (
      var index = 0, previous = ring.length - 1;
      index < ring.length;
      previous = index++
    ) {
      final a = ring[previous];
      final b = ring[index];
      if ((a.latitude > point.latitude) == (b.latitude > point.latitude)) {
        continue;
      }
      final crossing =
          a.longitude +
          (b.longitude - a.longitude) *
              (point.latitude - a.latitude) /
              (b.latitude - a.latitude);
      if (point.longitude < crossing) inside = !inside;
    }
    return inside;
  }
}
