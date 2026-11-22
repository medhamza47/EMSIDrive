import 'dart:async';

import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/notifications/application/push_service.dart';
import 'package:emsidrive_mobile/features/notifications/data/push_gateway.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

const userId = 'f458ec71-7ebf-4dac-aa70-f495d91c6591';
const notice = PushNotice(
  userId: userId,
  bookingId: 'ca5881d2-76d2-4cb8-a772-a8481b6b136d',
  id: 'cc2a3ef4-eae9-4bf2-942d-6a2039fc9d19',
);

class FakeGateway implements PushGateway {
  bool allowed = true;
  int stops = 0, prompts = 0;
  String currentToken = 'first-token';
  @override
  Future<bool> permission({bool request = false}) async {
    if (request) prompts++;
    return allowed;
  }

  @override
  Future<String?> token() async => currentToken;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Stream<String> get tokenChanges => const Stream.empty();
  @override
  Stream<PushNotice> get messages => const Stream.empty();
  @override
  Stream<PushNotice> get opened => const Stream.empty();
  @override
  Future<PushNotice?> initialNotice() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage tokens;
  late FakeGateway gateway;
  late FakeHttpAdapter adapter;
  late PushService service;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'access',
      StorageKeys.refreshToken: 'refresh',
    });
    tokens = TokenStorage(const FlutterSecureStorage());
    gateway = FakeGateway();
    adapter = FakeHttpAdapter(
      (request) async =>
          jsonResponse(request.path == '/me' ? {'id': userId} : {}),
    );
    service = PushService(
      AuthenticatedApi(dioWithAdapter(adapter), tokens),
      tokens,
      gateway,
    );
  });
  tearDown(() {
    service.dispose();
    tokens.dispose();
  });

  test('works without Firebase and does not register before consent', () async {
    final unavailable = PushService(
      AuthenticatedApi(dioWithAdapter(adapter), tokens),
      tokens,
      null,
    );
    expect(unavailable.status, PushStatus.unavailable);
    await unavailable.synchronize(enable: true);
    unavailable.dispose();
    await service.synchronize();
    expect(adapter.requests, isEmpty);
    expect(gateway.prompts, 0);
    expect(service.status, PushStatus.disabled);
  });

  test('denied permission never registers a phone', () async {
    gateway.allowed = false;
    await service.synchronize(enable: true);
    expect(service.status, PushStatus.denied);
    expect(adapter.requests, isEmpty);
    expect(gateway.prompts, 1);
  });

  test(
    'registers the current session and accepts only its validated routes',
    () async {
      await service.synchronize(enable: true);
      final registration = adapter.requests.last;
      expect(registration.path, '/me/push-devices');
      expect(registration.data, {
        'token': 'first-token',
        'refreshToken': 'refresh',
      });
      expect(service.status, PushStatus.enabled);
      expect(await tokens.readPushEnabled(), isTrue);
      expect(service.owns(notice), isTrue);
      expect(
        service.owns(
          const PushNotice(
            userId: userId,
            bookingId: '../../login',
            id: 'invalid',
          ),
        ),
        isFalse,
      );
      expect(
        service.owns(
          const PushNotice(
            userId: '3fb3cc23-69b2-46c8-a707-21eb7827da7b',
            bookingId: 'ca5881d2-76d2-4cb8-a772-a8481b6b136d',
            id: 'cc2a3ef4-eae9-4bf2-942d-6a2039fc9d19',
          ),
        ),
        isFalse,
      );
    },
  );

  test('unregisters on logout while keeping the device preference', () async {
    await service.synchronize(enable: true);
    await service.beforeSignOut();
    expect(adapter.requests.last.method, 'DELETE');
    expect(service.owns(notice), isFalse);
    expect(gateway.stops, 1);
    expect(await tokens.readPushEnabled(), isTrue);
  });

  test('disabling notifications persists and unregisters the device', () async {
    await service.synchronize(enable: true);
    await service.disable();
    expect(service.status, PushStatus.disabled);
    expect(await tokens.readPushEnabled(), isFalse);
    expect(adapter.requests.last.method, 'DELETE');
  });

  test('registers a replacement token before removing the old token', () async {
    await service.synchronize(enable: true);
    gateway.currentToken = 'replacement-token';
    await service.synchronize();
    expect(adapter.requests[adapter.requests.length - 2].data, {
      'token': 'replacement-token',
      'refreshToken': 'refresh',
    });
    expect(adapter.requests.last.data, {'token': 'first-token'});
  });

  test('a failed registration can be retried', () async {
    var failed = true;
    adapter = FakeHttpAdapter(
      (request) async => request.path == '/me/push-devices' && failed
          ? jsonResponse({}, statusCode: 503)
          : jsonResponse({'id': userId}),
    );
    service.dispose();
    service = PushService(
      AuthenticatedApi(dioWithAdapter(adapter), tokens),
      tokens,
      gateway,
    );
    await service.synchronize(enable: true);
    expect(service.status, PushStatus.error);
    failed = false;
    await service.synchronize(enable: true);
    expect(service.status, PushStatus.enabled);
  });

  test('a late response cannot bind a signed-out account', () async {
    final started = Completer<void>(), release = Completer<void>();
    adapter = FakeHttpAdapter((request) async {
      if (request.path == '/me') {
        started.complete();
        await release.future;
      }
      return jsonResponse({'id': userId});
    });
    service.dispose();
    service = PushService(
      AuthenticatedApi(dioWithAdapter(adapter), tokens),
      tokens,
      gateway,
    );
    final pending = service.synchronize(enable: true);
    await started.future;
    await tokens.clear();
    release.complete();
    await pending;
    await service.synchronize();
    expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(service.owns(notice), isFalse);
  });
}
