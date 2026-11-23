import 'package:flutter/widgets.dart';

import '../../../core/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../data/local_schedule_analyzer.dart';

class ScheduleFileTooLarge {
  const ScheduleFileTooLarge();
}

String scheduleError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  if (error is LocalScheduleException) {
    return switch (error.code) {
      'LOCAL_OCR_NO_TIMETABLE' => l.timetableLocalNotDetected,
      'LOCAL_OCR_AMBIGUOUS' => l.timetableLocalAmbiguous,
      'LOCAL_OCR_FILE' => l.timetableFileError,
      'LOCAL_OCR_PDF_PAGES' => l.timetablePdfPages,
      'LOCAL_OCR_MEMORY' => l.timetableLocalMemory,
      'LOCAL_OCR_BUSY' => l.timetableLocalBusy,
      _ => l.timetableLocalFailed,
    };
  }
  if (error is ScheduleFileTooLarge) return l.timetableFileSize;
  if (error is UnauthorizedFailure) return l.timetableSignIn;
  if (error is NetworkFailure || error is TimeoutFailure) {
    return l.timetableNetworkError;
  }
  final code = error is AppFailure ? error.code : null;
  return switch (code) {
    'SCHEDULE_FILE_SIZE' => l.timetableFileSize,
    'SCHEDULE_PDF_PAGES' => l.timetablePdfPages,
    'SCHEDULE_FILE_INVALID' || 'SCHEDULE_IMAGE_SIZE' => l.timetableFileError,
    'SCHEDULE_AMBIGUOUS' => l.timetableAmbiguous,
    'SCHEDULE_NOT_TIMETABLE' => l.timetableNotDetected,
    'SCHEDULE_AI_RATE_LIMIT' ||
    'SCHEDULE_IMPORT_RUNNING' ||
    'SCHEDULE_ANALYSIS_BUSY' => l.timetableRateLimit,
    'SCHEDULE_TRAVEL_REQUIRED' => l.matchPointRequired,
    'SCHEDULE_DEMO_NO_DAY' => l.demoNoUpcomingDay,
    'SCHEDULE_AI_UNAVAILABLE' ||
    'SCHEDULE_AI_TIMEOUT' ||
    'SCHEDULE_AI_INVALID' => l.timetableAiError,
    'SCHEDULE_AI_NOT_CONFIGURED' => l.timetableGeminiSetup,
    'SCHEDULE_CHANGED' => l.timetableChanged,
    'SCHEDULE_NOT_FOUND' => l.timetableNotSaved,
    'SCHEDULE_OVERLAP' => l.timetableOverlap,
    'SCHEDULE_DATES_INVALID' ||
    'SCHEDULE_TIMES_INVALID' ||
    'VALIDATION_ERROR' => l.timetableIncomplete,
    _ => l.timetableGenericError,
  };
}
