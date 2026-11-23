import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../data/road_route_repository.dart';
import '../domain/marketplace_models.dart';
import '../domain/marrakech_trip.dart';

class MarketplaceMap extends StatefulWidget {
  const MarketplaceMap({
    required this.path,
    this.live,
    this.previewOnOpen = true,
    this.offers = const [],
    this.selectedOfferId,
    this.onOfferSelected,
    this.cityPoint,
    this.route,
    this.approachRoute,
    this.trackingMode = false,
    this.pickupPhase = true,
    super.key,
  });

  final RidePath path;
  final LatLng? live;
  final bool previewOnOpen;
  final List<RideListing> offers;
  final String? selectedOfferId;
  final ValueChanged<RideListing>? onOfferSelected;
  final LatLng? cityPoint;
  final RoadRoute? route;
  final RoadRoute? approachRoute;
  final bool trackingMode;
  final bool pickupPhase;

  @override
  State<MarketplaceMap> createState() => _MarketplaceMapState();
}

class _MarketplaceMapState extends State<MarketplaceMap> {
  final _controller = MapController();
  final _repository = RoadRouteRepository();
  RoadRoute? _route;
  bool _loading = false;
  bool _failed = false;
  int _request = 0;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    if (widget.previewOnOpen && _route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preview();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MarketplaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackingMode &&
        (widget.pickupPhase != oldWidget.pickupPhase ||
            (oldWidget.approachRoute == null &&
                widget.approachRoute != null))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _follow) _controller.fitCamera(_fit);
      });
    }
    if (widget.trackingMode &&
        _follow &&
        widget.live != null &&
        widget.live != oldWidget.live) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _follow && widget.live != null) {
          _controller.move(widget.live!, _controller.camera.zoom);
        }
      });
    }
    if (widget.route != oldWidget.route ||
        widget.path.origin != oldWidget.path.origin ||
        widget.path.destination != oldWidget.path.destination) {
      _request++;
      _route = widget.route;
      _failed = false;
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_route == null && widget.previewOnOpen) {
          _preview();
        } else {
          _controller.fitCamera(_fit);
        }
      });
    }
  }

  Future<void> _preview() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final route = await _repository.between(
        widget.path.origin,
        widget.path.destination,
      );
      if (!mounted || request != _request) return;
      setState(() => _route = route);
      _controller.fitCamera(_fit);
    } on Exception {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  CameraFit get _fit => CameraFit.coordinates(
    coordinates: [
      widget.path.origin,
      if (!widget.trackingMode || !widget.pickupPhase || widget.live == null)
        widget.path.destination,
      if (!widget.trackingMode || !widget.pickupPhase || widget.live == null)
        ...?_route?.points,
      ...?widget.approachRoute?.points,
      ?widget.live,
      ?widget.cityPoint,
      for (final offer in widget.offers) _cityPoint(offer),
    ],
    padding: const EdgeInsets.all(30),
    maxZoom: 17,
  );

  LatLng _cityPoint(RideListing offer) => offer.path.originLabel == 'Marrakech'
      ? offer.path.origin
      : offer.path.destination;

  @override
  void dispose() {
    _repository.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final route = _route;
    final live = widget.live;
    final markers = [
      (
        widget.path.origin,
        widget.trackingMode ? Icons.person_pin_circle : Icons.trip_origin,
        widget.trackingMode ? l.tripPickupStop : l.tripOrigin,
        widget.trackingMode ? colors.tertiary : colors.primary,
      ),
      (
        widget.path.destination,
        Icons.flag,
        widget.trackingMode ? l.tripFinalStop : l.tripDestination,
        colors.primary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.trackingMode) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                avatar: Icon(Icons.person_pin_circle, color: colors.tertiary),
                label: Text(l.tripPickupStop),
                side: BorderSide(
                  color: widget.pickupPhase
                      ? colors.tertiary
                      : colors.outlineVariant,
                ),
              ),
              Chip(
                avatar: Icon(Icons.flag, color: colors.primary),
                label: Text(l.tripFinalStop),
                side: BorderSide(
                  color: !widget.pickupPhase
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
            ],
          ),
          Text(
            widget.pickupPhase
                ? l.tripPickupInstruction
                : l.tripDestinationInstruction,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: widget.trackingMode ? 340 : 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: widget.path.origin,
                initialCameraFit: _fit,
                minZoom: 9,
                maxZoom: 19,
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture) _follow = false;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: const String.fromEnvironment(
                    'MAP_TILE_URL',
                    defaultValue:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  userAgentPackageName: 'ma.emsi.emsidrive.emsidrive_mobile',
                  panBuffer: 0,
                ),
                if (route != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.points,
                        color: widget.trackingMode
                            ? colors.outline.withValues(alpha: .6)
                            : colors.primary,
                        strokeWidth: 5,
                        borderColor: colors.surface,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final (point, icon, label, color) in markers)
                      Marker(
                        point: point,
                        width: 36,
                        height: 36,
                        child: Tooltip(
                          message: label,
                          child: Icon(
                            icon,
                            color: color,
                            size: 30,
                            semanticLabel: label,
                          ),
                        ),
                      ),
                    if (widget.cityPoint case final point?)
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.person_pin_circle,
                          size: 36,
                          color: colors.tertiary,
                          semanticLabel: l.matchYourPoint,
                        ),
                      ),
                    for (final offer in widget.offers)
                      Marker(
                        point: _cityPoint(offer),
                        width: 52,
                        height: 52,
                        child: Tooltip(
                          message:
                              '${offer.author} · ${DateFormat.Hm().format(offer.path.departure)}',
                          child: Material(
                            color: widget.selectedOfferId == offer.id
                                ? colors.primary
                                : colors.surface,
                            shape: CircleBorder(
                              side: BorderSide(color: colors.primary, width: 2),
                            ),
                            elevation: 3,
                            child: IconButton(
                              onPressed: () =>
                                  widget.onOfferSelected?.call(offer),
                              icon: Icon(
                                Icons.directions_car,
                                color: widget.selectedOfferId == offer.id
                                    ? colors.onPrimary
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.approachRoute case final approach?)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: approach.points,
                        color: widget.pickupPhase
                            ? colors.tertiary
                            : colors.primary,
                        strokeWidth: 6,
                        borderColor: colors.surface,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (live != null)
                  TweenAnimationBuilder<LatLng>(
                    tween: _LocationTween(begin: live, end: live),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, point, child) => MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: l.driverLocation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.surface,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: colors.onTertiary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: IconButton.filledTonal(
                      tooltip: l.tripRecenter,
                      icon: Icon(
                        widget.trackingMode
                            ? Icons.my_location
                            : Icons.fit_screen_outlined,
                      ),
                      onPressed: () {
                        _follow = true;
                        _controller.fitCamera(_fit);
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Material(
                    color: colors.surface,
                    child: InkWell(
                      onTap: () => launchUrl(
                        Uri.https('www.openstreetmap.org', '/copyright'),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          '© OpenStreetMap contributors',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_failed) Text(l.roadRouteError),
        if (route != null && !widget.trackingMode)
          Text(
            l.roadRouteSummary(
              NumberFormat.decimalPatternDigits(
                locale: 'fr',
                decimalDigits: 1,
              ).format(route.distanceMeters / 1000),
              (route.durationSeconds / 60).ceil(),
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            if (route == null && !_loading)
              TextButton(onPressed: _preview, child: Text(l.previewRoadRoute)),
            if (live != null)
              TextButton(
                onPressed: () => _controller.move(live, 16),
                child: Text(l.driverLocation),
              ),
          ],
        ),
        if (route == null && !widget.previewOnOpen)
          Text(
            l.routingPrivacyHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _LocationTween extends Tween<LatLng> {
  _LocationTween({required super.begin, required super.end});
  @override
  LatLng lerp(double t) => LatLng(
    begin!.latitude + (end!.latitude - begin!.latitude) * t,
    begin!.longitude + (end!.longitude - begin!.longitude) * t,
  );
}
