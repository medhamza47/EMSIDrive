import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'http_home_repository.dart';
import '../../profile/data/profile_repository_provider.dart';
import '../../rides/data/marketplace_api.dart';
import 'home_repository.dart';

part 'home_repository_provider.g.dart';

/// Provides the Accueil data source.
///
/// Returns the Fake implementation until the ride endpoints are exposed to the
/// mobile app; tests override it to inject other fixtures or failures.
@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) {
  return HttpHomeRepository(
    ref.watch(profileRepositoryProvider),
    ref.watch(marketplaceApiProvider),
  );
}
