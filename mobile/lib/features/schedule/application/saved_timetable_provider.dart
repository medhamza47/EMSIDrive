import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/session_id_provider.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart';

final savedTimetableProvider = FutureProvider.autoDispose<Timetable?>((ref) {
  ref.watch(sessionIdProvider);
  return ref.watch(scheduleRepositoryProvider).current();
});
