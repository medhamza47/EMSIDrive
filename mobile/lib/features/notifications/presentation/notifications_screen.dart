import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../../rides/data/marketplace_api.dart';
import '../../rides/domain/marketplace_models.dart';
import '../data/ride_notices_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    RideNotice notice,
  ) async {
    if (!notice.seen) {
      try {
        await ref.read(marketplaceApiProvider).markRead(notice.id);
        if (context.mounted) ref.invalidate(rideNoticesProvider);
      } catch (_) {
        // An unavailable read receipt does not prevent opening the trip.
      }
    }
    if (context.mounted) context.push(AppRoutes.acceptedRide(notice.bookingId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final notices = ref.watch(rideNoticesProvider);
    return FlowPage(
      title: l.navNotifications,
      showNotifications: false,
      children: [
        if (notices.isLoading && !notices.hasValue)
          const LinearProgressIndicator()
        else if (notices.hasError)
          TextButton(
            onPressed: () => ref.invalidate(rideNoticesProvider),
            child: Text(l.marketplaceLoadError),
          )
        else if (notices.value?.isEmpty ?? true)
          Text(l.noRideNotices)
        else
          for (final notice in notices.value!)
            AppCard(
              onTap: () => _open(context, ref, notice),
              leading: Icon(
                notice.seen
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              trailing: const Icon(Icons.chevron_right),
              child: FlowCopy(
                notice.isRequest
                    ? l.requestAcceptedNotice(notice.accepter)
                    : l.offerAcceptedNotice(notice.accepter),
                l.openAcceptedRide,
              ),
            ),
      ],
    );
  }
}
