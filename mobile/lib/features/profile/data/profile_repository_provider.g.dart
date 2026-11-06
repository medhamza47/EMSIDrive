// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the [ProfileRepository] used by the Profil tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

/// Exposes the [ProfileRepository] used by the Profil tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  /// Exposes the [ProfileRepository] used by the Profil tab.
  ///
  /// Kept alive so switching tabs does not rebuild the repository. Tests override
  /// this provider to inject deterministic data.
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'4e194f1048d7894a8c860d5aa526af1e93e28bff';
