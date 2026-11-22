import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/session_id_provider.dart';
import '../../profile/presentation/profile_edit_screen.dart';
import '../data/vehicles_repository.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  bool _deleting = false;

  Future<void> _edit([StudentVehicle? vehicle]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => VehicleEditScreen(vehicle: vehicle)),
    );
  }

  Future<void> _remove(StudentVehicle vehicle) async {
    final l = AppLocalizations.of(context);
    final session = ref.read(sessionIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.vehiclesDelete),
        content: Text(
          l.vehiclesDeleteConfirm('${vehicle.brand} ${vehicle.model}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.vehiclesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.vehiclesDelete),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        ref.read(sessionIdProvider) != session) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref.read(vehiclesRepositoryProvider).remove(vehicle.id);
      if (mounted && ref.read(sessionIdProvider) == session) {
        ref.invalidate(vehiclesProvider);
      }
    } catch (error) {
      if (mounted && ref.read(sessionIdProvider) == session) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileFailure(l, ErrorMapper.map(error)))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.vehiclesTitle,
      children: [
        Text(l.vehiclesDescription),
        PrimaryButton(
          label: l.vehiclesAdd,
          icon: Icons.add,
          onPressed: _deleting ? null : () => _edit(),
        ),
        ref
            .watch(vehiclesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => AppCard(
                child: Column(
                  children: [
                    Text(profileFailure(l, ErrorMapper.map(error))),
                    TextButton(
                      onPressed: () => ref.invalidate(vehiclesProvider),
                      child: Text(l.retryLabel),
                    ),
                  ],
                ),
              ),
              data: (vehicles) => Column(
                spacing: 16,
                children: [
                  if (vehicles.isEmpty) AppCard(child: Text(l.vehiclesEmpty)),
                  for (final vehicle in vehicles)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          Row(
                            children: [
                              Icon(
                                vehicle.type == 'MOTO'
                                    ? Icons.two_wheeler
                                    : Icons.directions_car_outlined,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${vehicle.brand} ${vehicle.model}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            vehicle.type == 'MOTO'
                                ? l.vehicleMotorcycle
                                : l.vehicleCar,
                          ),
                          if (vehicle.color?.isNotEmpty == true)
                            Text(vehicle.color!),
                          Text(l.vehiclesSeatCount(vehicle.seats)),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton.icon(
                                onPressed: _deleting
                                    ? null
                                    : () => _edit(vehicle),
                                icon: const Icon(Icons.edit_outlined),
                                label: Text(l.vehiclesEdit),
                              ),
                              TextButton.icon(
                                onPressed: _deleting
                                    ? null
                                    : () => _remove(vehicle),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l.vehiclesDelete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class VehicleEditScreen extends ConsumerStatefulWidget {
  const VehicleEditScreen({this.vehicle, super.key});
  final StudentVehicle? vehicle;
  @override
  ConsumerState<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  late final int _session;

  @override
  void initState() {
    super.initState();
    _session = ref.read(sessionIdProvider);
  }

  final _form = GlobalKey<FormState>();
  late final _brand = TextEditingController(text: widget.vehicle?.brand);
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late final _color = TextEditingController(text: widget.vehicle?.color);
  late String _type = widget.vehicle?.type ?? 'VOITURE';
  late int _seats = widget.vehicle?.seats ?? 4;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        ref.read(sessionIdProvider) != _session ||
        !_form.currentState!.validate()) {
      return;
    }
    final session = ref.read(sessionIdProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(vehiclesRepositoryProvider)
          .save(
            StudentVehicle(
              id: widget.vehicle?.id ?? '',
              type: _type,
              brand: _brand.text,
              model: _model.text,
              color: _color.text,
              seats: _seats,
            ),
          );
      if (!mounted || ref.read(sessionIdProvider) != session) return;
      ref.invalidate(vehiclesProvider);
      Navigator.pop(context);
    } catch (error) {
      if (mounted && ref.read(sessionIdProvider) == session) {
        setState(
          () => _error = profileFailure(
            AppLocalizations.of(context),
            ErrorMapper.map(error),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (ref.watch(sessionIdProvider) != _session) {
      return FlowPage(
        title: l.vehiclesTitle,
        showNotifications: false,
        children: [Text(l.profileSignIn)],
      );
    }
    return PopScope(
      canPop: !_saving,
      child: FlowPage(
        title: widget.vehicle == null ? l.vehiclesAdd : l.vehiclesEdit,
        showNotifications: false,
        children: [
          Form(
            key: _form,
            child: Column(
              spacing: 16,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(labelText: l.vehiclesType),
                  items: [
                    DropdownMenuItem(
                      value: 'VOITURE',
                      child: Text(l.vehicleCar),
                    ),
                    DropdownMenuItem(
                      value: 'MOTO',
                      child: Text(l.vehicleMotorcycle),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                TextFormField(
                  controller: _brand,
                  enabled: !_saving,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l.vehiclesBrand),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l.vehiclesRequired
                      : null,
                ),
                TextFormField(
                  controller: _model,
                  enabled: !_saving,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l.vehiclesModel),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l.vehiclesRequired
                      : null,
                ),
                TextFormField(
                  controller: _color,
                  enabled: !_saving,
                  maxLength: 30,
                  decoration: InputDecoration(labelText: l.vehiclesColor),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _seats,
                  decoration: InputDecoration(labelText: l.vehiclesSeats),
                  items: [
                    for (var seats = 1; seats <= 8; seats++)
                      DropdownMenuItem(value: seats, child: Text('$seats')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _seats = value!),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                PrimaryButton(
                  label: l.vehiclesSave,
                  onPressed: _save,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
