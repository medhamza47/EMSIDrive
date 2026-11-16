import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/saved_timetable_provider.dart';
import 'import_job_card.dart';
import 'schedule_error.dart';
import 'schedule_screens.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context), theme = Theme.of(context);
    final colors = theme.colorScheme;
    final travel = ref.watch(scheduleTravelPreferencesProvider).asData?.value;
    return FlowPage(
      title: l.navPlanning,
      children: [
        const ImportJobCard(),
        ref
            .watch(savedTimetableProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Column(
                children: [
                  Text(scheduleError(context, error)),
                  TextButton(
                    onPressed: () => ref.invalidate(savedTimetableProvider),
                    child: Text(l.retryLabel),
                  ),
                ],
              ),
              data: (timetable) {
                if (timetable == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        spacing: 18,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 56,
                            color: colors.primary,
                          ),
                          Text(
                            l.planningEmptyTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          PrimaryButton(
                            label: l.planningImport,
                            icon: Icons.upload_file_outlined,
                            onPressed: () =>
                                context.push(AppRoutes.scheduleImport),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final windows = {
                  for (final day in timetable.attendance) day.weekday: day,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryContainer,
                            colors.secondaryContainer,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: colors.onPrimaryContainer,
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                Text(
                                  timetable.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                                if (travel != null)
                                  Text(
                                    travel.campus == 'TARGA'
                                        ? l.campusTarga
                                        : l.campusCentre,
                                    style: TextStyle(
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                if (timetable.validFrom != null &&
                                    timetable.validUntil != null)
                                  Text(
                                    '${DateFormat('dd/MM').format(timetable.validFrom!)} – ${DateFormat('dd/MM').format(timetable.validUntil!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.timetableEdit,
                            onPressed: () => context.push(
                              AppRoutes.scheduleSlots,
                              extra: timetable,
                            ),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PrimaryButton(
                      label: l.planningReserve,
                      icon: Icons.directions_car_rounded,
                      onPressed: () => context.push(AppRoutes.suggestions),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.timetableDay,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            l.planningArrival,
                            style: theme.textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            l.planningLeaving,
                            style: theme.textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    for (final (index, label) in timetableDays(l).indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: windows.containsKey(index + 1)
                              ? colors.surfaceContainerLow
                              : colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DateTime.now().weekday == index + 1
                                ? colors.primary
                                : colors.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: windows.containsKey(index + 1)
                                      ? colors.onSurface
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (windows[index + 1] case final day?) ...[
                              SizedBox(
                                width: 80,
                                child: Text(
                                  day.arrival,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  day.leaving,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ] else
                              SizedBox(
                                width: 160,
                                child: Text(
                                  l.planningFreeDay,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.scheduleImport),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(l.planningReplace),
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}
