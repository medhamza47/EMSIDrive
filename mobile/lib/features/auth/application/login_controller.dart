import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_failure.dart';
import '../data/auth_repository_provider.dart';
import 'auth_submission_state.dart';

part 'login_controller.g.dart';

/// Drives the login form.
///
/// Auto disposed so leaving the screen discards the previous result, keeping
/// stale errors from reappearing when the user comes back.
@riverpod
class LoginController extends _$LoginController {
  @override
  AuthSubmissionState build() => const AuthIdle();

  /// Submits the credentials. Errors are swallowed into [AuthFailed] so the
  /// screen only has to watch the state.
  Future<void> submit({required String email, required String password}) async {
    if (state.isSubmitting) {
      return;
    }
    state = const AuthSubmitting();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AuthSucceeded(session);
    } on AppFailure catch (failure) {
      state = AuthFailed(failure);
    }
  }

  /// Clears the last result, called when the user edits the form again.
  void reset() {
    if (state is! AuthIdle) {
      state = const AuthIdle();
    }
  }
}
