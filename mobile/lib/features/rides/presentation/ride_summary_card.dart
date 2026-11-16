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
    this.activeStatus,
    super.key,
  });
  final RidePath path;
  final String author;
  final int? seats;
  final String? activeStatus;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), l = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: activeStatus == null
            ? []
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .22),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Card(
        color: activeStatus == null ? null : theme.colorScheme.primaryContainer,
        shape: activeStatus == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                if (activeStatus != null)
                  Row(
                    children: [
                      Icon(
                        Icons.sensors,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeStatus!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Text(
                        l.tripFollow,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
