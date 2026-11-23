import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../auth/data/session_id_provider.dart';
import '../../auth/data/token_storage_provider.dart';
import '../data/marketplace_api.dart';

class DriverLocationSource {
  Future<Stream<Position>> open(String title, String text) async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      throw StateError('foreground');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('denied');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await const MethodChannel('emsidrive/notifications')
          .invokeMethod<bool>('requestPermission');
    }
    return Geolocator.getPositionStream(
      locationSettings: defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 5),
              foregroundNotificationConfig: ForegroundNotificationConfig(
                notificationTitle: title,
                notificationText: text,
                notificationChannelName: title,
                enableWakeLock: true,
                setOngoing: true,
              ),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
    );
  }
}

final driverLocationSourceProvider = Provider((ref) => DriverLocationSource());
final driverTrackingProvider =
    NotifierProvider<DriverTrackingController, DriverTrackingState>(
      DriverTrackingController.new,
    );

class DriverTrackingState {
  const DriverTrackingState({
    this.tripId,
    this.busy = false,
    this.error,
    this.lastSent,
  });
  final String? tripId, error;
  final bool busy;
  final DateTime? lastSent;
}

class DriverTrackingController extends Notifier<DriverTrackingState> {
  StreamSubscription<Position>? _positions;
  Timer? _timer;
  Position? _latest;
  Future<void>? _sending;
  int _generation = 0;
  late MarketplaceApi _api;
  late bool Function() _sameSession;
  DateTime? _started, _checked;
  bool _checking = false;

  @override
  DriverTrackingState build() {
    final session = ref.watch(sessionIdProvider);
    final tokens = ref.watch(tokenStorageProvider);
    _api = ref.watch(marketplaceApiProvider);
    _sameSession = () => tokens.session == session;
    ref.onDispose(() {
      _generation++;
      _timer?.cancel();
      unawaited(_positions?.cancel());
    });
    return const DriverTrackingState();
  }

  Future<void> start(String tripId, String title, String text) async {
    await stop();
    if (!ref.mounted) return;
    final generation = ++_generation;
    state = const DriverTrackingState(busy: true);
    try {
      final stream = await ref
          .read(driverLocationSourceProvider)
          .open(title, text);
      if (!ref.mounted || generation != _generation || !_sameSession()) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.paused ||
          lifecycle == AppLifecycleState.hidden ||
          lifecycle == AppLifecycleState.detached) {
        throw StateError('foreground');
      }
      _latest = null;
      _started = DateTime.now();
      _checked = null;
      state = DriverTrackingState(tripId: tripId);
      _positions = stream.listen(
        (position) {
          if (!ref.mounted || generation != _generation) return;
          _latest = position;
          _publish(generation);
        },
        onError: (Object _) {
          if (ref.mounted && generation == _generation) {
            state = DriverTrackingState(tripId: tripId, error: 'gps');
          }
        },
      );
      _timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _publish(generation),
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = DriverTrackingState(
          error: error is StateError ? error.message.toString() : 'gps',
        );
      }
    }
  }

  void _publish(int generation) {
    if (!ref.mounted ||
        generation != _generation ||
        state.tripId == null ||
        !_sameSession()) {
      return;
    }
    if (DateTime.now().difference(_started!).inHours >= 4) {
      unawaited(stop());
      return;
    }
    if (!_checking &&
        (_checked == null ||
            DateTime.now().difference(_checked!).inSeconds >= 15)) {
      _checking = true;
      _checked = DateTime.now();
      _api
          .trip(state.tripId!)
          .then((ride) async {
            if (!ref.mounted ||
                generation != _generation ||
                ride.stage.active) {
              return;
            }
            final others = await _api.trips();
            if (!ref.mounted || generation != _generation) return;
            final next = others
                .where(
                  (r) =>
                      r.isDriver && r.stage.active && r.offerId == ride.offerId,
                )
                .firstOrNull;
            if (next == null) {
              unawaited(stop());
            } else {
              state = DriverTrackingState(
                tripId: next.id,
                lastSent: state.lastSent,
              );
            }
          })
          .catchError((Object _) {})
          .whenComplete(() => _checking = false);
    }
    final position = _latest;
    if (position == null || _sending != null || _checking) return;
    if (DateTime.now().difference(position.timestamp).inSeconds >= 25 ||
        !position.accuracy.isFinite ||
        position.accuracy > 150) {
      state = DriverTrackingState(
        tripId: state.tripId,
        error: 'gps',
        lastSent: state.lastSent,
      );
      return;
    }
    final trip = state.tripId!;
    final operation = _send(trip, position, generation);
    _sending = operation;
    unawaited(operation.whenComplete(() => _sending = null));
  }

  Future<void> _send(String trip, Position position, int generation) async {
    try {
      await _api.location(
        trip,
        LatLng(position.latitude, position.longitude),
        capturedAt: position.timestamp,
        accuracy: position.accuracy,
        heading:
            position.heading.isFinite &&
                position.heading >= 0 &&
                position.heading <= 360
            ? position.heading
            : null,
      );
      if (ref.mounted && generation == _generation) {
        state = DriverTrackingState(tripId: trip, lastSent: DateTime.now());
      }
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = DriverTrackingState(
        tripId: trip,
        error: 'network',
        lastSent: state.lastSent,
      );
      if (error is DioException &&
          [403, 404].contains(error.response?.statusCode)) {
        unawaited(Future.microtask(stop));
      }
      if (error is DioException && error.response?.statusCode == 409) {
        // Re-select another passenger of the same offer after a cancellation.
        _checked = null;
      }
    }
  }

  Future<void> stop() async {
    if (!ref.mounted) return;
    final trip = state.tripId;
    final api = _api;
    final sameSession = _sameSession;
    _generation++;
    _timer?.cancel();
    _latest = null;
    final positions = _positions;
    _positions = null;
    state = const DriverTrackingState();
    await positions?.cancel();
    await _sending;
    if (trip != null && sameSession()) {
      try {
        await api.location(trip, null);
      } catch (_) {
        /* Server fixes expire after 30 seconds. */
      }
    }
  }
}
