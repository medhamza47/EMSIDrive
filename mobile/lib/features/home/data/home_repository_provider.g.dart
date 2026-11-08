// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the Accueil data source.
///
/// Returns the Fake implementation until the ride endpoints are exposed to the
/// mobile app; tests override it to inject other fixtures or failures.

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

/// Provides the Accueil data source.
///
/// Returns the Fake implementation until the ride endpoints are exposed to the
/// mobile app; tests override it to inject other fixtures or failures.

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  /// Provides the Accueil data source.
  ///
  /// Returns the Fake implementation until the ride endpoints are exposed to the
  /// mobile app; tests override it to inject other fixtures or failures.
  HomeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'6008f12c11c7452711d70e8fe463c89493273ec3';
