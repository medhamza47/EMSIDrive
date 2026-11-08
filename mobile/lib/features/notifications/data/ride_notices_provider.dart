import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rides/data/marketplace_api.dart';
import '../../rides/domain/marketplace_models.dart';

final rideNoticesProvider = StreamProvider.autoDispose<List<RideNotice>>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  final updates = StreamController<List<RideNotice>>();
  var loading = false;

  Future<void> refresh() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (loading ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    loading = true;
    try {
      final items = await api.notices();
      if (!updates.isClosed) updates.add(items);
    } catch (error, stack) {
      if (!updates.isClosed) updates.addError(error, stack);
    } finally {
      loading = false;
    }
  }

  unawaited(refresh());
  final timer = Timer.periodic(const Duration(seconds: 8), (_) => refresh());
  ref.onDispose(() {
    timer.cancel();
    unawaited(updates.close());
  });
  return updates.stream;
});
