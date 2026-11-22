import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/core/network/dio_client_provider.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage_provider.dart';
import 'package:emsidrive_mobile/features/vehicles/data/vehicles_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

ResponseBody vehicleList(List<Map<String, dynamic>> rows) =>
    ResponseBody.fromString(
      jsonEncode(rows),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late TokenStorage tokens;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'access',
      StorageKeys.refreshToken: 'refresh',
    });
    tokens = TokenStorage(const FlutterSecureStorage());
    await tokens.readAccessToken();
  });
  tearDown(() => tokens.dispose());

  testWidgets(
    'vehicle route creates, edits and confirms deletion through the HTTP API',
    (tester) async {
      tokens.dispose();
      tokens = TokenStorage(const FlutterSecureStorage());
      final stored = <Map<String, dynamic>>[];
      final adapter = FakeHttpAdapter((request) async {
        if (request.path == '/me') {
          return jsonResponse({
            'id': 'user',
            'fullName': 'Student',
            'email': 'student@emsi-edu.ma',
          });
        }
        if (request.method == 'GET') return vehicleList(stored);
        if (request.method == 'DELETE') {
          stored.clear();
          return ResponseBody.fromString('', 204);
        }
        final data = Map<String, dynamic>.from(request.data as Map);
        expect(data.containsKey('ownerId'), isFalse);
        stored.clear();
        stored.add({'id': 'vehicle-1', ...data});
        return jsonResponse(stored.single);
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.vehicles,
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
          authenticatedApiProvider.overrideWithValue(
            AuthenticatedApi(dioWithAdapter(adapter), tokens),
          ),
        ],
      );
      expect(find.text(l10nOf().vehiclesEmpty), findsOneWidget);
      await tester.tap(find.text(l10nOf().vehiclesAdd));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), ' Dacia ');
      await tester.enterText(find.byType(TextFormField).at(1), 'Sandero');
      await tester.ensureVisible(find.text(l10nOf().vehiclesSave));
      await tester.tap(find.text(l10nOf().vehiclesSave));
      await tester.pumpAndSettle();
      expect(find.text('Dacia Sandero'), findsOneWidget);
      expect(
        adapter.requests.any(
          (r) => r.method == 'POST' && r.path == '/me/vehicles',
        ),
        isTrue,
      );
      await tester.tap(find.text(l10nOf().vehiclesEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Logan');
      await tester.ensureVisible(find.text(l10nOf().vehiclesSave));
      await tester.tap(find.text(l10nOf().vehiclesSave));
      await tester.pumpAndSettle();
      expect(find.text('Dacia Logan'), findsOneWidget);
      expect(
        adapter.requests.any(
          (r) => r.method == 'PUT' && r.path == '/me/vehicles/vehicle-1',
        ),
        isTrue,
      );
      await tester.tap(find.text(l10nOf().vehiclesDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf().vehiclesCancel));
      await tester.pumpAndSettle();
      expect(stored, hasLength(1));
      await tester.tap(find.text(l10nOf().vehiclesDelete));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10nOf().vehiclesDelete),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().vehiclesEmpty), findsOneWidget);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer access');
    },
  );

  testWidgets(
    'validates required fields and preserves edits after a failed save',
    (tester) async {
      tokens.dispose();
      tokens = TokenStorage(const FlutterSecureStorage());
      var fail = true;
      final adapter = FakeHttpAdapter((request) async {
        if (request.path == '/me') {
          return jsonResponse({
            'id': 'user',
            'fullName': 'Student',
            'email': 'student@emsi-edu.ma',
          });
        }
        if (request.method == 'GET') return vehicleList([]);
        return jsonResponse({}, statusCode: fail ? 503 : 201);
      });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.vehicles,
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          dioClientProvider.overrideWithValue(dioWithAdapter(adapter)),
          authenticatedApiProvider.overrideWithValue(
            AuthenticatedApi(dioWithAdapter(adapter), tokens),
          ),
        ],
      );
      await tester.tap(find.text(l10nOf().vehiclesAdd));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10nOf().vehiclesSave));
      await tester.tap(find.text(l10nOf().vehiclesSave));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().vehiclesRequired), findsNWidgets(2));
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.enterText(find.byType(TextFormField).at(0), 'Dacia');
      await tester.enterText(find.byType(TextFormField).at(1), 'Logan');
      await tester.ensureVisible(find.text(l10nOf().vehiclesSave));
      await tester.tap(find.text(l10nOf().vehiclesSave));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().profileOperationError), findsOneWidget);
      expect(find.text('Logan'), findsOneWidget);
      fail = false;
      await tester.ensureVisible(find.text(l10nOf().vehiclesSave));
      await tester.tap(find.text(l10nOf().vehiclesSave));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().vehiclesEmpty), findsOneWidget);
    },
  );

  test('account changes discard an older pending vehicle list', () async {
    final pending = Completer<ResponseBody>();
    var loads = 0;
    final adapter = FakeHttpAdapter((request) async {
      if (loads++ == 0) return pending.future;
      return vehicleList([]);
    });
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        authenticatedApiProvider.overrideWithValue(
          AuthenticatedApi(dioWithAdapter(adapter), tokens),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(vehiclesProvider, (_, _) {});
    addTearDown(subscription.close);
    container.read(vehiclesProvider);
    await Future<void>.delayed(Duration.zero);
    await tokens.saveTokens(
      accessToken: 'other',
      refreshToken: 'other-refresh',
    );
    expect(await container.read(vehiclesProvider.future), isEmpty);
    pending.complete(
      vehicleList([
        {
          'id': 'old',
          'type': 'VOITURE',
          'brand': 'Old',
          'model': 'Car',
          'seats': 4,
        },
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(vehiclesProvider).value, isEmpty);
  });
}
