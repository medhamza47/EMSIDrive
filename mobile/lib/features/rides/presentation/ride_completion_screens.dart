import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';

class FuelSplitScreen extends StatefulWidget {
  const FuelSplitScreen({super.key});

  @override
  State<FuelSplitScreen> createState() => _FuelSplitScreenState();
}

class _FuelSplitScreenState extends State<FuelSplitScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FlowPage(
      title: l.fuelTitle,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.onPrimary),
            textAlign: TextAlign.center,
            child: Column(
              children: [
                Text(l.yourShare),
                Text(
                  l.amountMad(10),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(l.fuelSummary),
              ],
            ),
          ),
        ),
        SectionTitle(title: l.costBreakdown),
        FlowValue(l.totalAmount, l.amountMad(40)),
        FlowValue(l.driverTitle, '1'),
        FlowValue(l.passengers, '3'),
        FlowValue(l.sharePerPerson, l.amountMad(10)),
        SectionTitle(title: l.participants),
        for (final (name, avatar, confirmed) in [
          (l.youLabel, 'Yassine Amrani', true),
          ('Omar K.', 'Omar K.', true),
          ('Imane R.', 'Imane R.', false),
        ])
          AppCard(
            leading: Avatar(name: avatar),
            crossAxisAlignment: CrossAxisAlignment.center,
            trailing: AppBadge(
              label: confirmed ? l.tripStatusConfirmed : l.tripStatusPending,
              tone: confirmed ? AppBadgeTone.accent : AppBadgeTone.neutral,
            ),
            child: Text(name, style: theme.textTheme.titleSmall),
          ),
        PrimaryButton(
          label: _confirmed ? l.reviewTitle : l.confirmShare,
          onPressed: _confirmed
              ? () => context.push(AppRoutes.rideReview)
              : () => setState(() => _confirmed = true),
        ),
      ],
    );
  }
}

class RideReviewScreen extends StatefulWidget {
  const RideReviewScreen({super.key});

  @override
  State<RideReviewScreen> createState() => _RideReviewScreenState();
}

class _RideReviewScreenState extends State<RideReviewScreen> {
  int _rating = 4;
  final _tags = <int>{0, 1};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tags = [
      l.reviewPunctual,
      l.reviewSafe,
      l.reviewFriendly,
      l.reviewClean,
    ];
    return FlowPage(
      title: l.reviewTitle,
      children: [
        Center(child: Avatar(name: 'Salma B.', size: 64)),
        Text(
          l.reviewPrompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        Text(l.demoRoute, textAlign: TextAlign.center),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var value = 1; value <= 5; value++)
              IconButton(
                tooltip: l.ratingOutOfFive(value),
                isSelected: value <= _rating,
                icon: Icon(
                  Icons.star_outline_rounded,
                  color: theme.semanticColors.rating,
                ),
                selectedIcon: Icon(
                  Icons.star_rounded,
                  color: theme.semanticColors.rating,
                ),
                iconSize: 32,
                onPressed: () => setState(() => _rating = value),
              ),
          ],
        ),
        SectionTitle(title: l.reviewHighlights),
        Wrap(
          spacing: 8,
          children: [
            for (final (index, tag) in tags.indexed)
              FilterChip(
                label: Text(tag),
                selected: _tags.contains(index),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _tags.add(index);
                  } else {
                    _tags.remove(index);
                  }
                }),
              ),
          ],
        ),
        TextFormField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l.reviewComment,
            hintText: l.demoReviewComment,
          ),
        ),
        PrimaryButton(
          label: l.submitReview,
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.demoReviewSaved)));
            context.go(AppRoutes.rides);
          },
        ),
      ],
    );
  }
}
