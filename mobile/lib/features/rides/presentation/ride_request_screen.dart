import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({this.isOffer = false, super.key});

  final bool isOffer;

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _form = GlobalKey<FormState>();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 15);
  int _vehicle = 0;
  int _seats = 1;

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
    String? requiredField(String? value) =>
        value == null || value.trim().isEmpty ? l.flowRequired : null;
    return Form(
      key: _form,
      child: FlowPage(
        title: widget.isOffer ? l.offerTitle : l.requestTitle,
        children: [
          TextFormField(
            initialValue: l.demoOrigin,
            validator: requiredField,
            decoration: InputDecoration(
              labelText: l.tripOrigin,
              prefixIcon: const Icon(Icons.my_location),
            ),
          ),
          TextFormField(
            initialValue: l.demoCampus,
            validator: requiredField,
            decoration: InputDecoration(
              labelText: l.tripDestination,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
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
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l.optionalMessage,
              hintText: l.demoRideMessage,
            ),
          ),
          PrimaryButton(
            label: widget.isOffer ? l.publishOffer : l.publishRequest,
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              if (widget.isOffer) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.demoOfferSaved)));
                context.pop();
              } else {
                context.push(AppRoutes.nearbyDrivers);
              }
            },
          ),
        ],
      ),
    );
  }
}
