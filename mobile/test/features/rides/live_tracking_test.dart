import 'package:emsidrive_mobile/features/rides/data/marketplace_api.dart';
import 'package:emsidrive_mobile/features/rides/data/road_route_repository.dart';
import 'package:emsidrive_mobile/features/rides/domain/marketplace_models.dart';
import 'package:emsidrive_mobile/features/rides/domain/marrakech_trip.dart';
import 'package:emsidrive_mobile/features/rides/presentation/accepted_ride_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/pump_app.dart';

Map<String, dynamic> fixture(DateTime captured, {String stage = 'EN_ROUTE'}) =>
    {
      'id': 'booking',
      'ride_offer_id': 'offer',
      'partner': 'Conducteur test',
      'is_driver': false,
      'tracking_state': stage,
      'origin_latitude': 31.63,
      'origin_longitude': -8.01,
      'destination_latitude': 31.65,
      'destination_longitude': -8.02,
      'origin_label': 'Rendez-vous',
      'destination_label': 'EMSI Centre',
      'departure': captured.millisecondsSinceEpoch,
      'live_latitude': 31.62,
      'live_longitude': -8.015,
      'live_updated_at': captured.millisecondsSinceEpoch,
    };

class TestApi implements MarketplaceApi {
  TestApi(this.ride);
  AcceptedRide ride;
  @override
  Future<AcceptedRide> trip(String id) async => ride;
  @override
  Future<List<RideMessage>> messages(String id, [int after = 0]) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestRoutes implements RoadRouteRepository {
  LatLng? target;
  @override
  Future<RoadRoute> between(LatLng origin, LatLng destination) async {
    target = destination;
    return RoadRoute(
      points: [origin, destination],
      distanceMeters: 1200,
      durationSeconds: 240,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('calls only valid numbers for active bookings', () {
    final data = fixture(DateTime.now());
    expect(AcceptedRide.fromJson(data).callUri, isNull);
    data['partner_phone'] = '+212 612-345-678';
    expect(AcceptedRide.fromJson(data).callUri.toString(), 'tel:+212612345678');
    expect(
      AcceptedRide.fromJson(data).whatsappUri.toString(),
      'https://wa.me/212612345678',
    );
    data['partner_phone'] = '0612345678';
    expect(
      AcceptedRide.fromJson(data).whatsappUri.toString(),
      'https://wa.me/212612345678',
    );
    data['partner_phone'] = '0033612345678';
    expect(
      AcceptedRide.fromJson(data).whatsappUri.toString(),
      'https://wa.me/33612345678',
    );
    data['partner_phone'] = '*123#';
    expect(AcceptedRide.fromJson(data).callUri, isNull);
    expect(AcceptedRide.fromJson(data).whatsappUri, isNull);
    data['partner_phone'] = '+212612345678';
    data['tracking_state'] = 'COMPLETED';
    expect(AcceptedRide.fromJson(data).callUri, isNull);
  });
  test('only recent active GPS fixes are shown', () {
    final now = DateTime.now();
    expect(AcceptedRide.fromJson(fixture(now)).freshLocation(now), isNotNull);
    expect(
      AcceptedRide.fromJson(fixture(now.subtract(const Duration(seconds: 30))))
          .freshLocation(now),
      isNull,
    );
    expect(
      AcceptedRide.fromJson(fixture(now.add(const Duration(minutes: 1))))
          .freshLocation(now),
      isNull,
    );
    expect(
      AcceptedRide.fromJson(fixture(now, stage: 'COMPLETED'))
          .freshLocation(now),
      isNull,
    );
    expect(
      AcceptedRide.fromJson(fixture(now, stage: 'CANCELLED'))
          .freshLocation(now),
      isNull,
    );
  });
  for (final dark in [false, true]) {
    testWidgets(
      'tracking shows ETA and removes it when GPS expires, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = TestApi(AcceptedRide.fromJson(fixture(DateTime.now())));
        final routes = TestRoutes();
        await pumpWidgetWithApp(
          tester,
          const AcceptedRideScreen(id: 'booking'),
          dark: dark,
          overrides: [
            marketplaceApiProvider.overrideWithValue(api),
            roadRouteRepositoryProvider.overrideWithValue(routes),
          ],
        );
        expect(find.text(l10nOf().tripEtaMinutes(4)), findsOneWidget);
        expect(find.text(l10nOf().tripDriverComing), findsOneWidget);
        expect(routes.target, api.ride.path.origin);
        expect(find.byTooltip(l10nOf().tripCall), findsOneWidget);
        await tester.tap(find.byTooltip(l10nOf().tripCall));
        await tester.pump();
        expect(find.text(l10nOf().tripPhoneMissing), findsOneWidget);
        api.ride = AcceptedRide.fromJson({
          ...fixture(DateTime.now()),
          'partner_phone': '0612345678',
        });
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10nOf().tripCall));
        await tester.pumpAndSettle();
        expect(find.text(l10nOf().tripPhoneCall), findsOneWidget);
        expect(find.text(l10nOf().tripWhatsApp), findsOneWidget);
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        api.ride = AcceptedRide.fromJson(
          fixture(DateTime.now(), stage: 'IN_PROGRESS'),
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(routes.target, api.ride.path.destination);
        expect(tester.takeException(), isNull);
        api.ride = AcceptedRide.fromJson(
          fixture(DateTime.now().subtract(const Duration(minutes: 2))),
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.text(l10nOf().tripEtaMinutes(4)), findsNothing);
        expect(find.text(l10nOf().tripWaitingGps), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
