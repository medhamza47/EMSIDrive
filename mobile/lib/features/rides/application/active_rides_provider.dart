import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/session_id_provider.dart';
import '../data/marketplace_api.dart';
import '../domain/marketplace_models.dart';

final activeRidesProvider = StreamProvider.autoDispose<List<AcceptedRide>>((
  ref,
) {
  ref.watch(sessionIdProvider);
  final api = ref.watch(marketplaceApiProvider);
  final stream = StreamController<List<AcceptedRide>>();
  var busy = false;
  Future<void> poll() async {
    if (busy ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    busy = true;
    try {
      final rides = await api.trips();
      if (!stream.isClosed) {
        stream.add(
          rides
              .where(
                (r) =>
                    r.stage.active &&
                    (r.stage != RideStage.confirmed ||
                        r.path.departure.isAfter(
                          DateTime.now().subtract(const Duration(hours: 12)),
                        )),
              )
              .toList()
            ..sort(
              (a, b) => (a.stage == RideStage.confirmed ? 1 : 0).compareTo(
                b.stage == RideStage.confirmed ? 1 : 0,
              ),
            ),
        );
      }
    } catch (error, stack) {
      if (!stream.isClosed) stream.addError(error, stack);
    } finally {
      busy = false;
    }
  }

  unawaited(poll());
  final timer = Timer.periodic(const Duration(seconds: 8), (_) => poll());
  ref.onDispose(() {
    timer.cancel();
    unawaited(stream.close());
  });
  return stream.stream;
});
