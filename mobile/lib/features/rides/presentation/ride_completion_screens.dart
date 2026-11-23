import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int _passengers = 3;
  String _amount = '40';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = RegExp(r'^\d{1,7}([.,]\d{1,2})?$').hasMatch(_amount)
        ? double.tryParse(_amount.replaceAll(',', '.'))
        : null;
    final currency = NumberFormat.currency(locale: 'fr', symbol: 'MAD');
    return FlowPage(
      title: l.fuelTitle,
      children: [
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(l.sharePerPerson),
                Text(
                  total == null
                      ? '—'
                      : currency.format(total / (_passengers + 1)),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
        ),
        TextFormField(
          initialValue: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l.totalAmount,
            suffixText: 'MAD',
            errorText: total == null && _amount.isNotEmpty
                ? l.fuelAmountError
                : null,
          ),
          onChanged: (value) => setState(() => _amount = value.trim()),
        ),
        ListTile(title: Text(l.driverTitle), trailing: const Text('1')),
        ListTile(
          title: Text(l.passengers),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l.fuelRemovePassenger,
                onPressed: _passengers > 0
                    ? () => setState(() => _passengers--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_passengers'),
              IconButton(
                tooltip: l.fuelAddPassenger,
                onPressed: _passengers < 8
                    ? () => setState(() => _passengers++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
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
