import 'package:emsidrive_mobile/core/theme/app_radius.dart';
import 'package:emsidrive_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  Finder skeletonContainer() => find
      .descendant(
        of: find.byType(SkeletonLoader),
        matching: find.byType(Container),
      )
      .first;

  BoxDecoration skeletonDecoration(WidgetTester tester) =>
      tester.widget<Container>(skeletonContainer()).decoration! as BoxDecoration;

  Finder pulseFade() => find.descendant(
    of: find.byType(SkeletonLoader),
    matching: find.byType(FadeTransition),
  );

  group('SkeletonLoader', () {
    testWidgets('expands to the parent width by default', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader(height: 24, pulse: false)),
      );

      final available = tester.getSize(find.byType(Scaffold)).width;

      expect(tester.getSize(find.byType(SkeletonLoader)).height, 24);
      expect(tester.getSize(find.byType(SkeletonLoader)).width, available);
      expect(
        (skeletonDecoration(tester).borderRadius! as BorderRadius).topLeft.x,
        AppRadius.md,
      );
    });

    testWidgets('uses the surfaceContainerHigh colour', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader(height: 24, pulse: false)),
      );

      final scheme = Theme.of(
        tester.element(find.byType(SkeletonLoader)),
      ).colorScheme;

      expect(skeletonDecoration(tester).color, scheme.surfaceContainerHigh);
    });

    testWidgets('the line constructor is 12px tall with a small radius', (
      tester,
    ) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader.line(width: 120)),
        settle: false,
      );

      expect(tester.getSize(find.byType(SkeletonLoader)).height, 12);
      expect(tester.getSize(find.byType(SkeletonLoader)).width, 120);
      expect(
        (skeletonDecoration(tester).borderRadius! as BorderRadius).topLeft.x,
        AppRadius.xs,
      );
    });

    testWidgets('the box constructor keeps its height and large radius', (
      tester,
    ) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader.box(height: 96, width: 200)),
        settle: false,
      );

      expect(tester.getSize(find.byType(SkeletonLoader)), const Size(200, 96));
      expect(
        (skeletonDecoration(tester).borderRadius! as BorderRadius).topLeft.x,
        AppRadius.lg,
      );
    });

    testWidgets('honours a custom radius and width', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: Center(
            child: SkeletonLoader(width: 80, height: 40, radius: AppRadius.pill),
          ),
        ),
        settle: false,
      );

      expect(tester.getSize(find.byType(SkeletonLoader)), const Size(80, 40));
      expect(
        (skeletonDecoration(tester).borderRadius! as BorderRadius).topLeft.x,
        AppRadius.pill,
      );
    });

    testWidgets('pulses with a repeating fade transition', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader(height: 24)),
        settle: false,
      );

      expect(pulseFade(), findsOneWidget);

      final initial = tester.widget<FadeTransition>(pulseFade()).opacity.value;

      await tester.pump(const Duration(milliseconds: 550));

      final animated = tester.widget<FadeTransition>(pulseFade()).opacity.value;

      expect(animated, isNot(initial));
      expect(animated, inInclusiveRange(0.55, 1.0));
    });

    testWidgets('renders statically when pulse is false', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SkeletonLoader(height: 24, pulse: false)),
      );

      expect(pulseFade(), findsNothing);
    });
  });
}
