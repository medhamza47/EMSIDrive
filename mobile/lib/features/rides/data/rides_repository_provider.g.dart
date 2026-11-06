// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the [RidesRepository] used by the Trajets tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.

@ProviderFor(ridesRepository)
final ridesRepositoryProvider = RidesRepositoryProvider._();

/// Exposes the [RidesRepository] used by the Trajets tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.

final class RidesRepositoryProvider
    extends
        $FunctionalProvider<RidesRepository, RidesRepository, RidesRepository>
    with $Provider<RidesRepository> {
  /// Exposes the [RidesRepository] used by the Trajets tab.
  ///
  /// Kept alive so switching tabs does not rebuild the repository. Tests override
  /// this provider to inject deterministic data.
  RidesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ridesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ridesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RidesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RidesRepository create(Ref ref) {
    return ridesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RidesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RidesRepository>(value),
    );
  }
}

String _$ridesRepositoryHash() => r'ef4b15caa4840d5fff18f13e90d9ca7827014416';
