import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/data/token_storage_provider.dart';
import '../data/push_gateway.dart';

final pushGatewayProvider = Provider<PushGateway?>((ref) => null);
final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    ref.watch(authenticatedApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(pushGatewayProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

enum PushStatus { unavailable, disabled, denied, enabled, error }

/// Serializes registrations so an older account cannot replace the new owner.
class PushService extends ChangeNotifier {
  PushService(this._api, this._tokens, this.gateway) {
    _tokens.addListener(_sessionChanged);
    _tokenChanges = gateway?.tokenChanges.listen(
      (_) => unawaited(synchronize()),
      onError: (Object _) => _setStatus(PushStatus.error),
    );
  }
  final AuthenticatedApi _api;
  final TokenStorage _tokens;
  final PushGateway? gateway;
  StreamSubscription<String>? _tokenChanges;
  Future<void> _operations = Future.value();
  bool _disposed = false;
  String? _registeredToken;
  String? _userId;
  PushStatus get status => gateway == null ? PushStatus.unavailable : _status;
  PushStatus _status = PushStatus.disabled;

  bool owns(PushNotice notice) => notice.valid && notice.userId == _userId;

  Future<void> markRead(String id) =>
      _api.request<void>('PUT', '/marketplace/notifications/$id/read');

  void _setStatus(PushStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  void _sessionChanged() {
    _userId = null;
    unawaited(synchronize());
  }

  Future<void> _serialize(Future<void> Function() action) {
    final operation = _operations.then((_) async {
      if (_disposed) return;
      try {
        await action();
      } catch (_) {
        _setStatus(PushStatus.error);
      }
    });
    _operations = operation;
    return operation;
  }

  Future<void> synchronize({bool enable = false}) => _serialize(() async {
    if (gateway == null) return;
    final session = _tokens.session;
    if (await _tokens.readAccessToken() == null) {
      _userId = null;
      _registeredToken = null;
      await gateway!.stop().timeout(const Duration(seconds: 3));
      return;
    }
    if (!enable && !await _tokens.readPushEnabled()) {
      _setStatus(PushStatus.disabled);
      return;
    }
    if (!await gateway!.permission(request: enable)) {
      await _unregister();
      _setStatus(PushStatus.denied);
      return;
    }
    final token = await gateway!.token().timeout(const Duration(seconds: 6));
    if (token == null || _tokens.session != session) return;
    final profile = await _api.request<Map<String, dynamic>>(
      'GET',
      '/me',
      timeout: const Duration(seconds: 5),
    );
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || _tokens.session != session) return;
    await _api.request<void>(
      'PUT',
      '/me/push-devices',
      data: {'token': token, 'refreshToken': refresh},
      timeout: const Duration(seconds: 5),
    );
    if (_tokens.session != session || _disposed) return;
    if (_registeredToken != null && _registeredToken != token) {
      await _api.request<void>(
        'DELETE',
        '/me/push-devices',
        data: {'token': _registeredToken},
        timeout: const Duration(seconds: 3),
      );
    }
    _registeredToken = token;
    _userId = profile?['id'] as String?;
    await _tokens.writePushEnabled(true);
    _setStatus(PushStatus.enabled);
  });

  Future<void> disable() => _serialize(() async {
    await _tokens.writePushEnabled(false);
    await _unregister();
    _setStatus(PushStatus.disabled);
  });

  Future<void> beforeSignOut() => _serialize(_unregister);

  Future<void> _unregister() async {
    _userId = null;
    final token = _registeredToken;
    _registeredToken = null;
    try {
      if (token != null) {
        await _api.request<void>(
          'DELETE',
          '/me/push-devices',
          data: {'token': token},
          timeout: const Duration(seconds: 3),
        );
      }
    } finally {
      await gateway?.stop().timeout(const Duration(seconds: 3));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tokens.removeListener(_sessionChanged);
    unawaited(_tokenChanges?.cancel());
    super.dispose();
  }
}
