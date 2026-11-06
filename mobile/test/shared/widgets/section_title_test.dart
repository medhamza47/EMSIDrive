import 'package:emsidrive_mobile/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SectionTitle', () {
    testWidgets('renders its title', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: SectionTitle(title: 'Prochains trajets')),
      );

      expect(find.text('Prochains trajets'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders the trailing action and fires it', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: SectionTitle(
            title: 'Prochains trajets',
            action: 'Tout voir',
            onActionPressed: () => taps++,
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Tout voir'), findsOneWidget);

      await tester.tap(find.text('Tout voir'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('still renders the action label without a callback', (
      tester,
    ) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: SectionTitle(title: 'Prochains trajets', action: 'Tout voir'),
        ),
      );

      expect(find.text('Tout voir'), findsOneWidget);

      final button = tester.widget<TextButton>(find.byType(TextButton));

      expect(button.onPressed, isNull);
    });

    testWidgets('pushes the action to the trailing edge', (tester) async {
      await pumpWidgetWithApp(
        tester,
        SizedBox(
          width: 320,
          child: Scaffold(
            body: SectionTitle(
              title: 'Prochains trajets',
              action: 'Tout voir',
              onActionPressed: () {},
            ),
          ),
        ),
      );

      final titleRight = tester.getTopRight(find.text('Prochains trajets')).dx;
      final actionRight = tester.getTopRight(find.text('Tout voir')).dx;

      expect(actionRight, greaterThan(titleRight));
    });
  });
}
