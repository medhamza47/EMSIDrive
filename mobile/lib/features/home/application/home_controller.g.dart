// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the Accueil tab content.
///
/// Kept alive so switching tabs does not reload the overview and the scroll
/// position of the tab survives navigation.

@ProviderFor(HomeController)
final homeControllerProvider = HomeControllerProvider._();

/// Drives the Accueil tab content.
///
/// Kept alive so switching tabs does not reload the overview and the scroll
/// position of the tab survives navigation.
final class HomeControllerProvider
    extends $NotifierProvider<HomeController, HomeState> {
  /// Drives the Accueil tab content.
  ///
  /// Kept alive so switching tabs does not reload the overview and the scroll
  /// position of the tab survives navigation.
  HomeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeControllerHash();

  @$internal
  @override
  HomeController create() => HomeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeState>(value),
    );
  }
}

String _$homeControllerHash() => r'104972b8f1628afa278c974937e731b9169d3365';

/// Drives the Accueil tab content.
///
/// Kept alive so switching tabs does not reload the overview and the scroll
/// position of the tab survives navigation.

abstract class _$HomeController extends $Notifier<HomeState> {
  HomeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeState, HomeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeState, HomeState>,
              HomeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
