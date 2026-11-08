import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/data/session_id_provider.dart';
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
  int _generation = 0;

  @override
  HomeState build() {
    ref.watch(sessionIdProvider);
    _isLoading = false;
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    scheduleMicrotask(() {
      if (generation == _generation) reload();
    });
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
    state = const HomeLoading();
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
    final generation = _generation;
    try {
      final overview = await ref.read(homeRepositoryProvider).loadOverview();
      if (generation == _generation) {
        state = HomeLoaded(overview);
      }
    } on AppFailure catch (failure) {
      if (generation == _generation) {
        state = HomeError(failure);
      }
    } finally {
      if (generation == _generation) _isLoading = false;
    }
  }
}
