import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_failure.dart';
import '../data/auth_repository_provider.dart';
import 'auth_submission_state.dart';

part 'register_controller.g.dart';

/// Drives the registration form.
@riverpod
class RegisterController extends _$RegisterController {
  @override
  AuthSubmissionState build() => const AuthIdle();

  /// Creates the account. Errors are swallowed into [AuthFailed] so the screen
  /// only has to watch the state.
  Future<void> submit({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    if (state.isSubmitting) {
      return;
    }
    state = const AuthSubmitting();
    try {
      final session = await ref.read(authRepositoryProvider).register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
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
