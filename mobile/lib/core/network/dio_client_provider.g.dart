// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the configured [Dio] instance used by every repository.
///
/// The client only knows about transport concerns: base URL, timeouts, JSON
/// headers and logging. Authentication and refresh handling are added later
/// through [Dio.interceptors] so features stay independent.

@ProviderFor(dioClient)
final dioClientProvider = DioClientProvider._();

/// Provides the configured [Dio] instance used by every repository.
///
/// The client only knows about transport concerns: base URL, timeouts, JSON
/// headers and logging. Authentication and refresh handling are added later
/// through [Dio.interceptors] so features stay independent.

final class DioClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Provides the configured [Dio] instance used by every repository.
  ///
  /// The client only knows about transport concerns: base URL, timeouts, JSON
  /// headers and logging. Authentication and refresh handling are added later
  /// through [Dio.interceptors] so features stay independent.
  DioClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dioClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioClientHash() => r'8eec2d05c576ae4368d77c30c152dc80cd5b758c';
