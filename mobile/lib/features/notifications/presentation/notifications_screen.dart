import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? _accepted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final notifications = [
      (l.proposalNotification, l.proposalNotificationBody),
      (l.acceptedNotification, l.acceptedNotificationBody),
      (l.matchNotification, l.matchNotificationBody),
      (l.reminderNotification, l.reminderNotificationBody),
    ];

    return FlowPage(
      title: l.navNotifications,
      children: [
        for (final (index, (title, subtitle)) in notifications.indexed)
          AppCard(
            leading: index < 2
                ? Icon(Icons.circle, color: colors.secondary, size: 10)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowCopy(title, subtitle),
                if (index == 0) ...[
                  const SizedBox(height: 8),
                  if (_accepted == null)
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => setState(() => _accepted = true),
                          child: Text(l.acceptProposal),
                        ),
                        OutlinedButton(
                          onPressed: () => setState(() => _accepted = false),
                          child: Text(l.declineProposal),
                        ),
                      ],
                    )
                  else
                    AppBadge(
                      label: _accepted!
                          ? l.proposalAccepted
                          : l.proposalDeclined,
                      tone: _accepted!
                          ? AppBadgeTone.accent
                          : AppBadgeTone.neutral,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
