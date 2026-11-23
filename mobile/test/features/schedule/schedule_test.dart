import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/features/schedule/data/schedule_repository.dart';
import 'package:emsidrive_mobile/features/schedule/domain/schedule_models.dart';
import 'package:emsidrive_mobile/features/schedule/presentation/schedule_screens.dart';
import 'package:emsidrive_mobile/features/matching/presentation/suggestion_screens.dart';
import 'package:emsidrive_mobile/shared/widgets/primary_button.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:emsidrive_mobile/features/schedule/presentation/planning_screen.dart';
import 'package:emsidrive_mobile/features/rides/data/road_route_repository.dart';
import 'package:emsidrive_mobile/features/rides/domain/marrakech_trip.dart';

import '../../helpers/pump_app.dart';

class FakeRoadRoutes extends RoadRouteRepository {
  @override
  Future<RoadRoute> between(LatLng origin, LatLng destination) async =>
      RoadRoute(
        points: [origin, destination],
        distanceMeters: 3000,
        durationSeconds: 600,
      );
}

class FakeSchedules implements ScheduleRepository {
  Timetable? stored;
  int saves = 0;
  ScheduleImportJob? job;
  ScheduleTravelPreferences? preferences;
  List<ScheduleSuggestion> offers = [];
  @override
  Future<ScheduleImportJob?> latestImport() async => job;
  @override
  Future<void> dismissImport(String id) async {
    job = null;
  }

  @override
  Future<ScheduleImportJob> startImport(
    Uint8List bytes,
    String filename,
    String group,
    int revision,
    CancelToken cancel,
  ) => throw UnimplementedError();
  @override
  Future<ScheduleTravelPreferences?> travelPreferences() async => preferences;
  @override
  Future<void> saveTravelPreferences(ScheduleTravelPreferences value) async {
    preferences = value;
  }

  @override
  Future<Timetable?> current() async => stored;
  @override
  Future<Timetable> save(Timetable timetable) async {
    saves++;
    if (timetable.analysisJobId == job?.id) job = null;
    return stored = timetable;
  }

  @override
  Future<void> delete() async {
    stored = null;
  }

  @override
  Future<List<ScheduleSuggestion>> suggestions(int commuteMinutes) async =>
      offers;
  @override
  Future<Timetable> analyze(
    Uint8List bytes,
    String filename,
    String group,
    int revision,
    CancelToken cancel,
  ) => throw UnimplementedError();
}

