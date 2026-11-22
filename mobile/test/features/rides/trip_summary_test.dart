import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/rides/presentation/trip_summary_screen.dart';
import 'package:emsidrive_mobile/features/rides/domain/marketplace_models.dart';
import 'package:emsidrive_mobile/features/rides/data/marketplace_api.dart';
import 'package:emsidrive_mobile/features/rides/domain/marrakech_trip.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

Map<String, dynamic> completedTrip({bool driver = true}) => {
  'id': 'trip',
  'partner': 'Partenaire',
  'is_driver': driver,
  'status': 'COMPLETED',
  'origin_latitude': 31.632123,
  'origin_longitude': -8.011123,
  'destination_latitude': 31.6535903,
  'destination_longitude': -8.0214513,
  'origin_label': 'Marrakech',
  'destination_label': 'EMSI Marrakech Centre',
  'departure': 1794916800000,
  'vehicle_brand': 'Dacia',
  'vehicle_model': 'Sandero',
};

Map<String, dynamic> tripSummary({bool driver = true}) => {
  'trip': completedTrip(driver: driver),
  'duration_seconds': 900,
  'participants': [
    {'id': 'driver', 'name': 'Conducteur', 'is_driver': true, 'seats': 1},
    {'id': 'passenger', 'name': 'Passager', 'is_driver': false, 'seats': 1},
  ],
  'my_review': null,
  'costs': null,
  'shares': [],
};

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'access',
    }),
  );

  testWidgets(
    'completed trip summary submits one review and confirms a permanent cost split',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = tripSummary();
      final adapter = FakeHttpAdapter((request) async {
        if (request.path.endsWith('/summary')) return jsonResponse(data);
        if (request.method == 'PUT' && request.path.endsWith('/review')) {
          data['my_review'] = request.data;
          return jsonResponse({});
        }
        if (request.method == 'PUT' && request.path.endsWith('/costs')) {
          expect(request.data, {'total': '10.01'});
          data['costs'] = {'total_cost': 10.01, 'currency': 'MAD'};
          data['shares'] = [
            {'name': 'Conducteur', 'amount': 5.01, 'mine': true},
            {'name': 'Passager', 'amount': 5, 'mine': false},
          ];
          return jsonResponse({});
        }
        if (request.path == '/marketplace/trips/trip') {
          return jsonResponse(completedTrip());
        }
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.tripSummary('trip'),
        overrides: [
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        ],
      );
      final l = l10nOf();
      expect(find.text(l.tripDuration(15)), findsOneWidget);
      expect(find.text('Dacia · Sandero'), findsWidgets);
      await tester.tap(find.byTooltip(l.tripReviewStars(4)));
      await tester.enterText(find.byType(TextField).first, 'Très ponctuel');
      await tester.ensureVisible(find.text(l.tripReviewSubmit));
      await tester.tap(find.text(l.tripReviewSubmit));
      await tester.pumpAndSettle();
      expect(find.text(l.tripReviewSaved(4)), findsOneWidget);
      expect(find.text(l.tripReviewSubmit), findsNothing);
      await tester.enterText(find.byType(TextFormField), '-1');
      await tester.ensureVisible(find.text(l.tripCostsPublish));
      await tester.tap(find.text(l.tripCostsPublish));
      await tester.pumpAndSettle();
      expect(find.text(l.tripCostsInvalid), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '10,01');
      await tester.ensureVisible(find.text(l.tripCostsPublish));
      await tester.tap(find.text(l.tripCostsPublish));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.rideKeep));
      await tester.pumpAndSettle();
      expect(
        adapter.requests.where(
          (r) => r.method == 'PUT' && r.path.endsWith('/costs'),
        ),
        isEmpty,
      );
      await tester.tap(find.text(l.tripCostsPublish));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.rideConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l.tripCostsTotal('10.01')), findsOneWidget);
      expect(find.text('5.01 MAD'), findsOneWidget);
      expect(find.text('5.00 MAD'), findsOneWidget);
      expect(find.text(l.tripCostsPublish), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'passenger cannot publish costs and can retry a failed summary load',
    (tester) async {
      var fail = true;
      final adapter = FakeHttpAdapter((request) async {
        if (request.path.endsWith('/summary')) {
          return fail
              ? jsonResponse({}, statusCode: 503)
              : jsonResponse(tripSummary(driver: false));
        }
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      await pumpWidgetWithApp(
        tester,
        const TripSummaryScreen(id: 'trip'),
        overrides: [
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        ],
      );
      expect(find.text(l10nOf().marketplaceLoadError), findsOneWidget);
      fail = false;
      await tester.tap(find.text(l10nOf().retryLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().tripCostsWaiting), findsOneWidget);
      expect(find.text(l10nOf().tripCostsPublish), findsNothing);
    },
  );

  test('offer publication sends the selected vehicle and old records remain readable', () async {
    final adapter = FakeHttpAdapter(
      (request) async => jsonResponse({'id': 'offer'}),
    );
    final tokens = TokenStorage(const FlutterSecureStorage());
    addTearDown(tokens.dispose);
    final api = MarketplaceApi(dioWithAdapter(adapter), tokens);
    await api.publish(
      kind: ListingKind.offer,
      trip: const MarrakechTrip(
        campus: EmsiCampus.centre,
        direction: CampusDirection.toCampus,
        cityPoint: LatLng(31.63, -8.01),
      ),
      departure: DateTime.now().add(const Duration(hours: 1)),
      seats: 2,
      vehicle: 'CAR',
      notes: '',
      vehicleId: 'vehicle',
    );
    expect((adapter.requests.single.data as Map)['vehicleId'], 'vehicle');
    final legacy = completedTrip()
      ..remove('vehicle_brand')
      ..remove('vehicle_model');
    expect(AcceptedRide.fromJson(legacy).vehicleDetails, isNull);
    expect(jsonDecode(jsonEncode(completedTrip()))['vehicle_model'], 'Sandero');
  });
}
