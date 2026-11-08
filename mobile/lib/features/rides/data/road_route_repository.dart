import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../domain/marrakech_trip.dart';

class RoadRouteRepository {
  RoadRouteRepository()
    : _client = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'ROUTING_BASE_URL',
            defaultValue: 'https://router.project-osrm.org',
          ),
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
          headers: const {
            'User-Agent':
                'EMSIDrive/1.0 (https://github.com/medhamza47/EMSIDrive)',
          },
        ),
      );

  final Dio _client;

  Future<RoadRoute> calculate(MarrakechTrip trip) =>
      between(trip.origin, trip.destination);

  Future<RoadRoute> between(LatLng origin, LatLng destination) async {
    String coordinate(LatLng point) =>
        '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}';
    final start = coordinate(origin);
    final end = coordinate(destination);
    final response = await _client.get<Map<String, dynamic>>(
      '/route/v1/driving/$start;$end',
      queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
    );
    final data = response.data;
    final routes = data?['routes'] as List<dynamic>?;
    if (data?['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw const FormatException('No road route returned');
    }
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    return RoadRoute(
      points: [
        for (final coordinate in coordinates)
          LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
      ],
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  void close() => _client.close(force: true);
}
