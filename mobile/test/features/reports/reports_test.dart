import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage_provider.dart';
import 'package:emsidrive_mobile/features/reports/data/reports_repository.dart';
import 'package:emsidrive_mobile/features/reports/presentation/report_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

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

  test('submission identifiers are distinct valid UUIDs', () {
    final ids = List.generate(100, (_) => ReportsRepository.submissionId());
    expect(ids.toSet().length, 100);
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ),
        ),
      );
    }
  });

  testWidgets('validates description and sends the selected ride context', (
    tester,
  ) async {
    tokens.dispose();
    tokens = TokenStorage(const FlutterSecureStorage());
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = FakeHttpAdapter(
      (request) async => jsonResponse({'id': 'report-1', 'status': 'OPEN'}),
    );
    await pumpWidgetWithApp(
      tester,
      const ReportScreen(contextData: {'bookingId': 'booking-1'}),
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        reportsRepositoryProvider.overrideWithValue(
          ReportsRepository(AuthenticatedApi(dioWithAdapter(adapter), tokens)),
        ),
      ],
    );
    await tester.tap(find.text(l10nOf().reportSend));
    await tester.pumpAndSettle();
    expect(find.text(l10nOf().reportRequired), findsOneWidget);
    expect(adapter.requests, isEmpty);
    await tester.enterText(
      find.byType(TextFormField),
      ' Driver absent at pickup ',
    );
    await tester.tap(find.text(l10nOf().reportSend));
    await tester.pumpAndSettle();
    expect(find.text(l10nOf().reportSent), findsOneWidget);
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.data, {
      'bookingId': 'booking-1',
      'category': 'OTHER',
      'description': 'Driver absent at pickup',
    });
  });

  testWidgets(
    'retry keeps the same identifier and payload after uncertain delivery',
    (tester) async {
      tokens.dispose();
      tokens = TokenStorage(const FlutterSecureStorage());
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var attempts = 0;
      final adapter = FakeHttpAdapter((request) async {
        if (++attempts == 1) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionTimeout,
          );
        }
        return jsonResponse({'id': 'report-2', 'status': 'OPEN'});
      });
      await pumpWidgetWithApp(
        tester,
        const ReportScreen(
          contextData: {'kind': 'REQUEST', 'listingId': 'listing-1'},
        ),
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          reportsRepositoryProvider.overrideWithValue(
            ReportsRepository(
              AuthenticatedApi(dioWithAdapter(adapter), tokens),
            ),
          ),
        ],
      );
      await tester.enterText(find.byType(TextFormField), 'Test report');
      await tester.tap(find.text(l10nOf().reportSend));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf().reportRetryHint), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.text(l10nOf().retryLabel));
      await tester.pumpAndSettle();
      expect(adapter.requests[0].path, adapter.requests[1].path);
      expect(adapter.requests[0].data, adapter.requests[1].data);
      expect(find.text(l10nOf().reportSent), findsOneWidget);
    },
  );
}
