import 'package:emsidrive_mobile/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders its child inside a rounded surface', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: AppCard(child: Text('Trajet Marrakech → Casablanca'))),
      );

      expect(find.text('Trajet Marrakech → Casablanca'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('becomes tappable when onTap is provided', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: AppCard(
            onTap: () => taps++,
            child: const Text('Détails du trajet'),
          ),
        ),
      );

      await tester.tap(find.text('Détails du trajet'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('lays out leading and trailing slots', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: AppCard(
            leading: Icon(Icons.person),
            trailing: Icon(Icons.chevron_right),
            child: Text('Conducteur'),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Conducteur'), findsOneWidget);
    });
  });
}
