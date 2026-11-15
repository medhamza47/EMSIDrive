import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

void main() {
  for (final isDriver in [true, false]) {
    testWidgets('handles confirmed lifecycle actions for driver=$isDriver', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'test-token',
      });
      var status = 'CONFIRMED';
      final adapter = FakeHttpAdapter((options) async {
        if (options.path.endsWith('/messages')) {
          return ResponseBody.fromString(
            '[]',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('/actions/')) {
          status = switch (options.path.split('/').last) {
            'START' => 'ONGOING',
            'COMPLETE' => 'COMPLETED',
            _ => 'CANCELLED',
          };
          return jsonResponse({});
        }
        return jsonResponse({
          'id': 'demo-trip',
          'partner': 'Partenaire Demo',
          'is_driver': isDriver,
          'status': status,
          'origin_latitude': 31.632123,
          'origin_longitude': -8.011123,
          'destination_latitude': 31.6529961,
          'destination_longitude': -8.0603932,
          'origin_label': 'Marrakech',
          'destination_label': 'EMSI Marrakech Targa',
          'departure': 1794916800000,
        });
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.acceptedRide('demo-trip'),
        overrides: [
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        ],
      );
      final l = l10nOf();
      if (isDriver) {
        await tester.ensureVisible(find.text(l.rideStart));
        await tester.tap(find.text(l.rideStart));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.rideKeep));
        await tester.pumpAndSettle();
        expect(status, 'CONFIRMED');
        await tester.tap(find.text(l.rideStart));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.rideConfirm));
        await tester.pumpAndSettle();
        expect(status, 'ONGOING');
        expect(find.text(l.rideStatusOngoing), findsOneWidget);
        expect(find.text(l.rideCancelBooking), findsNothing);
        await tester.ensureVisible(find.text(l.rideComplete));
        await tester.tap(find.text(l.rideComplete));
      } else {
        expect(find.text(l.rideStart), findsNothing);
        await tester.ensureVisible(find.text(l.rideCancelBooking));
        await tester.tap(find.text(l.rideCancelBooking));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.rideConfirm));
      await tester.pumpAndSettle();
      expect(status, isDriver ? 'COMPLETED' : 'CANCELLED');
      await tester.tap(find.text(l.rideChat));
      await tester.pumpAndSettle();
      expect(find.text(l.rideReadOnlyChat), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'opens a readable chat and sends a message from an accepted trip',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'test-token',
      });
      final messages = <Map<String, Object>>[];
      final adapter = FakeHttpAdapter((options) async {
        if (options.path.endsWith('/messages')) {
          if (options.method == 'POST') {
            messages.add({
              'id': messages.length + 1,
              'body': (options.data as Map)['body'] as String,
              'mine': true,
            });
            return jsonResponse({});
          }
          final after = options.queryParameters['after'] as int? ?? 0;
          return ResponseBody.fromString(
            jsonEncode(
              messages
                  .where((message) => (message['id'] as int) > after)
                  .toList(),
            ),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return jsonResponse({
          'id': 'demo-trip',
          'partner': 'Conducteur Demo',
          'is_driver': false,
          'origin_latitude': 31.632123,
          'origin_longitude': -8.011123,
          'destination_latitude': 31.6529961,
          'destination_longitude': -8.0603932,
          'origin_label': 'Marrakech',
          'destination_label': 'EMSI Marrakech Targa',
          'departure': 1794916800000,
        });
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.acceptedRide('demo-trip'),
        overrides: [
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
        ],
      );
      final l = l10nOf();
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final colors = Theme.of(tester.element(find.byType(TabBar))).colorScheme;
      expect(tabBar.labelColor, colors.primary);
      expect(tabBar.unselectedLabelColor, colors.onSurfaceVariant);

      await tester.tap(find.text(l.rideChat));
      await tester.pumpAndSettle();
      expect(find.text(l.noChatMessages), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Je suis devant le campus.',
      );
      await tester.tap(find.byTooltip(l.sendChatMessage));
      await tester.pumpAndSettle();

      expect(find.text('Je suis devant le campus.'), findsOneWidget);
      expect(messages.single['body'], 'Je suis devant le campus.');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
