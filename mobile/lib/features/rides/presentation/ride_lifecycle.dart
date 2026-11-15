import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

String rideStatusLabel(AppLocalizations l, String status) => switch (status) {
  'OPEN' => l.rideStatusOpen,
  'FULL' => l.rideStatusFull,
  'PENDING' => l.tripStatusPending,
  'MATCHED' => l.rideStatusMatched,
  'CONFIRMED' => l.tripStatusConfirmed,
  'ONGOING' => l.rideStatusOngoing,
  'COMPLETED' => l.rideStatusCompleted,
  'CANCELLED' => l.rideStatusCancelled,
  _ => l.rideStatusExpired,
};

Future<bool> confirmRideAction(BuildContext context, String message) async {
  final l = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.rideConfirmAction),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.rideKeep),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.rideConfirm),
            ),
          ],
        ),
      ) ??
      false;
}
