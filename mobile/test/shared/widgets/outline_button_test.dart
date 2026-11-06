import 'package:emsidrive_mobile/shared/widgets/outline_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OutlineButton', () {
    testWidgets('renders its label and fires the callback', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(body: OutlineButton(label: 'Réessayer', onPressed: () => taps++)),
      );

      expect(find.widgetWithText(OutlinedButton, 'Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: OutlineButton(label: 'Réessayer', onPressed: null)),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      expect(button.onPressed, isNull);
    });

    testWidgets('renders an optional leading icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: OutlineButton(
            label: 'Réessayer',
            onPressed: () {},
            icon: Icons.refresh,
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('is 52px tall', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(body: OutlineButton(label: 'Réessayer', onPressed: () {})),
      );

      expect(tester.getSize(find.byType(OutlinedButton)).height, 52);
    });

    testWidgets('expanded stretches to the parent width', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Center(
          child: SizedBox(
            width: 300,
            child: OutlineButton(
              label: 'Réessayer',
              onPressed: () {},
              expanded: true,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(OutlinedButton)).width, 300);
    });

    testWidgets('does not stretch when not expanded', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Center(
          child: SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlineButton(label: 'Réessayer', onPressed: () {}),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(OutlinedButton)).width,
        lessThan(300),
      );
    });
  });
}
