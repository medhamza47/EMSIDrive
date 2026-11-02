import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_session.dart';

/// State of a login or register submission.
@immutable
sealed class AuthSubmissionState {
  const AuthSubmissionState();

  /// Whether a request is currently in flight.
  bool get isSubmitting => this is AuthSubmitting;

  /// The session produced by a successful submission, `null` otherwise.
  AuthSession? get session => switch (this) {
    AuthSucceeded(:final session) => session,
    _ => null,
  };

  /// The failure produced by a rejected submission, `null` otherwise.
  AppFailure? get failure => switch (this) {
    AuthFailed(:final failure) => failure,
    _ => null,
  };
}

/// Nothing submitted yet.
final class AuthIdle extends AuthSubmissionState {
  const AuthIdle();
}

/// Waiting for the API to answer.
final class AuthSubmitting extends AuthSubmissionState {
  const AuthSubmitting();
}

/// Submission accepted; [session] carries the tokens.
final class AuthSucceeded extends AuthSubmissionState {
  const AuthSucceeded(this.session);

  @override
  final AuthSession session;
}

/// Submission rejected; [failure] carries the normalized error.
final class AuthFailed extends AuthSubmissionState {
  const AuthFailed(this.failure);

  @override
  final AppFailure failure;
}
