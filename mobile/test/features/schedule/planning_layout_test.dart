import 'dart:io';
import 'dart:ui' as ui;

import 'package:emsidrive_mobile/features/schedule/data/schedule_repository.dart';
import 'package:emsidrive_mobile/features/schedule/domain/schedule_models.dart';
import 'package:emsidrive_mobile/features/schedule/presentation/planning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import 'schedule_test.dart' show FakeSchedules;

void main() {
  for (final dark in [false, true]) {
    testWidgets('planning fits a phone in ${dark ? 'dark' : 'light'} mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      final repository = FakeSchedules()
        ..stored = Timetable(
          name: 'Ma semaine EMSI',
          source: 'MANUAL',
          validFrom: DateTime(2026, 11, 10),
          validUntil: DateTime(2026, 11, 16),
          slots: const [
            CourseSlot(weekday: 1, startTime: '08:30', endTime: '16:30'),
            CourseSlot(weekday: 2, startTime: '09:00', endTime: '18:00'),
            CourseSlot(weekday: 4, startTime: '08:30', endTime: '12:00'),
            CourseSlot(weekday: 5, startTime: '15:00', endTime: '18:00'),
          ],
        );
      await pumpWidgetWithApp(
        tester,
        RepaintBoundary(key: capture, child: const PlanningScreen()),
        dark: dark,
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10nOf().planningReserve).hitTestable(), findsOneWidget);
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/qa/planning-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
