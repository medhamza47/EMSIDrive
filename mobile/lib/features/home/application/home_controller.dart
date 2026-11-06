import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_failure.dart';
import '../data/home_repository_provider.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

/// Drives the Accueil tab content.
///
/// Kept alive so switching tabs does not reload the overview and the scroll
/// position of the tab survives navigation.
@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  HomeState build() {
    ref.onDispose(() => _isDisposed = true);
    scheduleMicrotask(reload);
    return const HomeLoading();
  }

  /// Loads the content from scratch, showing skeletons while it runs.
  ///
  /// Used on first build and by the retry action of the error state.
  Future<void> reload() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    if (!_isDisposed) {
      state = const HomeLoading();
    }
    await _fetch();
  }

  /// Reloads the content without clearing what is already on screen.
  ///
  /// Backs the pull-to-refresh gesture; failures still surface as [HomeError].
  Future<void> refresh() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final overview = await ref.read(homeRepositoryProvider).loadOverview();
      if (!_isDisposed) {
        state = HomeLoaded(overview);
      }
    } on AppFailure catch (failure) {
      if (!_isDisposed) {
        state = HomeError(failure);
      }
    } finally {
      _isLoading = false;
    }
  }
}
