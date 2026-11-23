import 'dart:async';

import 'package:emsidrive_mobile/core/network/secure_storage_provider.dart';
import 'package:emsidrive_mobile/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedThemeStorage extends FlutterSecureStorage {
  final pending = Completer<String?>();
  String? saved;
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => pending.future;
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    saved = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a theme selection persists and is restored in a new app session',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = ProviderContainer();
      first.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      await first.read(themeModeProvider.notifier).choose(ThemeMode.dark);
      expect(first.read(themeModeProvider), ThemeMode.dark);
      first.dispose();
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      restored.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(restored.read(themeModeProvider), ThemeMode.dark);
    },
  );
  test('a late stored preference cannot override a new selection', () async {
    final storage = DelayedThemeStorage();
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider);
    await container.read(themeModeProvider.notifier).choose(ThemeMode.dark);
    storage.pending.complete('light');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(storage.saved, 'dark');
  });
}
