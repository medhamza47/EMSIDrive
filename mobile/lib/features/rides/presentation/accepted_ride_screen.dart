import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/marketplace_api.dart';
import '../domain/marketplace_models.dart';
import 'marketplace_map.dart';
import 'marketplace_screens.dart';

class AcceptedRideScreen extends ConsumerStatefulWidget {
  const AcceptedRideScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<AcceptedRideScreen> createState() => _AcceptedRideScreenState();
}

class _AcceptedRideScreenState extends ConsumerState<AcceptedRideScreen>
    with WidgetsBindingObserver {
  late final MarketplaceApi _api = ref.read(marketplaceApiProvider);
  final _draft = TextEditingController();
  final _messages = <RideMessage>[];
  AcceptedRide? _ride;
  Timer? _refreshTimer;
  Timer? _locationTimer;
  Future<void>? _publishing;
  bool _polling = false;
  bool _loadingError = false;
  bool _sending = false;
  bool _starting = false;
  bool _sharing = false;
  bool _foreground = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _sharing) unawaited(_stopSharing());
    if (_foreground) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_polling || !_foreground) return;
    _polling = true;
    try {
      final after = _messages.isEmpty ? 0 : _messages.last.id;
      final (ride, messages) = await (
        _api.trip(widget.id),
        _api.messages(widget.id, after),
      ).wait;
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _loadingError = false;
        _messages.addAll(messages);
      });
    } catch (_) {
      if (mounted) setState(() => _loadingError = true);
    } finally {
      _polling = false;
    }
  }

  Future<void> _send() async {
    final body = _draft.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.send(widget.id, body);
      if (!mounted) return;
      if (_draft.text.trim() == body) _draft.clear();
      await _refresh();
    } catch (_) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.sendChatError)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startSharing() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _starting = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationError = l.locationDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationError = l.locationDenied);
        return;
      }
      if (!mounted || !_foreground) return;
      setState(() => _sharing = true);
      _publishLocation();
      _locationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _publishLocation(),
      );
    } catch (_) {
      if (mounted) setState(() => _locationError = l.liveSharingError);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _publishLocation() {
    if (!_sharing || !_foreground || _publishing != null) return;
    final operation = _updateLocation();
    _publishing = operation;
    unawaited(operation.whenComplete(() => _publishing = null));
  }

  Future<void> _updateLocation() async {
    final l = AppLocalizations.of(context);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted || !_sharing || !_foreground) return;
      await _api.location(
        widget.id,
        LatLng(position.latitude, position.longitude),
      );
      if (mounted && _locationError != null) {
        setState(() => _locationError = null);
      }
    } catch (_) {
      if (mounted && _sharing) {
        setState(() => _locationError = l.liveSharingError);
      }
    }
  }

  Future<void> _stopSharing({bool disposing = false}) async {
    _locationTimer?.cancel();
    _sharing = false;
    if (!disposing && mounted) setState(() => _starting = true);
    final api = _api;
    final id = widget.id;
    await _publishing;
    try {
      await api.location(id, null);
    } catch (_) {
      if (!disposing && mounted) {
        setState(
          () => _locationError = AppLocalizations.of(context).liveSharingError,
        );
      }
    } finally {
      if (!disposing && mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    if (_sharing) unawaited(_stopSharing(disposing: true));
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ride = _ride;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ride?.partner ?? l.acceptedRideTitle),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary
                .withValues(alpha: .75),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: [
              Tab(text: l.navRides, icon: const Icon(Icons.route)),
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
                          child: Text(l.marketplaceLoadError),
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
    final l = AppLocalizations.of(context);
    final live = _loadingError ? null : ride.live;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppBadge(label: ride.isDriver ? l.youDrive : l.youRide),
        const SizedBox(height: 8),
        FlowCopy(ride.path.title, rideDeparture(ride.path.departure)),
        const SizedBox(height: 12),
        MarketplaceMap(path: ride.path, live: live),
        if (ride.isDriver) ...[
          Text(l.locationSharingHint),
          const SizedBox(height: 8),
          PrimaryButton(
            label: _sharing ? l.stopLiveSharing : l.startLiveSharing,
            icon: Icons.my_location,
            isLoading: _starting,
            onPressed: _sharing ? _stopSharing : _startSharing,
          ),
          if (_locationError case final error?) Text(error),
        ] else
          Text(live == null ? l.noLiveLocation : l.driverLocation),
        if (_loadingError) Text(l.marketplaceLoadError),
      ],
    );
  }

  Widget _chatTab(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_loadingError) Text(l.marketplaceLoadError),
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
