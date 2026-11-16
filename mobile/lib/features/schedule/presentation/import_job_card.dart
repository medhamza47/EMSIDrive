import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../application/import_job_provider.dart';
import '../application/saved_timetable_provider.dart';
import '../data/schedule_repository.dart';
import 'schedule_error.dart';

class ImportJobCard extends ConsumerStatefulWidget {
  const ImportJobCard({super.key});
  @override
  ConsumerState<ImportJobCard> createState() => _ImportJobCardState();
}

class _ImportJobCardState extends ConsumerState<ImportJobCard> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(scheduleImportJobProvider)
        .when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => TextButton.icon(
            onPressed: () => ref.invalidate(scheduleImportJobProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l.importCheckStatus),
          ),
          data: (job) {
            if (job == null) return const SizedBox.shrink();
            return Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            job.pending
                                ? l.importBackgroundTitle
                                : job.draft != null
                                ? l.importReadyTitle
                                : l.importFailedTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: job.pending
                              ? l.timetableCancel
                              : l.importDismiss,
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    await ref
                                        .read(scheduleRepositoryProvider)
                                        .dismissImport(job.id);
                                    ref.invalidate(scheduleImportJobProvider);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                scheduleError(context, error),
                                              ),
                                            ),
                                          );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (job.pending) ...[
                      const LinearProgressIndicator(),
                      Text(l.importBackgroundHint),
                    ],
                    if (job.draft != null) ...[
                      Text(l.importReadyHint),
                      FilledButton(
                        onPressed: () async {
                          await context.push(
                            AppRoutes.scheduleSlots,
                            extra: job.draft,
                          );
                          if (mounted) {
                            ref.invalidate(scheduleImportJobProvider);
                            ref.invalidate(savedTimetableProvider);
                          }
                        },
                        child: Text(l.importReviewPresence),
                      ),
                    ],
                    if (!job.pending && job.draft == null) ...[
                      Text(
                        scheduleError(
                          context,
                          ApiFailure(message: '', code: job.errorCode),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.scheduleImport),
                        child: Text(l.planningImport),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
  }
}
