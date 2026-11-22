import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/notifications/data/push_gateway.dart';
import 'features/notifications/application/push_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PushGateway? gateway;
  if (const bool.fromEnvironment('PUSH_ENABLED', defaultValue: true)) {
    try {
      await Firebase.initializeApp();
      gateway = FirebasePushGateway();
    } catch (_) {
      debugPrint('Push unavailable. Check the Firebase configuration.');
    }
  }
  runApp(
    ProviderScope(
      overrides: [pushGatewayProvider.overrideWithValue(gateway)],
      child: const EmsiDriveApp(),
    ),
  );
}
