import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../../rides/data/demo_drivers.dart';
import '../../schedule/presentation/schedule_screens.dart';

class _DemoSuggestion {
  const _DemoSuggestion(
    this.driverId,
    this.score,
    this.commonCount,
    this.driverSlots,
  );

  final String driverId;
  final int score;
  final int commonCount;
  final Set<int> driverSlots;

  static const all = [
    _DemoSuggestion('salma', 92, 5, {0, 1, 5, 13, 22, 24, 27, 29}),
    _DemoSuggestion('omar', 85, 4, {0, 1, 3, 8, 12}),
    _DemoSuggestion('imane', 74, 3, {21, 22, 24, 27}),
    _DemoSuggestion('anas', 61, 2, {1, 6, 11}),
  ];
}

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slots = [
      [l.mondayMorning, l.tuesdayMorning, l.wednesdayEvening],
      [l.mondayMorning, l.thursdayMorning],
      [l.wednesdayEvening, l.fridayEvening],
      [l.tuesdayMorning],
    ];

    return FlowPage(
      title: l.suggestionsTitle,
      children: [
        ScheduleCallout(l.suggestionsIntro),
        for (final (index, suggestion) in _DemoSuggestion.all.indexed)
          Builder(
            builder: (context) {
              final driver = DemoDriver.find(suggestion.driverId);
              final vehicle = driver.isMotorcycle
                  ? l.vehicleMotorcycle
                  : l.vehicleCar;
              void open() =>
                  context.push(AppRoutes.suggestionDetail(driver.id));
              return AppCard(
                leading: _MatchScore(suggestion.score),
                onTap: open,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlowCopy(
                      '${driver.name} - $vehicle',
                      l.commonSlots(suggestion.commonCount),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final slot in slots[index])
                          AppBadge(label: slot, tone: AppBadgeTone.neutral),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: open,
                        child: Text(l.proposeAction),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class SuggestionDetailScreen extends StatelessWidget {
  const SuggestionDetailScreen({required this.driver, super.key});

  final DemoDriver driver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final suggestion = _DemoSuggestion.all.firstWhere(
      (item) => item.driverId == driver.id,
    );
    final vehicle = driver.isMotorcycle ? l.vehicleMotorcycle : l.vehicleCar;
    final number = NumberFormat.decimalPattern('fr');
    final days = [l.monday, l.tuesday, l.wednesday, l.thursday, l.friday];

    return FlowPage(
      title: l.compatibilityTitle,
      children: [
        AppCard(
          leading: _MatchScore(suggestion.score),
          child: FlowCopy(
            '${driver.name} - $vehicle',
            l.suggestionDriverSummary(
              driver.major,
              number.format(driver.distance),
            ),
          ),
        ),
        ScheduleGrid(slots: demoSlots, driverSlots: suggestion.driverSlots),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final (label, first, second) in [
              (l.yourClasses, colors.primary, colors.primary),
              (l.driverClasses, colors.secondary, colors.secondary),
              (l.sharedClasses, colors.primary, colors.secondary),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [first, second],
                        stops: const [.5, .5],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
          ],
        ),
        for (final (index, day) in days.indexed)
          if (suggestion.driverSlots
              .intersection(demoSlots)
              .any((slot) => slot % 5 == index))
            FlowValue(
              day,
              index == 2 || index == 4
                  ? l.matchEveningTime
                  : index == 0 && driver.id == 'salma'
                  ? l.matchRoundTrip
                  : l.matchMorningTime(driver.time),
            ),
        FlowValue(l.fuelPerTrip, l.amountMad(driver.fare)),
        PrimaryButton(
          label: l.proposeCarpool,
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.demoProposalSaved)));
            context.go(AppRoutes.notifications);
          },
        ),
        OutlineButton(
          label: l.ignoreSuggestion,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.suggestions),
        ),
      ],
    );
  }
}

class _MatchScore extends StatelessWidget {
  const _MatchScore(this.score);

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = NumberFormat.percentPattern('fr').format(score / 100);
    return SizedBox.square(
      dimension: 57,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: colors.surfaceContainerHigh,
              color: colors.primary,
              semanticsLabel: AppLocalizations.of(context).compatibilityTitle,
              semanticsValue: value,
            ),
          ),
          ExcludeSemantics(
            child: Text(value, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}
