import 'package:emsidrive_mobile/shared/widgets/empty_state.dart';
import 'package:emsidrive_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders its title and message', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: EmptyState(
            title: 'Aucun trajet à venir',
            message: 'Vos prochains trajets confirmés apparaîtront ici.',
          ),
        ),
      );

      expect(find.text('Aucun trajet à venir'), findsOneWidget);
      expect(
        find.text('Vos prochains trajets confirmés apparaîtront ici.'),
        findsOneWidget,
      );
    });

    testWidgets('defaults to the inbox icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: EmptyState(title: 'Aucun trajet à venir')),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('accepts a custom icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: EmptyState(title: 'Aucun trajet', icon: Icons.route_outlined),
        ),
      );

      expect(find.byIcon(Icons.route_outlined), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('hides the action when no callback is given', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: EmptyState(title: 'Aucun trajet', actionLabel: 'Chercher'),
        ),
      );

      expect(find.byType(PrimaryButton), findsNothing);
      expect(find.text('Chercher'), findsNothing);
    });

    testWidgets('renders the action and fires it', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: EmptyState(
            title: 'Aucun trajet',
            actionLabel: 'Chercher',
            onActionPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(PrimaryButton), findsOneWidget);

      await tester.tap(find.text('Chercher'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('centers its content without its own scaffold', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: EmptyState(title: 'Aucun trajet')),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(
        tester.widget<Column>(find.byType(Column).first).mainAxisSize,
        MainAxisSize.min,
      );
    });
  });
}
