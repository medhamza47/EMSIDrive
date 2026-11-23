import 'dart:async';

import 'package:emsidrive_mobile/features/rides/application/active_rides_provider.dart';
import 'package:emsidrive_mobile/features/rides/data/marketplace_api.dart';
import 'package:emsidrive_mobile/features/rides/domain/marketplace_models.dart';
import 'package:emsidrive_mobile/features/rides/presentation/marketplace_screens.dart';
import 'package:emsidrive_mobile/features/rides/presentation/ride_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import 'live_tracking_test.dart' show fixture;

class BoardApi implements MarketplaceApi {
  final calls = <String>[];
  bool failRequests = false;
  String stage = 'CONFIRMED';
  @override
  Future<List<RideListing>> listings(
    ListingKind kind, {
    bool mine = false,
  }) async {
    calls.add(kind.name);
    if (failRequests && kind == ListingKind.request) {
      throw StateError('offline');
    }
    return [
      RideListing.fromJson({
        ...fixture(DateTime.now()),
        'id': 'offer',
        'author': kind.name,
        'own': false,
        'can_accept': true,
        'seats': 2,
      }, kind),
    ];
  }

  @override
  Future<List<AcceptedRide>> trips({bool history = false}) async {
    calls.add('mine');
    return [AcceptedRide.fromJson(fixture(DateTime.now(), stage: stage))];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('all three ride tabs load their own content and retry errors', (
    tester,
  ) async {
    final api = BoardApi();
    await pumpWidgetWithApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(child: MarketplaceBoard(initialTab: 1)),
      ),
      overrides: [
        marketplaceApiProvider.overrideWithValue(api),
        activeRidesProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    expect(find.text('offer'), findsOneWidget);
    api.failRequests = true;
    await tester.tap(find.byKey(const ValueKey('rides-tab-0')));
    await tester.pumpAndSettle();
    expect(find.text(l10nOf().marketplaceLoadError), findsOneWidget);
    api.failRequests = false;
    await tester.tap(find.text(l10nOf().retryLabel));
    await tester.pumpAndSettle();
    expect(find.text('request'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rides-tab-2')));
    await tester.pumpAndSettle();
    expect(api.calls.last, 'mine');
    expect(find.byType(RideSummaryCard), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rides-tab-1')));
    await tester.pumpAndSettle();
    expect(api.calls.last, 'offer');
    expect(find.text('offer'), findsOneWidget);
  });

  testWidgets(
    'active booking replaces ordinary offer and cancellation restores it',
    (tester) async {
      final api = BoardApi();
      final stream = StreamController<List<AcceptedRide>>();
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: MarketplaceBoard(initialTab: 1)),
        ),
        overrides: [
          marketplaceApiProvider.overrideWithValue(api),
          activeRidesProvider.overrideWith((ref) => stream.stream),
        ],
      );
      stream.add([AcceptedRide.fromJson(fixture(DateTime.now()))]);
      await tester.pumpAndSettle();
      expect(find.byType(RideSummaryCard), findsOneWidget);
      expect(
        tester
            .widget<RideSummaryCard>(find.byType(RideSummaryCard))
            .activeStatus,
        isNotNull,
      );
      stream.add([]);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RideSummaryCard>(find.byType(RideSummaryCard))
            .activeStatus,
        isNull,
      );
      expect(find.text('offer'), findsOneWidget);
      api.stage = 'COMPLETED';
      await tester.tap(find.byKey(const ValueKey('rides-tab-2')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RideSummaryCard>(find.byType(RideSummaryCard))
            .activeStatus,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      unawaited(stream.close());
    },
  );
}
