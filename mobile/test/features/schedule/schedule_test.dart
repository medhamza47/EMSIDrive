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

import '../../helpers/pump_app.dart';

class FakeSchedules implements ScheduleRepository {
  Timetable? stored;
  int saves = 0;
  @override
  Future<Timetable?> current() async => stored;
  @override
  Future<Timetable> save(Timetable timetable) async {
    saves++;
    return stored = timetable;
  }

  @override
  Future<void> delete() async {
    stored = null;
  }

  @override
  Future<List<ScheduleSuggestion>> suggestions(int commuteMinutes) async => [];
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
        slots: const [course],
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
      expect(repo.stored!.slots.single.label, 'ERP');
      expect(find.byType(ScheduleSlotsScreen), findsNothing);
    },
  );
  testWidgets('uncertain extracted course blocks confirmation until edited', (
    tester,
  ) async {
    final repo = FakeSchedules();
    final draft = Timetable(
      name: 'G1',
      source: 'IMAGE',
      slots: const [
        CourseSlot(
          label: 'ERP',
          weekday: 1,
          startTime: '08:30',
          endTime: '10:00',
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
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNull,
    );
    await tester.ensureVisible(find.text('ERP'));
    await tester.tap(find.text('ERP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nOf().timetableValidateCourse));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNotNull,
    );
  });
  testWidgets('empty offers show an honest empty state without fake drivers', (
    tester,
  ) async {
    await pumpWidgetWithApp(
      tester,
      const SuggestionsScreen(),
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(FakeSchedules()),
      ],
    );
    expect(find.text(l10nOf().timetableNoMatches), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
