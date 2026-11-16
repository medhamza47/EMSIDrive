import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/session_id_provider.dart';
import '../../notifications/data/ride_notices_provider.dart';
import '../application/active_rides_provider.dart';
import 'trip_status.dart';

class ActiveRideBar extends ConsumerStatefulWidget {
  const ActiveRideBar({super.key});
  @override
  ConsumerState<ActiveRideBar> createState() => _ActiveRideBarState();
}

class _ActiveRideBarState extends ConsumerState<ActiveRideBar> {
  Set<String>? _seen;
  int? _session;
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionIdProvider);
    if (_session != session) {
      _seen = null;
      _session = session;
    }
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    ref.listen(rideNoticesProvider, (_, next) {
      final notices = next.asData?.value;
      if (notices == null) return;
      final fresh = _seen == null
          ? null
          : notices.where((n) => !n.seen && !_seen!.contains(n.id)).firstOrNull;
      _seen = notices.map((n) => n.id).toSet();
      if (fresh != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rideNoticeLabel(l, fresh)),
            action: SnackBarAction(
              label: l.tripFollow,
              onPressed: () =>
                  context.push(AppRoutes.acceptedRide(fresh.bookingId)),
            ),
          ),
        );
        ref.invalidate(activeRidesProvider);
      }
    });
    final ride = ref.watch(activeRidesProvider).asData?.value.firstOrNull;
    if (ride == null) return const SizedBox.shrink();
    return Material(
      color: colors.primaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.directions_car_filled,
          color: colors.onPrimaryContainer,
        ),
        title: Text(
          ride.partner,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          tripStageLabel(l, ride.stage),
          style: TextStyle(color: colors.onPrimaryContainer),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.acceptedRide(ride.id)),
      ),
    );
  }
}
