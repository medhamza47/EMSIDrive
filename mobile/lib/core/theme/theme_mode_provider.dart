import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/secure_storage_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const storageKey = 'appearance.themeMode';
  int _revision = 0;
  Future<void> _writes = Future.value();

  @override
  ThemeMode build() {
    final storage = ref.watch(secureStorageProvider);
    final revision = ++_revision;
    storage
        .read(key: storageKey)
        .then((value) {
          if (!ref.mounted || revision != _revision) return;
          state =
              ThemeMode.values
                  .where((mode) => mode.name == value)
                  .firstOrNull ??
              ThemeMode.system;
        })
        .catchError((Object _) {
          /* Use the system theme if storage is unavailable. */
        });
    return ThemeMode.system;
  }

  Future<void> choose(ThemeMode mode) {
    _revision++;
    state = mode;
    final storage = ref.read(secureStorageProvider);
    final write = _writes.then(
      (_) => storage.write(key: storageKey, value: mode.name),
    );
    _writes = write.catchError((Object _) {});
    return write;
  }
}
