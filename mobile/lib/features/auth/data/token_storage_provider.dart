import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/secure_storage_provider.dart';
import 'token_storage.dart';

part 'token_storage_provider.g.dart';

/// Provides the secure token storage used by the authentication feature.
///
/// Override it in tests with an in-memory [TokenStorage] backed by a fake
/// [FlutterSecureStorage] so no keystore access happens.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  final storage = TokenStorage(ref.watch(secureStorageProvider));
  ref.onDispose(storage.dispose);
  return storage;
}
