import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../rides/data/road_route_repository.dart';
import '../../rides/domain/marketplace_models.dart';
import '../../rides/domain/marrakech_trip.dart';
import '../../rides/presentation/marrakech_map_screen.dart';
import '../../rides/presentation/marketplace_map.dart';
import '../../schedule/application/saved_timetable_provider.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/schedule_models.dart';
import '../../schedule/presentation/schedule_error.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});
  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsState();
}

class _SuggestionsState extends ConsumerState<SuggestionsScreen> {
  final _mapKey = GlobalKey();
  int _commute = 30, _radius = 2000, _direction = 0, _searchRevision = 0;
  String _campus = 'CENTRE';
  LatLng? _point;
  RoadRoute? _route;
  ScheduleSuggestion? _selected;
  List<ScheduleSuggestion>? _matches;
  bool _loading = true, _busy = false, _routeFailed = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ref
          .read(scheduleRepositoryProvider)
          .travelPreferences();
      if (!mounted) return;
      if (value != null) {
        setState(() {
          _campus = value.campus;
          _point = value.point;
          _radius = value.radiusMeters;
          _commute = value.commuteMinutes;
        });
        await _search();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choosePoint() async {
    final l = AppLocalizations.of(context);
    final point = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => MarrakechMapScreen(
          campus: _campus == 'TARGA' ? EmsiCampus.targa : EmsiCampus.centre,
          direction: CampusDirection.toCampus,
          campusLabel: _campus == 'TARGA' ? l.campusTarga : l.campusCentre,
          initialPoint: _point,
        ),
      ),
    );
    if (!mounted || point == null) return;
    setState(() {
      _point = point;
      _route = null;
      _selected = null;
      _matches = null;
    });
    await _search();
  }

  RidePath get _path {
    final campus = _campus == 'TARGA' ? EmsiCampus.targa : EmsiCampus.centre;
    final l = AppLocalizations.of(context);
    final campusLabel = _campus == 'TARGA' ? l.campusTarga : l.campusCentre;
    return RidePath(
      origin: _direction == 2 ? campus.point : _point!,
      destination: _direction == 2 ? _point! : campus.point,
      originLabel: _direction == 2 ? campusLabel : l.matchYourPoint,
      destinationLabel: _direction == 2 ? l.matchYourPoint : campusLabel,
      departure: DateTime.now(),
    );
  }

  Future<void> _search({bool recalculate = true}) async {
    if (_point == null || _busy) return;
    final revision = ++_searchRevision;
    setState(() {
      _busy = true;
      _error = null;
      _selected = null;
      _matches = null;
    });
    try {
      if (recalculate) {
        try {
          final route = await ref
              .read(roadRouteRepositoryProvider)
              .between(_path.origin, _path.destination);
          if (!mounted || revision != _searchRevision) return;
          _route = route;
          _commute = (route.durationSeconds / 60).ceil().clamp(5, 180);
          _routeFailed = false;
        } catch (_) {
          _route = null;
          _routeFailed = true;
        }
      }
      if (!mounted || revision != _searchRevision) return;
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.saveTravelPreferences(
        ScheduleTravelPreferences(
          campus: _campus,
          point: _point!,
          radiusMeters: _radius,
          commuteMinutes: _commute,
        ),
      );
      if (!mounted || revision != _searchRevision) return;
      ref.invalidate(scheduleTravelPreferencesProvider);
      final matches = await repository.suggestions(_commute);
      if (mounted && revision == _searchRevision) {
        setState(() => _matches = matches);
      }
    } catch (error) {
      if (mounted && revision == _searchRevision) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && revision == _searchRevision) setState(() => _busy = false);
    }
  }

  Future<void> _demo() async {
    if (_busy || _point == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authenticatedApiProvider)
          .request<Object>('POST', '/schedules/demo-rides');
      final matches = await ref
          .read(scheduleRepositoryProvider)
          .suggestions(_commute);
      if (mounted) {
        setState(() {
          _matches = matches;
          _selected = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(ScheduleSuggestion match) async {
    await context.push(AppRoutes.listing('offer', match.listing.id));
    if (mounted) await _search(recalculate: false);
  }

  void _select(ScheduleSuggestion match) {
    setState(() => _selected = match);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapContext = _mapKey.currentContext;
      if (mounted && mapContext != null) {
        Scrollable.ensureVisible(
          mapContext,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    final matches =
        _matches
            ?.where((m) => _direction == 0 || m.toCampus == (_direction == 1))
            .toList() ??
        [];
    final selected = _selected;
    return FlowPage(
      title: l.planningReserve,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(_campus),
                initialValue: _campus,
                decoration: InputDecoration(labelText: l.profileCampus),
                items: [
                  DropdownMenuItem(
                    value: 'CENTRE',
                    child: Text(l.campusCentre),
                  ),
                  DropdownMenuItem(value: 'TARGA', child: Text(l.campusTarga)),
                ],
                onChanged: _loading || _busy
                    ? null
                    : (value) async {
                        setState(() {
                          _campus = value!;
                          _route = null;
                          _selected = null;
                          _matches = null;
                        });
                        if (_point != null) await _search();
                      },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: _loading || _busy ? null : _choosePoint,
              tooltip: l.matchChoosePoint,
              icon: const Icon(Icons.edit_location_alt_outlined),
            ),
          ],
        ),
        if (_point == null) ...[
          Text(l.matchPointRequired),
          OutlinedButton.icon(
            onPressed: _loading ? null : _choosePoint,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(l.matchChoosePoint),
          ),
        ] else ...[
          MarketplaceMap(
            key: _mapKey,
            path: selected?.listing.path ?? _path,
            route: selected == null ? _route : null,
            previewOnOpen: selected != null,
            cityPoint: _point,
            offers: matches.map((m) => m.listing).toList(),
            selectedOfferId: selected?.listing.id,
            onOfferSelected: (offer) =>
                _select(matches.firstWhere((m) => m.listing.id == offer.id)),
          ),
          Text(
            l.matchPickupMarkers,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_routeFailed)
            Text(
              l.matchRouteFallback(_commute),
              style: TextStyle(color: colors.error),
            ),
          if (selected != null) _matchCard(selected, highlighted: true),
        ],
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null)
          Text(
            scheduleError(context, _error!),
            style: TextStyle(color: colors.error),
          ),
        FilledButton.icon(
          onPressed: _point == null || _loading || _busy ? null : _search,
          icon: const Icon(Icons.refresh),
          label: Text(l.matchSearch),
        ),
        ExpansionTile(
          title: Text(l.matchFilters),
          tilePadding: EdgeInsets.zero,
          children: [
            Text(l.matchRadius(_radius)),
            Slider(
              value: _radius.toDouble(),
              min: 100,
              max: 10000,
              divisions: 99,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _radius = value.round();
                      _matches = null;
                      _selected = null;
                    }),
            ),
            Text(l.timetableCommute(_commute)),
            Slider(
              value: _commute.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _commute = value.round();
                      _matches = null;
                      _selected = null;
                    }),
              onChangeEnd: _busy ? null : (_) => _search(recalculate: false),
            ),
            Text(
              l.routingPrivacyHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (_matches != null) ...[
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final (index, label) in [
                l.matchBothDirections,
                l.matchOutbound,
                l.matchReturn,
              ].indexed)
                ButtonSegment(value: index, label: Text(label)),
            ],
            selected: {_direction},
            onSelectionChanged: _busy
                ? null
                : (values) async {
                    setState(() {
                      _direction = values.single;
                      _selected = null;
                      _route = null;
                    });
                    await _search();
                  },
          ),
          if (matches.isEmpty) ...[
            Text(l.timetableNoMatches),
            TextButton(
              onPressed: () => context.push(AppRoutes.rideRequest),
              child: Text(l.matchCreateRequest),
            ),
          ] else ...[
            Text(
              l.matchOfferCount(matches.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final match in matches) _matchCard(match),
          ],
        ],
        if (kDebugMode && _point != null)
          OutlinedButton.icon(
            onPressed: _busy || _loading ? null : _demo,
            icon: const Icon(Icons.science_outlined),
            label: Text(l.matchAddDemoRides),
          ),
      ],
    );
  }

  Widget _matchCard(ScheduleSuggestion match, {bool highlighted = false}) {
    final l = AppLocalizations.of(context),
        colors = Theme.of(context).colorScheme;
    return Card(
      color: highlighted ? colors.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  child: Icon(
                    Icons.directions_car,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.listing.author,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${DateFormat("EEE dd/MM HH:mm", "fr").format(match.listing.path.departure)} · ${match.toCampus ? l.matchOutbound : l.matchReturn}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              children: [
                Text(l.seatsValue(match.listing.seats)),
                if (match.distanceMeters != null)
                  Text(l.matchDistance(match.distanceMeters!)),
              ],
            ),
            if (match.listing.notes?.startsWith('[TEST]') ?? false)
              Text(l.matchDemoLabel),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _select(match),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l.matchShowOnMap),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _open(match),
                    child: Text(l.matchReserve),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
