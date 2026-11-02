// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the registration form.

@ProviderFor(RegisterController)
final registerControllerProvider = RegisterControllerProvider._();

/// Drives the registration form.
final class RegisterControllerProvider
    extends $NotifierProvider<RegisterController, AuthSubmissionState> {
  /// Drives the registration form.
  RegisterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerControllerHash();

  @$internal
  @override
  RegisterController create() => RegisterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSubmissionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSubmissionState>(value),
    );
  }
}

String _$registerControllerHash() =>
    r'2ff6572d54f32ad2d4d54f1b3bf988e094f198e6';

/// Drives the registration form.

abstract class _$RegisterController extends $Notifier<AuthSubmissionState> {
  AuthSubmissionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthSubmissionState, AuthSubmissionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthSubmissionState, AuthSubmissionState>,
              AuthSubmissionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
