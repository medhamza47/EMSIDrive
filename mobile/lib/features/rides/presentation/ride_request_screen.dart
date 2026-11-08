import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/form_section.dart';
import '../../profile/data/profile_repository_provider.dart';
import '../data/marketplace_api.dart';
import '../domain/marketplace_models.dart';
import '../domain/marrakech_trip.dart';
import 'marrakech_map_screen.dart';

class RideRequestScreen extends ConsumerStatefulWidget {
  const RideRequestScreen({this.isOffer = false, super.key});

  final bool isOffer;

  @override
  ConsumerState<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  final _notes = TextEditingController();
  bool _publishing = false;
  late final _initialDeparture = DateTime.now().add(const Duration(hours: 1));
  late DateTime _date = DateUtils.dateOnly(_initialDeparture);
  late TimeOfDay _time = TimeOfDay.fromDateTime(_initialDeparture);
  late int _vehicle = widget.isOffer ? 1 : 2;
  bool _touched = false;
  int _seats = 1;
  EmsiCampus _campus = EmsiCampus.centre;
  CampusDirection _direction = CampusDirection.toCampus;
  LatLng? _cityPoint;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await ref.read(profileRepositoryProvider).loadProfile();
      if (!mounted || _touched) return;
      setState(() {
        _campus = profile.preferredCampus == 'TARGA'
            ? EmsiCampus.targa
            : EmsiCampus.centre;
        _vehicle = switch (profile.preferredVehicle) {
          'MOTO' => 0,
          'CAR' => 1,
          'ANY' => 2,
          _ => widget.isOffer ? 1 : 2,
        };
      });
    } catch (_) {
      /* Optional defaults must not prevent publishing a ride. */
    }
  }

  void _edit(VoidCallback update) => setState(() {
    _touched = true;
    update();
  });

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _publish(LatLng cityPoint) async {
    final l = AppLocalizations.of(context);
    final departure = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (!departure.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.departureMustBeFuture)));
      return;
    }
    setState(() => _publishing = true);
    try {
      await ref
          .read(marketplaceApiProvider)
          .publish(
            kind: widget.isOffer ? ListingKind.offer : ListingKind.request,
            trip: MarrakechTrip(
              campus: _campus,
              direction: _direction,
              cityPoint: cityPoint,
            ),
            departure: departure,
            seats: _seats,
            vehicle: const ['MOTO', 'CAR', 'ANY'][_vehicle],
            notes: _notes.text.trim(),
          );
      if (mounted) {
        context.go(
          '${AppRoutes.rides}?tab=${widget.isOffer ? 'offers' : 'requests'}',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.publishRideError)));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _campusName(EmsiCampus campus, AppLocalizations l) => switch (campus) {
    EmsiCampus.targa => l.campusTarga,
    EmsiCampus.centre => l.campusCentre,
  };

  Future<void> _chooseCityPoint() async {
    _touched = true;
    final l = AppLocalizations.of(context);
    final point = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => MarrakechMapScreen(
          campus: _campus,
          direction: _direction,
          campusLabel: _campusName(_campus, l),
          initialPoint: _cityPoint,
        ),
      ),
    );
    if (mounted && point != null) setState(() => _cityPoint = point);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (mounted && date != null) _edit(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (mounted && time != null) _edit(() => _time = time);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final vehicles = [l.vehicleMotorcycle, l.vehicleCar, l.vehicleAny];
    final cityPoint = _cityPoint;
    final toCampus = _direction == CampusDirection.toCampus;
    final campusField = DropdownButtonFormField<EmsiCampus>(
      initialValue: _campus,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: toCampus ? l.tripDestination : l.tripOrigin,
        prefixIcon: const Icon(Icons.school_outlined),
        helperText: _campus == EmsiCampus.centre ? l.campusCentreAddress : null,
      ),
      items: [
        for (final campus in EmsiCampus.values)
          DropdownMenuItem(value: campus, child: Text(_campusName(campus, l))),
      ],
      onChanged: (campus) {
        if (campus != null) _edit(() => _campus = campus);
      },
    );
    final cityField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(toCampus ? l.tripOrigin : l.tripDestination),
        OutlinedButton.icon(
          onPressed: _chooseCityPoint,
          icon: const Icon(Icons.map_outlined),
          label: Text(cityPoint == null ? l.chooseMapPoint : l.changeMapPoint),
        ),
        if (cityPoint != null)
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(l.ridePointReady)),
            ],
          ),
      ],
    );
    return FlowPage(
      title: widget.isOffer ? l.offerTitle : l.requestTitle,
      children: [
        FormSection(
          title: l.rideFormRoute,
          subtitle: l.rideFormRouteHint,
          icon: Icons.route_rounded,
          children: [
            Text(l.campusDirectionHint),
            SegmentedButton<CampusDirection>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: CampusDirection.toCampus,
                  label: Text(l.towardCampus),
                ),
                ButtonSegment(
                  value: CampusDirection.fromCampus,
                  label: Text(l.fromCampus),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) =>
                  _edit(() => _direction = selection.single),
            ),
            if (toCampus) ...[
              cityField,
              campusField,
            ] else ...[
              campusField,
              cityField,
            ],
          ],
        ),
        FormSection(
          title: l.rideFormDeparture,
          icon: Icons.calendar_today_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat.MMMEd('fr').format(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
        FormSection(
          title: l.rideFormDetails,
          icon: Icons.airline_seat_recline_normal_outlined,
          children: [
            Text(
              l.vehiclePreference,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final (index, vehicle) in vehicles.indexed)
                  ChoiceChip(
                    label: Text(vehicle),
                    selected: _vehicle == index,
                    onSelected: (_) => _edit(() {
                      _vehicle = index;
                      if (index == 0) _seats = 1;
                    }),
                  ),
              ],
            ),
            Text(l.seatCount, style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(child: Text(l.seatsValue(_seats))),
                IconButton.outlined(
                  tooltip: l.removeSeat,
                  icon: const Icon(Icons.remove),
                  onPressed: _seats > 1 ? () => _edit(() => _seats--) : null,
                ),
                IconButton.outlined(
                  tooltip: l.addSeat,
                  icon: const Icon(Icons.add),
                  onPressed: _vehicle != 0 && _seats < 4
                      ? () => _edit(() => _seats++)
                      : null,
                ),
              ],
            ),
            TextField(
              controller: _notes,
              onChanged: (_) => _touched = true,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.optionalMessage,
                hintText: l.demoRideMessage,
              ),
            ),
          ],
        ),
        if (cityPoint != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: FlowCopy(
                l.rideFormSummary,
                '${toCampus ? l.towardCampus : l.fromCampus} · ${_campusName(_campus, l)}\n${DateFormat.MMMEd('fr').format(_date)} · ${_time.format(context)} · ${l.seatsValue(_seats)}',
              ),
            ),
          ),
        PrimaryButton(
          label: widget.isOffer ? l.publishOffer : l.publishRequest,
          isLoading: _publishing,
          onPressed: cityPoint == null ? null : () => _publish(cityPoint),
        ),
      ],
    );
  }
}
