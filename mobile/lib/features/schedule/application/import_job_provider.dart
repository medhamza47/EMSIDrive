import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/session_id_provider.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart';

/// Restores a pending/result import after navigation or an application restart.
final scheduleImportJobProvider = StreamProvider<ScheduleImportJob?>((
  ref,
) async* {
  ref.watch(sessionIdProvider);
  final repository = ref.watch(scheduleRepositoryProvider);
  var active = true;
  ref.onDispose(() => active = false);
  while (active) {
    final job = await repository.latestImport();
    if (!active) return;
    yield job;
    if (job == null || !job.pending) return;
    await Future<void>.delayed(const Duration(seconds: 3));
  }
});
