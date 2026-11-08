import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/dio_client_provider.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/data/token_storage_provider.dart';
import '../domain/marketplace_models.dart';
import '../domain/marrakech_trip.dart';

final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi(
    ref.watch(dioClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class MarketplaceApi {
  MarketplaceApi(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;
  Future<String?>? _refreshing;

  Future<String?> _refresh(int session) async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || _tokens.session != session) return null;
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final access = response.data!['accessToken'] as String;
    final refresh = response.data!['refreshToken'] as String;
    final saved = await _tokens.rotate(
      session,
      accessToken: access,
      refreshToken: refresh,
    );
    return saved ? access : null;
  }

  Future<T?> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final session = _tokens.session;
    final token = await _tokens.readAccessToken();
    if (token == null || _tokens.session != session) {
      throw StateError('Sign-in required');
    }
    Future<T?> send(String token) async => (await _dio.request<T>(
      '/marketplace$path',
      data: data,
      queryParameters: query,
      options: Options(
        method: method,
        headers: {'Authorization': 'Bearer $token'},
      ),
    )).data;

    try {
      return await send(token);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _tokens.session != session) {
        rethrow;
      }
      var replacement = await _tokens.readAccessToken();
      if (replacement == token) {
        final operation = _refreshing ??= _refresh(session);
        try {
          replacement = await operation;
        } finally {
          if (identical(_refreshing, operation)) _refreshing = null;
        }
      }
      if (replacement == null || _tokens.session != session) rethrow;
      return send(replacement);
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final rows = await _request<List<dynamic>>('GET', path, query: query);
    return rows!.cast<Map<String, dynamic>>();
  }

  Future<List<RideListing>> listings(ListingKind kind) async => [
    for (final item in await _list(
      '/listings',
      query: {'kind': kind.name.toUpperCase()},
    ))
      RideListing.fromJson(item, kind),
  ];

  Future<RideListing> listing(ListingKind kind, String id) async =>
      RideListing.fromJson(
        (await _request<Map<String, dynamic>>(
          'GET',
          '/listings/${kind.name.toUpperCase()}/$id',
        ))!,
        kind,
      );

  Future<void> publish({
    required ListingKind kind,
    required MarrakechTrip trip,
    required DateTime departure,
    required int seats,
    required String vehicle,
    required String notes,
  }) async {
    await _request<Map<String, dynamic>>(
      'POST',
      '/listings',
      data: {
        'kind': kind.name.toUpperCase(),
        'campus': trip.campus.name.toUpperCase(),
        'toCampus': trip.direction == CampusDirection.toCampus,
        'point': _point(trip.cityPoint),
        'departure': departure.toUtc().toIso8601String(),
        'seats': seats,
        'vehicle': vehicle,
        'notes': notes,
      },
    );
  }

  Future<String> accept(RideListing listing) async =>
      (await _request<Map<String, dynamic>>(
            'POST',
            '/listings/${listing.kind.name.toUpperCase()}/${listing.id}/accept',
          ))!['id']
          as String;

  Future<List<AcceptedRide>> trips() async => [
    for (final item in await _list('/trips')) AcceptedRide.fromJson(item),
  ];

  Future<AcceptedRide> trip(String id) async => AcceptedRide.fromJson(
    (await _request<Map<String, dynamic>>('GET', '/trips/$id'))!,
  );

  Future<List<RideMessage>> messages(String id, int after) async => [
    for (final item in await _list(
      '/trips/$id/messages',
      query: {'after': after},
    ))
      RideMessage.fromJson(item),
  ];

  Future<void> send(String id, String body) async {
    await _request<Object>('POST', '/trips/$id/messages', data: {'body': body});
  }

  Future<void> location(String id, LatLng? point) async {
    await _request<Object>(
      point == null ? 'DELETE' : 'PUT',
      '/trips/$id/location',
      data: point == null ? null : _point(point),
    );
  }

  Future<List<RideNotice>> notices() async => [
    for (final item in await _list('/notifications')) RideNotice.fromJson(item),
  ];

  Future<void> markRead(String id) async {
    await _request<Object>('PUT', '/notifications/$id/read');
  }

  Map<String, double> _point(LatLng point) => {
    'latitude': point.latitude,
    'longitude': point.longitude,
  };
}
