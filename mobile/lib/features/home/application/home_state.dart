import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/home_overview.dart';

/// State of the Accueil tab content.
@immutable
sealed class HomeState {
  const HomeState();

  /// Whether the first load is still running.
  bool get isLoading => this is HomeLoading;

  /// The loaded overview, `null` while loading or after a failure.
  HomeOverview? get overview => switch (this) {
    HomeLoaded(:final overview) => overview,
    _ => null,
  };

  /// The failure that prevented the content from loading, `null` otherwise.
  AppFailure? get failure => switch (this) {
    HomeError(:final failure) => failure,
    _ => null,
  };
}

/// First load in progress, the screen shows skeletons.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Content available.
final class HomeLoaded extends HomeState {
  const HomeLoaded(this.overview);

  @override
  final HomeOverview overview;
}

/// Content could not be loaded; [failure] carries the normalized error.
final class HomeError extends HomeState {
  const HomeError(this.failure);

  @override
  final AppFailure failure;
}
