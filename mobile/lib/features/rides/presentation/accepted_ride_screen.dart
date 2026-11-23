import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/session_id_provider.dart';
import '../../notifications/data/ride_notices_provider.dart';
import '../application/active_rides_provider.dart';
import '../application/driver_tracking_provider.dart';
import '../data/marketplace_api.dart';
import '../data/road_route_repository.dart';
import '../domain/marketplace_models.dart';
import '../domain/marrakech_trip.dart';
import 'marketplace_map.dart';
import 'marketplace_screens.dart';
import 'trip_status.dart';
import '../../home/application/home_controller.dart';
import '../../reports/presentation/report_screens.dart';

class AcceptedRideScreen extends ConsumerStatefulWidget {
  const AcceptedRideScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<AcceptedRideScreen> createState() => _AcceptedRideScreenState();
}

class _AcceptedRideScreenState extends ConsumerState<AcceptedRideScreen>
    with WidgetsBindingObserver {
  late final MarketplaceApi _api = ref.read(marketplaceApiProvider);
  late final int _session = ref.read(sessionIdProvider);
  final _draft = TextEditingController();
  final _messages = <RideMessage>[];
  AcceptedRide? _ride;
  Timer? _timer;
  bool _polling = false,
      _loadingError = false,
      _sending = false,
      _changing = false,
      _foreground = true;
  RoadRoute? _approach;
  DateTime? _routedAt;
  LatLng? _routedPoint;
  RideStage? _routedStage;
  int _routeVersion = 0;
  bool _routing = false, _routeError = false;

  bool get _current => mounted && ref.read(sessionIdProvider) == _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      setState(() {});
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (_polling || !_foreground || !_current) return;
    _polling = true;
    try {
      final ride = await _api.trip(widget.id);
      if (!mounted || !_current) return;
      final changed =
          _ride != null &&
          (_ride!.stage != ride.stage || _ride!.status != ride.status);
      setState(() {
        _ride = ride;
        _loadingError = false;
      });
      if (changed) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tripStageLabel(l, ride.stage))));
        ref.invalidate(homeControllerProvider);
        ref.invalidate(activeRidesProvider);
        ref.invalidate(rideNoticesProvider);
      }
      unawaited(_updateApproach(ride));
      try {
        final messages = await _api.messages(
          widget.id,
          _messages.isEmpty ? 0 : _messages.last.id,
        );
        if (!_current) return;
        final known = _messages.map((m) => m.id).toSet();
        setState(
          () => _messages.addAll(messages.where((m) => !known.contains(m.id))),
        );
      } catch (_) {
        /* Chat failure must not hide a fresh driver location. */
      }
    } catch (_) {
      if (_current) {
        setState(() {
          _loadingError = true;
          _approach = null;
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _updateApproach(AcceptedRide ride) async {
    final point = ride.freshLocation(DateTime.now());
    if (point == null ||
        ![
          RideStage.confirmed,
          RideStage.enRoute,
          RideStage.inProgress,
        ].contains(ride.stage)) {
      _routeVersion++;
      if (_current) {
        setState(() {
          _approach = null;
          _routing = false;
          _routedStage = null;
        });
      }
      return;
    }
    if (_routedStage != ride.stage) {
      _routeVersion++;
      _approach = null;
      _routing = false;
    }
    if (_routing) return;
    final elapsed = _routedAt == null
        ? 999
        : DateTime.now().difference(_routedAt!).inSeconds;
    final moved = _routedPoint == null
        ? 999
        : const Distance().as(LengthUnit.Meter, _routedPoint!, point);
    if (_routedStage == ride.stage &&
        elapsed < 20 &&
        (elapsed < 8 || moved < 100)) {
      return;
    }
    final version = ++_routeVersion;
    _routedStage = ride.stage;
    _routedPoint = point;
    _routedAt = DateTime.now();
    setState(() {
      _routing = true;
      _routeError = false;
    });
    try {
      final target = ride.stage == RideStage.inProgress
          ? ride.path.destination
          : ride.path.origin;
      final route = await ref
          .read(roadRouteRepositoryProvider)
          .between(point, target);
      if (_current &&
          version == _routeVersion &&
          _ride?.freshLocation(DateTime.now()) != null &&
          !_loadingError) {
        setState(() => _approach = route);
      }
    } catch (_) {
      if (_current && version == _routeVersion) {
        setState(() {
          _approach = null;
          _routeError = true;
        });
      }
    } finally {
      if (_current && version == _routeVersion) {
        setState(() => _routing = false);
      }
    }
  }

  Future<void> _transition(RideStage stage) async {
    if (_changing || !_current) return;
    final l = AppLocalizations.of(context);
    if (stage == RideStage.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l.tripCancelQuestion),
          content: Text(l.tripCancelHint),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.timetableCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.tripCancelAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !_current) return;
    }
    setState(() => _changing = true);
    try {
      if (stage == RideStage.enRoute) {
        await ref
            .read(driverTrackingProvider.notifier)
            .start(
              widget.id,
              l.tripGpsNotificationTitle,
              l.tripGpsNotificationBody,
            );
      }
      final ride = await _api.transition(widget.id, stage);
      if (!_current) return;
      setState(() {
        _ride = ride;
        _approach = null;
      });
      _routeVersion++;
      ref.invalidate(homeControllerProvider);
      ref.invalidate(activeRidesProvider);
      ref.invalidate(rideNoticesProvider);
      unawaited(_updateApproach(ride));
    } catch (_) {
      if (mounted && _current) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.tripUpdateError)));
      }
    } finally {
      if (_current) setState(() => _changing = false);
    }
  }

  Future<void> _send() async {
    if (_ride?.active != true) return;
    final body = _draft.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.send(widget.id, body);
      if (!_current) return;
      if (_draft.text.trim() == body) _draft.clear();
      await _refresh();
    } catch (_) {
      if (mounted && _current) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).sendChatError)),
        );
      }
    } finally {
      if (_current) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _routeVersion++;
    _draft.dispose();
    super.dispose();
  }

  Future<void> _call(AcceptedRide ride) async {
    final uri = ride.callUri;
    final l = AppLocalizations.of(context);
    if (uri == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.tripPhoneMissing)));
      return;
    }
    final whatsapp = ride.whatsappUri;
    final selected = await showModalBottomSheet<Uri>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.tripContactChoice,
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(l.tripPhoneCall),
              subtitle: Text(l.tripPhoneCallHint),
              onTap: () => Navigator.pop(sheet, uri),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text(l.tripWhatsApp),
              subtitle: Text(
                whatsapp == null
                    ? l.tripInternationalPhone
                    : l.tripWhatsAppHint,
              ),
              enabled: whatsapp != null,
              onTap: whatsapp == null
                  ? null
                  : () => Navigator.pop(sheet, whatsapp),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected == null ||
        !mounted ||
        !_current ||
        _ride?.stage.active != true) {
      return;
    }
    try {
      if (selected.scheme == 'https') {
        try {
          if (await launchUrl(
            selected,
            mode: LaunchMode.externalNonBrowserApplication,
          )) {
            return;
          }
        } catch (_) {
          /* Fall back to WhatsApp's official web link. */
        }
      }
      if (await launchUrl(selected, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      /* Show the same actionable error if no dialer is available. */
    }
    if (mounted && _current) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected.scheme == 'tel' ? l.tripCallFailed : l.tripWhatsAppFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionIdProvider);
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    final ride = _current ? _ride : null;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ride?.partner ?? l.acceptedRideTitle),
          actions: [
            if (ride != null && ride.stage.active)
              IconButton(
                tooltip: l.tripCall,
                onPressed: () => _call(ride),
                icon: const Icon(Icons.call),
              ),
            if (ride != null)
              IconButton(
                tooltip: l.reportTitle,
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportScreen(contextData: {'bookingId': ride.id}),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            tabs: [
              Tab(text: l.tripFollow, icon: const Icon(Icons.near_me_outlined)),
              Tab(text: l.rideChat, icon: const Icon(Icons.chat_outlined)),
            ],
          ),
        ),
        body: SafeArea(
          child: ride == null
              ? Center(
                  child: _loadingError
                      ? TextButton(
                          onPressed: _refresh,
                          child: Text(l.retryLabel),
                        )
                      : const CircularProgressIndicator(),
                )
              : TabBarView(
                  children: [_mapTab(context, ride), _chatTab(context)],
                ),
        ),
      ),
    );
  }

  Widget _mapTab(BuildContext context, AcceptedRide ride) {
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    final live = _loadingError ? null : ride.freshLocation(DateTime.now());
    final tracking = ref.watch(driverTrackingProvider);
    final sharing = tracking.tripId == ride.id;
    final approach = live == null ? null : _approach;
    final statusColor = tripStageColor(colors, ride.stage);
    final minutes = approach == null
        ? null
        : (approach.durationSeconds / 60).ceil().clamp(1, 999);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                children: [
                  Icon(
                    ride.stage == RideStage.completed
                        ? Icons.check_circle
                        : Icons.directions_car,
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tripStageLabel(l, ride.stage),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (minutes != null) ...[
                Text(
                  l.tripEtaMinutes(minutes),
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  ride.stage == RideStage.inProgress
                      ? l.tripEtaDestination
                      : l.tripEtaPickup,
                ),
                Text(
                  l.tripEtaAt(
                    DateFormat.Hm().format(
                      _routedAt!.add(
                        Duration(seconds: approach!.durationSeconds.round()),
                      ),
                    ),
                  ),
                ),
                Text(
                  l.tripEtaEstimate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (ride.stage == RideStage.enRoute ||
                  ride.stage == RideStage.inProgress)
                Text(
                  _routeError
                      ? l.tripEtaUnavailable
                      : live == null
                      ? l.tripWaitingGps
                      : l.tripCalculatingEta,
                ),
              if (_routing) const LinearProgressIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (ride.stage != RideStage.cancelled)
          Row(
            children: [
              for (final stage in RideStage.values.where(
                (s) => s != RideStage.cancelled,
              ))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: stage.index <= ride.stage.index
                            ? statusColor
                            : colors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 14),
        MarketplaceMap(
          path: ride.path,
          live: live,
          approachRoute: approach,
          trackingMode: true,
          pickupPhase:
              ride.stage != RideStage.inProgress &&
              ride.stage != RideStage.completed,
        ),
        const SizedBox(height: 8),
        if (ride.vehicleDetails != null) Text(ride.vehicleDetails!.label),
        if (ride.status == 'COMPLETED')
          PrimaryButton(
            label: l.tripSummaryOpen,
            icon: Icons.receipt_long_outlined,
            onPressed: () => context.push(AppRoutes.tripSummary(ride.id)),
          ),
        if (ride.stage.active)
          Row(
            children: [
              Icon(
                live == null ? Icons.location_off_outlined : Icons.gps_fixed,
                size: 16,
                color: live == null ? colors.onSurfaceVariant : colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  live == null ? l.tripWaitingGps : l.tripGpsFresh,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  rideDeparture(ride.path.departure),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  children: [
                    Icon(Icons.trip_origin, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ride.path.originLabel)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.flag, color: colors.error),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ride.path.destinationLabel)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_loadingError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l.tripConnectionLost,
              style: TextStyle(color: colors.error),
            ),
          ),
        if (ride.isDriver && ride.stage.active) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _changing ? null : () => _transition(ride.stage.next!),
            icon: const Icon(Icons.arrow_forward),
            label: Text(switch (ride.stage) {
              RideStage.confirmed => l.tripStartDriving,
              RideStage.enRoute => l.tripMarkArrived,
              RideStage.arrived => l.tripStartJourney,
              _ => l.tripFinishJourney,
            }),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: tracking.busy
                ? null
                : () async {
                    final controller = ref.read(
                      driverTrackingProvider.notifier,
                    );
                    if (sharing) {
                      await controller.stop();
                    } else {
                      await controller.start(
                        ride.id,
                        l.tripGpsNotificationTitle,
                        l.tripGpsNotificationBody,
                      );
                    }
                  },
            icon: Icon(
              sharing ? Icons.location_off_outlined : Icons.my_location,
            ),
            label: Text(sharing ? l.stopLiveSharing : l.startLiveSharing),
          ),
          Text(
            l.tripSharingDisclosure,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (tracking.error != null)
            Text(switch (tracking.error) {
              'denied' => l.locationDenied,
              'disabled' => l.locationDisabled,
              _ => l.liveSharingError,
            }, style: TextStyle(color: colors.error)),
        ],
        if ([
          RideStage.confirmed,
          RideStage.enRoute,
          RideStage.arrived,
        ].contains(ride.stage))
          TextButton(
            onPressed: _changing
                ? null
                : () => _transition(RideStage.cancelled),
            child: Text(
              l.tripCancelAction,
              style: TextStyle(color: colors.error),
            ),
          ),
      ],
    );
  }

  Widget _chatTab(BuildContext context) {
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_loadingError) Text(l.tripConnectionLost),
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Text(l.noChatMessages))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return Align(
                      alignment: message.mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.mine
                              ? colors.primaryContainer
                              : colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.body,
                          style: TextStyle(
                            color: message.mine
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_ride?.active != true)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l.rideReadOnlyChat),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _draft,
                    maxLength: 1000,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: l.writeChatMessage,
                      counterText: '',
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: l.sendChatMessage,
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
