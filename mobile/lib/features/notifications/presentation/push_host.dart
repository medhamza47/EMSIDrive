import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../application/push_service.dart';
import '../data/push_gateway.dart';
import '../data/ride_notices_provider.dart';

class PushHost extends ConsumerStatefulWidget {
  const PushHost({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost>
    with WidgetsBindingObserver {
  late final PushService _service;
  StreamSubscription<PushNotice>? _messages, _opened;
  Timer? _retry;
  PushNotice? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = ref.read(pushServiceProvider)..addListener(_changed);
    final gateway = _service.gateway;
    if (gateway != null) {
      _messages = gateway.messages.listen(_message);
      _opened = gateway.opened.listen(_open);
      unawaited(_initial(gateway));
      _retry = Timer.periodic(const Duration(minutes: 1), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          unawaited(_service.synchronize());
        }
      });
      unawaited(_service.synchronize());
    }
  }

  Future<void> _initial(PushGateway gateway) async {
    try {
      final notice = await gateway.initialNotice();
      if (mounted && notice != null) _open(notice);
    } catch (_) {
      // Startup remains usable if Google Play services are unavailable.
    }
  }

  void _message(PushNotice notice) {
    if (!mounted || !_service.owns(notice)) return;
    ref.invalidate(rideNoticesProvider);
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.pushForegroundNotice),
        action: SnackBarAction(
          label: l.pushOpen,
          onPressed: () => _open(notice),
        ),
      ),
    );
  }

  void _open(PushNotice notice) {
    if (!notice.valid) return;
    _pending = notice;
    _changed();
  }

  void _changed() {
    final notice = _pending;
    if (notice == null || !_service.owns(notice)) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_service.owns(notice)) return;
      ref
          .read(appRouterProvider)
          .push(AppRoutes.acceptedRide(notice.bookingId));
      unawaited(_markRead(notice));
    });
  }

  Future<void> _markRead(PushNotice notice) async {
    try {
      // Opening the trip succeeds even when the read receipt cannot be sent.
      await ref.read(pushServiceProvider).markRead(notice.id);
      if (mounted) ref.invalidate(rideNoticesProvider);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_service.synchronize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_changed);
    _retry?.cancel();
    unawaited(_messages?.cancel());
    unawaited(_opened?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
