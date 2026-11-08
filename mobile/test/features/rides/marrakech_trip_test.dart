import 'package:emsidrive_mobile/features/rides/data/marrakech_boundary.dart';
import 'package:emsidrive_mobile/features/rides/domain/marrakech_trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both directions retain one campus and one exact city point', () {
    const point = LatLng(31.632, -8.0111);
    for (final campus in EmsiCampus.values) {
      final inbound = MarrakechTrip(
        campus: campus,
        direction: CampusDirection.toCampus,
        cityPoint: point,
      );
      final outbound = MarrakechTrip(
        campus: campus,
        direction: CampusDirection.fromCampus,
        cityPoint: point,
      );
      expect(inbound.origin, point);
      expect(inbound.destination, campus.point);
      expect(outbound.origin, campus.point);
      expect(outbound.destination, point);
    }
  });

  test('the Marrakech boundary covers both urban communes and excludes distant points', () async {
    final boundary = await MarrakechBoundary.load();
    expect(boundary.contains(const LatLng(31.632, -8.0111)), isTrue);
    expect(boundary.contains(const LatLng(31.6146, -7.9868)), isTrue);
    expect(boundary.contains(const LatLng(33.57, -7.59)), isFalse);
    for (final campus in EmsiCampus.values) {
      expect(boundary.contains(campus.point), isTrue);
    }
  });
}
