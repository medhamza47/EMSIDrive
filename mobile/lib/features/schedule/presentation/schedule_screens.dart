import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';

class ScheduleImportScreen extends StatefulWidget {
  const ScheduleImportScreen({super.key});

  @override
  State<ScheduleImportScreen> createState() => _ScheduleImportScreenState();
}

class _ScheduleImportScreenState extends State<ScheduleImportScreen> {
  bool _hasSample = true;
  bool _isPhoto = false;

  void _selectSample({required bool photo}) {
    setState(() {
      _hasSample = true;
      _isPhoto = photo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FlowPage(
      title: l.scheduleTitle,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
          decoration: BoxDecoration(
            border: Border.all(color: colors.secondary, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: colors.secondaryContainer,
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 12),
              Text(
                l.scheduleImportTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(l.scheduleFormats, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: () => _selectSample(photo: false),
                    child: Text(l.chooseFile),
                  ),
                  OutlinedButton(
                    onPressed: () => _selectSample(photo: true),
                    child: Text(l.takePhoto),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_hasSample)
          AppCard(
            leading: Icon(
              _isPhoto ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
            ),
            crossAxisAlignment: CrossAxisAlignment.center,
            trailing: IconButton(
              tooltip: l.removeFile,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _hasSample = false),
            ),
            child: FlowCopy(
              _isPhoto ? l.demoPhotoName : l.demoPdfName,
              l.demoFileReady,
            ),
          ),
        ScheduleCallout(l.scheduleAssistant),
        PrimaryButton(
          label: l.analyzeSchedule,
          onPressed: _hasSample
              ? () => context.push(AppRoutes.scheduleSlots)
              : null,
        ),
      ],
    );
  }
}

class ScheduleSlotsScreen extends StatefulWidget {
  const ScheduleSlotsScreen({super.key});

  @override
  State<ScheduleSlotsScreen> createState() => _ScheduleSlotsScreenState();
}

class _ScheduleSlotsScreenState extends State<ScheduleSlotsScreen> {
  final _slots = {...demoSlots};
  bool _morning = true;
  bool _evening = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.slotsTitle,
      children: [
        FlowCopy(l.detectedSlots(_slots.length), l.reviewSlotsHint),
        ScheduleGrid(
          slots: _slots,
          onToggle: (index) => setState(() {
            if (!_slots.remove(index)) _slots.add(index);
          }),
        ),
        for (final (column, day, hours) in [
          (0, l.monday, l.demoMondayHours),
          (1, l.tuesday, l.demoTuesdayHours),
          (2, l.wednesday, l.demoWednesdayHours),
        ])
          if (_slots.any((slot) => slot % 5 == column)) FlowValue(day, hours),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(l.morningTrip),
              selected: _morning,
              onSelected: (selected) => setState(() => _morning = selected),
            ),
            FilterChip(
              label: Text(l.eveningTrip),
              selected: _evening,
              onSelected: (selected) => setState(() => _evening = selected),
            ),
          ],
        ),
        PrimaryButton(
          label: l.searchSharedTrips,
          onPressed: (_morning || _evening) && _slots.isNotEmpty
              ? () => context.push(AppRoutes.suggestions)
              : null,
        ),
      ],
    );
  }
}

const demoSlots = {0, 1, 3, 5, 6, 8, 22, 24, 27};

class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({
    required this.slots,
    this.driverSlots = const {},
    this.onToggle,
    super.key,
  });

  final Set<int> slots;
  final Set<int> driverSlots;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final days = [
      l.mondayShort,
      l.tuesdayShort,
      l.wednesdayShort,
      l.thursdayShort,
      l.fridayShort,
    ];
    const hours = ['08h', '10h', '12h', '14h', '16h', '18h'];
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final day in days) Center(child: Text(day)),
          ],
        ),
        for (final (row, hour) in hours.indexed)
          TableRow(
            children: [
              Text(hour, textAlign: TextAlign.center),
              for (final (column, day) in days.indexed)
                Builder(
                  builder: (context) {
                    final index = row * days.length + column;
                    final own = slots.contains(index);
                    final other = driverSlots.contains(index);
                    return Semantics(
                      label: '$day $hour',
                      selected: own || other,
                      button: onToggle != null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: onToggle == null
                              ? null
                              : () => onToggle!(index),
                          child: Ink(
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: own
                                  ? colors.primary
                                  : other
                                  ? colors.secondary
                                  : colors.surfaceContainerHigh,
                              gradient: own && other
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colors.primary,
                                        colors.secondary,
                                      ],
                                      stops: const [.5, .5],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class ScheduleCallout extends StatelessWidget {
  const ScheduleCallout(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      leading: AppBadge(label: l.aiLabel, tone: AppBadgeTone.primary),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
