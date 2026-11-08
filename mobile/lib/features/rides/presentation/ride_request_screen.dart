import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/marrakech_trip.dart';
import 'marrakech_map_screen.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({this.isOffer = false, super.key});

  final bool isOffer;

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 15);
  int _vehicle = 0;
  int _seats = 1;
  EmsiCampus _campus = EmsiCampus.centre;
  CampusDirection _direction = CampusDirection.toCampus;
  LatLng? _cityPoint;

  String _campusName(EmsiCampus campus, AppLocalizations l) => switch (campus) {
    EmsiCampus.targa => l.campusTarga,
    EmsiCampus.centre => l.campusCentre,
  };

  Future<void> _chooseCityPoint() async {
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
    if (mounted && date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (mounted && time != null) setState(() => _time = time);
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
        if (campus != null) setState(() => _campus = campus);
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
          Text(
            l.chosenCoordinates(
              cityPoint.latitude.toStringAsFixed(5),
              cityPoint.longitude.toStringAsFixed(5),
            ),
          ),
      ],
    );
    return FlowPage(
      title: widget.isOffer ? l.offerTitle : l.requestTitle,
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
              setState(() => _direction = selection.single),
        ),
        if (toCampus) ...[
          cityField,
          campusField,
        ] else ...[
          campusField,
          cityField,
        ],
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
                onSelected: (_) => setState(() {
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
              onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
            ),
            IconButton.outlined(
              tooltip: l.addSeat,
              icon: const Icon(Icons.add),
              onPressed: _vehicle != 0 && _seats < 4
                  ? () => setState(() => _seats++)
                  : null,
            ),
          ],
        ),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l.optionalMessage,
            hintText: l.demoRideMessage,
          ),
        ),
        PrimaryButton(
          label: widget.isOffer ? l.publishOffer : l.publishRequest,
          onPressed: cityPoint == null
              ? null
              : () {
                  if (widget.isOffer) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.demoOfferSaved)));
                    context.pop();
                  } else {
                    context.push(AppRoutes.nearbyDrivers);
                  }
                },
        ),
      ],
    );
  }
}
