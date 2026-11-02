// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the secure token storage used by the authentication feature.
///
/// Override it in tests with an in-memory [TokenStorage] backed by a fake
/// [FlutterSecureStorage] so no keystore access happens.

@ProviderFor(tokenStorage)
final tokenStorageProvider = TokenStorageProvider._();

/// Provides the secure token storage used by the authentication feature.
///
/// Override it in tests with an in-memory [TokenStorage] backed by a fake
/// [FlutterSecureStorage] so no keystore access happens.

final class TokenStorageProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  /// Provides the secure token storage used by the authentication feature.
  ///
  /// Override it in tests with an in-memory [TokenStorage] backed by a fake
  /// [FlutterSecureStorage] so no keystore access happens.
  TokenStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageHash();

  @$internal
  @override
  $ProviderElement<TokenStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStorage create(Ref ref) {
    return tokenStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorage>(value),
    );
  }
}

String _$tokenStorageHash() => r'2a6ca82cc149e733a5b0935df6408cb72c21f538';
