import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/avatar.dart';
import '../domain/marketplace_models.dart';

import 'package:intl/intl.dart';

class RideSummaryCard extends StatelessWidget {
  const RideSummaryCard({
    required this.path,
    required this.author,
    required this.onTap,
    this.seats,
    super.key,
  });
  final RidePath path;
  final String author;
  final int? seats;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), l = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat.MMMEd('fr').add_Hm().format(path.departure),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  if (seats != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: .5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l.seatsValue(seats!),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.trip_origin,
                    size: 17,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      path.originLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      path.destinationLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Avatar(name: author, size: 32, showBorder: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(author, style: theme.textTheme.bodyMedium),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
