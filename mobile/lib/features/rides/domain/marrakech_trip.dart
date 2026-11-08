import 'package:latlong2/latlong.dart';

enum EmsiCampus {
  targa(LatLng(31.6529961, -8.0603932)),
  centre(LatLng(31.6535903, -8.0214513));

  const EmsiCampus(this.point);

  final LatLng point;
}

enum CampusDirection { toCampus, fromCampus }

class MarrakechTrip {
  const MarrakechTrip({
    required this.campus,
    required this.direction,
    required this.cityPoint,
  });

  final EmsiCampus campus;
  final CampusDirection direction;
  final LatLng cityPoint;

  LatLng get origin =>
      direction == CampusDirection.toCampus ? cityPoint : campus.point;

  LatLng get destination =>
      direction == CampusDirection.toCampus ? campus.point : cityPoint;
}

class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}
