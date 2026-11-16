import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/features/rides/domain/marketplace_models.dart';
import 'package:emsidrive_mobile/features/rides/presentation/ride_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('edits an announcement without rounding its existing pickup', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'test-token',
    });
    final listing = RideListing.fromJson({
      'id': 'edit-me',
      'author': 'Demo',
      'own': true,
      'can_accept': false,
      'can_edit': true,
      'status': 'OPEN',
      'revision': 'original-revision',
      'seats': 2,
      'vehicle_preference': 'CAR',
      'notes': 'Original notes',
      'origin_latitude': 31.632123,
      'origin_longitude': -8.011123,
      'destination_latitude': 31.6529961,
      'destination_longitude': -8.0603932,
      'origin_label': 'Marrakech',
      'destination_label': 'EMSI Marrakech Targa',
      'departure': DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch,
    }, ListingKind.offer);
    final adapter = FakeHttpAdapter(
      (options) async => ResponseBody.fromString('', 200),
    );
    await pumpWidgetWithApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    RideRequestScreen(isOffer: true, editing: listing),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
      overrides: [dioClientProvider.overrideWithValue(dioWithAdapter(adapter))],
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.text('Original notes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated notes');
    await tester.ensureVisible(find.text(l10nOf().rideSaveListing));
    await tester.tap(find.text(l10nOf().rideSaveListing));
    await tester.pumpAndSettle();
    final request = adapter.requests.singleWhere(
      (request) => request.method == 'PUT',
    );
    expect(request.method, 'PUT');
    expect(request.path, '/marketplace/listings/OFFER/edit-me');
    expect(request.data['revision'], 'original-revision');
    expect(request.data['listing']['point'], {
      'latitude': 31.632123,
      'longitude': -8.011123,
    });
    expect(request.data['listing']['campus'], 'TARGA');
    expect(request.data['listing']['seats'], 2);
    expect(request.data['listing']['notes'], 'Updated notes');
    expect(find.text('Open editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