const course = CourseSlot(
  label: 'ERP',
  weekday: 1,
  startTime: '08:30',
  endTime: '10:00',
  campus: 'CENTRE',
);
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('digital attendance keeps first arrival and last departure without subjects', () {
    const timetable = Timetable(
      name: 'G1',
      source: 'IMAGE',
      slots: [
        CourseSlot(
          label: 'Ignored',
          weekday: 1,
          startTime: '08:30',
          endTime: '11:45',
        ),
        CourseSlot(
          label: 'Ignored',
          weekday: 1,
          startTime: '14:00',
          endTime: '16:30',
        ),
        CourseSlot(weekday: 3, startTime: '09:00', endTime: '12:00'),
      ],
    );
    expect(timetable.attendance, hasLength(2));
    expect(timetable.attendance.first.arrival, '08:30');
    expect(timetable.attendance.first.leaving, '16:30');
    expect(timetable.slots, hasLength(3));
  });
  testWidgets(
    'completed background import is recovered and saved from planning',
    (tester) async {
      final repo = FakeSchedules()
        ..job = ScheduleImportJob.fromJson({
          'id': 'job-1',
          'status': 'SUCCEEDED',
          'revision': 0,
          'draft': {
            'name': 'G1',
            'source': 'IMAGE',
            'warnings': [],
            'slots': [
              {
                'weekday': 1,
                'startTime': '08:30',
                'endTime': '16:30',
                'needsReview': false,
              },
            ],
          },
        });
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.planning,
        overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      );
      expect(find.byType(PlanningScreen), findsOneWidget);
      expect(find.text(l10nOf().importReadyTitle), findsOneWidget);
      await tester.ensureVisible(find.text(l10nOf().importReviewPresence));
      await tester.tap(find.text(l10nOf().importReviewPresence));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(l10nOf().presenceArrival('08:30')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(repo.stored!.analysisJobId, 'job-1');
      expect(repo.stored!.toJson()['analysisJobId'], 'job-1');
      expect(repo.job, isNull);
    },
  );
  test('days and times are sufficient without a subject or a place', () {
    expect(
      const CourseSlot(
        weekday: 1,
        startTime: '08:30',
        endTime: '11:30',
      ).complete,
      isTrue,
    );
  });
  test(
    'normalizes backend times and detects overlaps without rejecting adjacency',
    () {
      final parsed = CourseSlot.fromJson({
        'label': 'ERP',
        'weekday': 1,
        'startTime': '08:30:00',
        'endTime': '10:00:00',
        'campus': 'CENTRE',
      });
      expect(parsed.complete, isTrue);
      expect(parsed.startTime, '08:30');
      expect(
        Timetable.overlaps([
          course,
          const CourseSlot(
            label: 'Java',
            weekday: 1,
            startTime: '09:00',
            endTime: '11:00',
            campus: 'TARGA',
          ),
        ]),
        isTrue,
      );
      expect(
        Timetable.overlaps([
          course,
          const CourseSlot(
            label: 'Java',
            weekday: 1,
            startTime: '10:00',
            endTime: '11:00',
            campus: 'TARGA',
          ),
        ]),
        isFalse,
      );
      expect(
        const CourseSlot(
          label: 'Unknown',
          weekday: 1,
          startTime: '28:00',
          endTime: '29:00',
        ).complete,
        isFalse,
      );
    },
  );
  testWidgets('empty account has no sample file and cannot analyze', (
    tester,
  ) async {
    final repo = FakeSchedules();
    await pumpWidgetWithApp(
      tester,
      const ScheduleImportScreen(),
      overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
    );
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(find.text(l10nOf().timetableManual), findsOneWidget);
    expect(find.text('ERP'), findsNothing);
  });
  testWidgets(
    'requires confirmation and persists corrected courses through repository',
    (tester) async {
      final repo = FakeSchedules();
      final draft = Timetable(
        name: 'G1',
        source: 'IMAGE',
        slots: const [
          CourseSlot(weekday: 1, startTime: '08:30', endTime: '11:30'),
        ],
        validFrom: DateTime(2026, 9, 1),
        validUntil: DateTime(2027, 1, 31),
        revision: 3,
      );
      repo.stored = draft;
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.scheduleSlots,
        overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.stored!.revision, 3);
      expect(repo.stored!.slots.single.label, isNull);
      expect(repo.stored!.slots.single.campus, isNull);
      expect(find.byType(ScheduleSlotsScreen), findsNothing);
      expect(find.byType(SuggestionsScreen), findsOneWidget);
    },
  );
  testWidgets(
    'incomplete extracted course blocks confirmation until corrected',
    (tester) async {
      final repo = FakeSchedules();
      final draft = Timetable(
        name: 'G1',
        source: 'IMAGE',
        slots: const [
          CourseSlot(
            label: 'ERP',
            weekday: 1,
            startTime: '08:30',
            endTime: null,
            campus: 'CENTRE',
            needsReview: true,
          ),
        ],
        validFrom: DateTime(2026, 9, 1),
        validUntil: DateTime(2027, 1, 31),
      );
      await pumpWidgetWithApp(
        tester,
        ScheduleSlotsScreen(initial: draft),
        overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(find.text(l10nOf().timetableMissingTimes(1)), findsOneWidget);
      expect(find.text('ERP'), findsNothing);
      await tester.ensureVisible(find.text(l10nOf().monday));
      await tester.tap(find.text(l10nOf().monday));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '10:00');
      await tester.tap(find.text(l10nOf().timetableValidateCourse));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNotNull,
      );
    },
  );
  testWidgets(
    'new import can be confirmed and saved without editing every complete slot',
    (tester) async {
      final now = DateTime.now();
      final repo = FakeSchedules()
        ..stored = const Timetable(
          name: '',
          source: 'IMAGE',
          slots: [
            CourseSlot(
              weekday: 1,
              startTime: '08:30',
              endTime: '11:45',
              needsReview: true,
            ),
          ],
        );
      await pumpEmsiDriveApp(
        tester,
        initialLocation: AppRoutes.scheduleSlots,
        overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      );
      expect(find.text(l10nOf().timetableSuggestedDates), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNotNull,
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.stored!.validFrom, DateTime(now.year, now.month, now.day));
      expect(
        repo.stored!.validUntil,
        DateTime(now.year, now.month, now.day + 6),
      );
      expect(repo.stored!.slots.single.endTime, '11:45');
      expect(find.byType(SuggestionsScreen), findsOneWidget);
    },
  );
  testWidgets(
    'overlapping sessions still block confirmation with a clear reason',
    (tester) async {
      await pumpWidgetWithApp(
        tester,
        const ScheduleSlotsScreen(
          initial: Timetable(
            name: 'G1',
            source: 'IMAGE',
            slots: [course, course],
          ),
        ),
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(FakeSchedules()),
        ],
      );
      expect(find.text(l10nOf().timetableOverlap), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
    },
  );
  testWidgets('empty offers show an honest empty state without fake drivers', (
    tester,
  ) async {
    await pumpWidgetWithApp(
      tester,
      const SuggestionsScreen(),
      overrides: [
        roadRouteRepositoryProvider.overrideWithValue(FakeRoadRoutes()),
        scheduleRepositoryProvider.overrideWithValue(
          FakeSchedules()
            ..preferences = const ScheduleTravelPreferences(
              campus: 'TARGA',
              point: LatLng(31.632123, -8.011123),
            ),
        ),
      ],
    );
    expect(find.text(l10nOf().timetableNoMatches), findsOneWidget);
    expect(find.text(l10nOf().matchOfferCount(1)), findsNothing);
  });
  testWidgets('a city point must be selected before geographical matching', (
    tester,
  ) async {
    await pumpWidgetWithApp(
      tester,
      const SuggestionsScreen(),
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(FakeSchedules()),
      ],
    );
    expect(find.text(l10nOf().matchPointRequired), findsOneWidget);
    final search = find.ancestor(
      of: find.text(l10nOf().matchSearch),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(search).onPressed, isNull);
  });
  testWidgets('adding Monday puts it before existing Wednesday and Friday', (
    tester,
  ) async {
    const draft = Timetable(
      name: 'G1',
      source: 'MANUAL',
      slots: [
        CourseSlot(weekday: 5, startTime: '15:00', endTime: '18:00'),
        CourseSlot(weekday: 3, startTime: '08:30', endTime: '12:00'),
      ],
    );
    await pumpWidgetWithApp(
      tester,
      const ScheduleSlotsScreen(initial: draft),
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(FakeSchedules()),
      ],
    );
    await tester.ensureVisible(find.text(l10nOf().timetableAddCourse));
    await tester.tap(find.text(l10nOf().timetableAddCourse));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nOf().monday).last);
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), '09:00');
    await tester.enterText(fields.at(1), '12:00');
    await tester.tap(find.text(l10nOf().timetableValidateCourse));
    await tester.pumpAndSettle();
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.take(3).map((tile) => (tile.title! as Text).data), [
      l10nOf().monday,
      l10nOf().wednesday,
      l10nOf().timetableFriday,
    ]);
  });

  testWidgets(
    'saved departure calculates the route and displays three offer markers',
    (tester) async {
      final repo = FakeSchedules()
        ..preferences = const ScheduleTravelPreferences(
          campus: 'TARGA',
          point: LatLng(31.632123, -8.011123),
        );
      final departure = DateTime(2026, 11, 11, 8).millisecondsSinceEpoch;
      repo.offers = [
        for (var index = 0; index < 3; index++)
          ScheduleSuggestion.fromJson({
            'toCampus': true,
            'courseTime': '09:00',
            'distanceMeters': 200,
            'listing': {
              'id': 'offer-$index',
              'author': 'Test $index',
              'own': false,
              'can_accept': true,
              'seats': 2,
              'origin_label': 'Marrakech',
              'destination_label': 'EMSI Marrakech Targa',
              'origin_latitude': 31.632 + index * .001,
              'origin_longitude': -8.011,
              'destination_latitude': EmsiCampus.targa.point.latitude,
              'destination_longitude': EmsiCampus.targa.point.longitude,
              'departure': departure,
            },
          }),
      ];
      await pumpWidgetWithApp(
        tester,
        const SuggestionsScreen(),
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(repo),
          roadRouteRepositoryProvider.overrideWithValue(FakeRoadRoutes()),
        ],
      );
      expect(repo.preferences!.commuteMinutes, 10);
      expect(find.text(l10nOf().matchOfferCount(3)), findsOneWidget);
      expect(find.byTooltip('Test 0 · 08:00'), findsOneWidget);
      expect(find.byTooltip('Test 1 · 08:00'), findsOneWidget);
      expect(find.byTooltip('Test 2 · 08:00'), findsOneWidget);
    },
  );
}
