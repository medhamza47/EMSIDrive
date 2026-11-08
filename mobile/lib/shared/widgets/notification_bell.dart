import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../features/notifications/data/ride_notices_provider.dart';
import '../../l10n/app_localizations.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(rideNoticesProvider).value?.any((n) => !n.seen) ?? false;
    return IconButton(
      tooltip: AppLocalizations.of(context).navNotifications,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
