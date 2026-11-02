import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client_provider.dart';
import 'auth_api.dart';
import 'auth_repository.dart';
import 'token_storage_provider.dart';

part 'auth_repository_provider.g.dart';

/// Provides the authentication repository wired to the shared [Dio] client.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    api: AuthApi(ref.watch(dioClientProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}
