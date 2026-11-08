import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_storage_provider.dart';

/// Changes only when the account changes, not during an access-token refresh.
final sessionIdProvider = Provider<int>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  void changed() => ref.invalidateSelf();
  tokens.addListener(changed);
  ref.onDispose(() => tokens.removeListener(changed));
  return tokens.session;
});
