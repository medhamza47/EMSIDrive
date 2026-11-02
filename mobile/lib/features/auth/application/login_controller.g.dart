// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the login form.
///
/// Auto disposed so leaving the screen discards the previous result, keeping
/// stale errors from reappearing when the user comes back.

@ProviderFor(LoginController)
final loginControllerProvider = LoginControllerProvider._();

/// Drives the login form.
///
/// Auto disposed so leaving the screen discards the previous result, keeping
/// stale errors from reappearing when the user comes back.
final class LoginControllerProvider
    extends $NotifierProvider<LoginController, AuthSubmissionState> {
  /// Drives the login form.
  ///
  /// Auto disposed so leaving the screen discards the previous result, keeping
  /// stale errors from reappearing when the user comes back.
  LoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginControllerHash();

  @$internal
  @override
  LoginController create() => LoginController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSubmissionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSubmissionState>(value),
    );
  }
}

String _$loginControllerHash() => r'2f25a24366f01642261a17f3fce10f79718df6fa';

/// Drives the login form.
///
/// Auto disposed so leaving the screen discards the previous result, keeping
/// stale errors from reappearing when the user comes back.

abstract class _$LoginController extends $Notifier<AuthSubmissionState> {
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
