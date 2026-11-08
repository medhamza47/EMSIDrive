import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/marrakech_boundary.dart';
import '../data/road_route_repository.dart';
import '../domain/marrakech_trip.dart';

class MarrakechMapScreen extends StatefulWidget {
  const MarrakechMapScreen({
    required this.campus,
    required this.direction,
    required this.campusLabel,
    this.initialPoint,
    super.key,
  });

  final EmsiCampus campus;
  final CampusDirection direction;
  final String campusLabel;
  final LatLng? initialPoint;

  @override
  State<MarrakechMapScreen> createState() => _MarrakechMapScreenState();
}

class _MarrakechMapScreenState extends State<MarrakechMapScreen> {
  final _map = MapController();
  final _repository = RoadRouteRepository();
  late final Future<MarrakechBoundary> _boundary = MarrakechBoundary.load();
  late LatLng? _point = widget.initialPoint;
  RoadRoute? _route;
  String? _message;
  bool _locating = false;
  bool _routing = false;
  bool _showCoordinates = false;

  @override
  void dispose() {
    _map.dispose();
    _repository.close();
    super.dispose();
  }

  void _select(MarrakechBoundary boundary, LatLng point) {
    if (!boundary.contains(point)) {
      setState(
        () => _message = AppLocalizations.of(context).pointOutsideMarrakech,
      );
      return;
    }

    setState(() {
      _point = point;
      _route = null;
      _message = null;
    });
  }

  Future<void> _locate(MarrakechBoundary boundary) async {
    final l = AppLocalizations.of(context);
    final previous = _point;
    setState(() {
      _locating = true;
      _message = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _message = l.locationDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _message = l.locationDenied);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted || _point != previous) return;
      final point = LatLng(position.latitude, position.longitude);
      _select(boundary, point);
      if (boundary.contains(point)) _map.move(point, 17);
    } on Exception {
      if (mounted) setState(() => _message = l.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _preview() async {
    final point = _point;
    if (point == null) return;

    final l = AppLocalizations.of(context);
    final trip = MarrakechTrip(
      campus: widget.campus,
      direction: widget.direction,
      cityPoint: point,
    );
    setState(() {
      _routing = true;
      _message = null;
    });

    try {
      final route = await _repository.calculate(trip);
      if (!mounted || _point != point) return;
      setState(() => _route = route);
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: [trip.origin, trip.destination, ...route.points],
          padding: const EdgeInsets.all(44),
          maxZoom: 17,
        ),
      );
    } on Exception {
      if (mounted && _point == point) {
        setState(() => _message = l.roadRouteError);
      }
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.marrakechMapTitle)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: l.confirmMapPoint,
            onPressed: _point == null
                ? null
                : () => Navigator.of(context).pop(_point),
          ),
        ),
      ),
      body: FutureBuilder(
        future: _boundary,
        builder: (context, snapshot) {
          final boundary = snapshot.data;
          if (snapshot.hasError) {
            return Center(child: Text(l.mapUnavailable));
          }
          if (boundary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(child: _buildMap(context, boundary)),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * .45,
                  ),
                  child: SingleChildScrollView(
                    child: _buildControls(context, boundary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context, MarrakechBoundary boundary) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final route = _route;
    final point = _point;
    final campusIsOrigin = widget.direction == CampusDirection.fromCampus;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: point ?? const LatLng(31.6295, -8.0083),
        initialCameraFit: CameraFit.coordinates(
          coordinates: [
            widget.campus.point,
            point ?? const LatLng(31.6295, -8.0083),
          ],
          padding: const EdgeInsets.all(65),
          maxZoom: 14,
        ),
        minZoom: 11,
        maxZoom: 19,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: boundary.bounds,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, location) => _select(boundary, location),
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment(
            'MAP_TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'ma.emsi.emsidrive.emsidrive_mobile',
          maxNativeZoom: 19,
          panBuffer: 0,
        ),
        PolygonLayer(
          polygons: [
            for (final polygon in boundary.polygons)
              Polygon(
                points: polygon.first,
                holePointsList: polygon.skip(1).toList(),
                borderColor: colors.primary.withValues(alpha: .6),
                borderStrokeWidth: 2,
              ),
          ],
        ),
        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                color: colors.primary,
                strokeWidth: 6,
                borderColor: colors.surface,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            _marker(
              widget.campus.point,
              Icons.school,
              widget.campusLabel,
              colors.primary,
            ),
            if (point != null)
              _marker(
                point,
                Icons.location_on,
                campusIsOrigin ? l.tripDestination : l.tripOrigin,
                colors.tertiary,
              ),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Material(
            color: colors.surface,
            child: InkWell(
              onTap: () =>
                  launchUrl(Uri.https('www.openstreetmap.org', '/copyright')),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _marker(LatLng point, IconData icon, String label, Color color) =>
      Marker(
        point: point,
        width: 42,
        height: 42,
        child: Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28, semanticLabel: label),
          ),
        ),
      );

  Widget _buildControls(BuildContext context, MarrakechBoundary boundary) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final point = _point;
    final route = _route;
    final message = _message;
    final number = NumberFormat.decimalPatternDigits(
      locale: 'fr',
      decimalDigits: 1,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.mapSelectionTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          point == null
                              ? l.mapSelectionHint
                              : l.mapSelectedHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${l.mapCampusSummary} : ${widget.campusLabel}',
                style: theme.textTheme.bodySmall,
              ),
              if (point != null)
                TextButton(
                  onPressed: () =>
                      setState(() => _showCoordinates = !_showCoordinates),
                  child: Text(l.mapCoordinatesDetails),
                ),
              if (point != null && _showCoordinates)
                Text(
                  l.chosenCoordinates(
                    point.latitude.toStringAsFixed(5),
                    point.longitude.toStringAsFixed(5),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              if (message != null)
                Text(message, style: TextStyle(color: theme.colorScheme.error)),
              if (route != null)
                Text(
                  l.roadRouteSummary(
                    number.format(route.distanceMeters / 1000),
                    (route.durationSeconds / 60).ceil(),
                  ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _locating ? null : () => _locate(boundary),
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _locating ? l.locatingPosition : l.useMyLocation,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: point == null || _routing || route != null
                        ? null
                        : _preview,
                    icon: const Icon(Icons.alt_route),
                    label: Text(
                      _routing ? l.calculatingRoute : l.previewRoadRoute,
                    ),
                  ),
                ],
              ),
              if (route == null && point != null)
                Text(l.routingPrivacyHint, style: theme.textTheme.bodySmall),
              if (route != null)
                Text(l.roadRouteSource, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
