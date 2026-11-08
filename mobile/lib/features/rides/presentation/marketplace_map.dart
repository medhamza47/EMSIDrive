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
    this.previewOnOpen = false,
    super.key,
  });

  final RidePath path;
  final LatLng? live;
  final bool previewOnOpen;

  @override
  State<MarketplaceMap> createState() => _MarketplaceMapState();
}

class _MarketplaceMapState extends State<MarketplaceMap> {
  final _controller = MapController();
  final _repository = RoadRouteRepository();
  RoadRoute? _route;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.previewOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preview();
      });
    }
  }

  Future<void> _preview() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final route = await _repository.between(
        widget.path.origin,
        widget.path.destination,
      );
      if (!mounted) return;
      setState(() => _route = route);
      _controller.fitCamera(_fit);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  CameraFit get _fit => CameraFit.coordinates(
    coordinates: [
      widget.path.origin,
      widget.path.destination,
      ...?_route?.points,
      ?widget.live,
    ],
    padding: const EdgeInsets.all(30),
    maxZoom: 17,
  );

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
      (widget.path.origin, Icons.trip_origin, l.tripOrigin, colors.primary),
      (widget.path.destination, Icons.flag, l.tripDestination, colors.error),
      if (live != null)
        (live, Icons.directions_car, l.driverLocation, colors.tertiary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: widget.path.origin,
                initialCameraFit: _fit,
                minZoom: 9,
                maxZoom: 19,
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
                        color: colors.primary,
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
                  ],
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
        if (route != null)
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
