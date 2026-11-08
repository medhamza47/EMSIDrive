import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/schedule/data/schedule_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage tokens;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'old',
      StorageKeys.refreshToken: 'refresh',
    });
    tokens = TokenStorage(const FlutterSecureStorage());
  });
  test(
    'missing current timetable becomes null, server errors remain errors',
    () async {
      var code = 404;
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse({
          'code': code == 404 ? 'SCHEDULE_NOT_FOUND' : 'SERVER_ERROR',
          'message': 'Failed',
        }, statusCode: code),
      );
      final repo = HttpScheduleRepository(
        AuthenticatedApi(dioWithAdapter(adapter), tokens),
      );
      expect(await repo.current(), isNull);
      code = 500;
      await expectLater(repo.current(), throwsA(isA<ApiFailure>()));
    },
  );
  test('multipart upload can retry after token refresh without reusing finalized form', () async {
    final adapter = FakeHttpAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return jsonResponse({'accessToken': 'new', 'refreshToken': 'next'});
      }
      if (options.headers['Authorization'] == 'Bearer old') {
        return jsonResponse({'message': 'Expired'}, statusCode: 401);
      }
      return jsonResponse({
        'source': 'IMAGE',
        'name': 'G1',
        'slots': [
          {
            'label': 'ERP',
            'weekday': 1,
            'startTime': '08:30',
            'endTime': '10:00',
            'campus': 'CENTRE',
            'needsReview': false,
          },
        ],
        'warnings': [],
      });
    });
    final repo = HttpScheduleRepository(
      AuthenticatedApi(dioWithAdapter(adapter), tokens),
    );
    final result = await repo.analyze(
      Uint8List.fromList([1, 2, 3]),
      'photo.jpg',
      'G1',
      4,
      CancelToken(),
    );
    expect(result.revision, 4);
    expect(result.slots.single.complete, isTrue);
    expect(await tokens.readAccessToken(), 'new');
    final uploads = adapter.requests
        .where((r) => r.path == '/schedules/analyze')
        .toList();
    expect(uploads, hasLength(2));
    expect(identical(uploads[0].data, uploads[1].data), isFalse);
    expect(uploads[1].headers['Authorization'], 'Bearer new');
  });
  test('does not expose a response arriving after sign out', () async {
    final adapter = FakeHttpAdapter((_) async {
      await tokens.clear();
      return jsonResponse({'ok': true});
    });
    final api = AuthenticatedApi(dioWithAdapter(adapter), tokens);
    await expectLater(
      api.request<Map<String, dynamic>>('GET', '/schedules/current'),
      throwsA(isA<UnauthorizedFailure>()),
    );
  });
}
