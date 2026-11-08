import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/saved_timetable_provider.dart';
import 'schedule_error.dart';
import 'schedule_screens.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});
  @override
  ConsumerState<PlanningScreen> createState() => _PlanningState();
}

class _PlanningState extends ConsumerState<PlanningScreen> {
  int _day = DateTime.now().weekday;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), theme = Theme.of(context);
    final schedule = ref.watch(savedTimetableProvider);
    return FlowPage(
      title: l.navPlanning,
      children: [
        Text(l.planningIntro, style: theme.textTheme.bodyMedium),
        schedule.when(
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    spacing: 16,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                      Text(
                        l.planningEmptyTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(l.planningEmptyHint, textAlign: TextAlign.center),
                      PrimaryButton(
                        label: l.planningImport,
                        icon: Icons.upload_file_outlined,
                        onPressed: () => context.push(AppRoutes.scheduleImport),
                      ),
                    ],
                  ),
                ),
              );
            }
            final slots =
                timetable.slots.where((s) => s.weekday == _day).toList()
                  ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FlowCopy(
                        timetable.name,
                        '${l.timetableFrom} ${timetable.validFrom == null ? '—' : DateFormat('dd/MM/yyyy').format(timetable.validFrom!)}',
                      ),
                    ),
                    IconButton(
                      tooltip: l.timetableEdit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        AppRoutes.scheduleSlots,
                        extra: timetable,
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 4,
                  children: [
                    for (final (index, day) in timetableDays(l).indexed)
                      Expanded(
                        child: Semantics(
                          selected: _day == index + 1,
                          child: TextButton(
                            onPressed: () => setState(() => _day = index + 1),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 48),
                              backgroundColor: _day == index + 1
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Tooltip(
                              message: day,
                              child: Text(
                                day.substring(0, 3),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _day == index + 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  timetableDays(l)[_day - 1],
                  style: theme.textTheme.titleMedium,
                ),
                if (slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l.planningFreeDay, textAlign: TextAlign.center),
                  ),
                for (final slot in slots)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${slot.startTime}\n${slot.endTime}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Text(
                                  slot.label!,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  [
                                    slot.campus == 'TARGA'
                                        ? l.campusTarga
                                        : l.campusCentre,
                                    if (slot.location?.isNotEmpty ?? false)
                                      slot.location!,
                                  ].join(' · '),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: l.searchSharedTrips,
                  icon: Icons.route_outlined,
                  onPressed: () => context.push(AppRoutes.suggestions),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.scheduleImport),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l.planningManage),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
