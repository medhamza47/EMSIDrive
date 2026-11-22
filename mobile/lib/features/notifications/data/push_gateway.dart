import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotice {
  const PushNotice({
    required this.userId,
    required this.bookingId,
    required this.id,
  });
  factory PushNotice.fromData(Map<String, dynamic> data) => PushNotice(
    userId: data['user_id'] as String? ?? '',
    bookingId: data['booking_id'] as String? ?? '',
    id: data['notification_id'] as String? ?? '',
  );
  final String userId, bookingId, id;

  bool get valid {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(userId) &&
        uuid.hasMatch(bookingId) &&
        uuid.hasMatch(id);
  }
}

abstract class PushGateway {
  Future<bool> permission({bool request = false});
  Future<String?> token();
  Future<void> stop();
  Stream<String> get tokenChanges;
  Stream<PushNotice> get messages;
  Stream<PushNotice> get opened;
  Future<PushNotice?> initialNotice();
}

class FirebasePushGateway implements PushGateway {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _target;

  @override
  Future<bool> permission({bool request = false}) async {
    final settings = request
        ? await _messaging.requestPermission()
        : await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    if (_target != null) return _target;
    final registered = Completer<String>();
    final subscription = _messaging.onRegistered.listen(
      (target) {
        _target = target;
        if (!registered.isCompleted) registered.complete(target);
      },
      onError: (Object error) {
        if (!registered.isCompleted) registered.completeError(error);
      },
    );
    try {
      await _messaging.setAutoInitEnabled(true);
      await _messaging.register();
      return await registered.future.timeout(const Duration(seconds: 6));
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> stop() async {
    _target = null;
    await _messaging.setAutoInitEnabled(false);
    await _messaging.unregister();
  }

  @override
  Stream<String> get tokenChanges => _messaging.onRegistered.map((target) {
    _target = target;
    return target;
  });
  @override
  Stream<PushNotice> get messages =>
      FirebaseMessaging.onMessage.map((m) => PushNotice.fromData(m.data));
  @override
  Stream<PushNotice> get opened => FirebaseMessaging.onMessageOpenedApp.map(
    (m) => PushNotice.fromData(m.data),
  );
  @override
  Future<PushNotice?> initialNotice() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushNotice.fromData(message.data);
  }
}
