import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../../auth/data/session_id_provider.dart';

class StudentVehicle {
  const StudentVehicle({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.seats,
    this.color,
  });

  factory StudentVehicle.fromJson(Map<String, dynamic> json) => StudentVehicle(
    id: json['id'] as String,
    type: json['type'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    color: json['color'] as String?,
    seats: (json['seats'] as num).toInt(),
  );

  final String id, type, brand, model;
  final String? color;
  final int seats;

  Map<String, dynamic> toJson() => {
    'type': type,
    'brand': brand.trim(),
    'model': model.trim(),
    'color': color?.trim().isEmpty == true ? null : color?.trim(),
    'seats': seats,
  };
}

final vehiclesRepositoryProvider = Provider(
  (ref) => VehiclesRepository(ref.watch(authenticatedApiProvider)),
);

final vehiclesProvider = FutureProvider.autoDispose<List<StudentVehicle>>((
  ref,
) {
  ref.watch(sessionIdProvider);
  return ref.watch(vehiclesRepositoryProvider).load();
});

class VehiclesRepository {
  VehiclesRepository(this._api);
  final AuthenticatedApi _api;

  Future<List<StudentVehicle>> load() async {
    final rows = await _api.request<List<dynamic>>('GET', '/me/vehicles');
    return (rows ?? [])
        .map((row) => StudentVehicle.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(StudentVehicle vehicle) => _api.request<void>(
    vehicle.id.isEmpty ? 'POST' : 'PUT',
    vehicle.id.isEmpty ? '/me/vehicles' : '/me/vehicles/${vehicle.id}',
    data: vehicle.toJson(),
  );

  Future<void> remove(String id) =>
      _api.request<void>('DELETE', '/me/vehicles/$id');
}
