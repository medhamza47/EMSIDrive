import 'package:emsidrive_mobile/shared/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  BoxDecoration badgeDecoration(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('AppBadge', () {
    testWidgets('renders its label', (tester) async {
      await pumpWidgetWithApp(tester, const Scaffold(body: AppBadge(label: 'Confirmé')));

      expect(find.text('Confirmé'), findsOneWidget);
    });

    testWidgets('defaults to the accent tone', (tester) async {
      await pumpWidgetWithApp(tester, const Scaffold(body: AppBadge(label: 'Actif')));

      final secondary = Theme.of(
        tester.element(find.text('Actif')),
      ).colorScheme.secondary;

      expect(badgeDecoration(tester, 'Actif').color, secondary);
    });

    testWidgets('every tone resolves to a themed background', (tester) async {
      for (final tone in AppBadgeTone.values) {
        await pumpWidgetWithApp(tester, Scaffold(body: AppBadge(label: 'X', tone: tone)));

        expect(
          badgeDecoration(tester, 'X').color,
          isNotNull,
          reason: 'tone $tone must resolve a color',
        );
      }
    });

    testWidgets('renders an optional icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: AppBadge(label: '3 places', icon: Icons.event_seat)),
      );

      expect(find.byIcon(Icons.event_seat), findsOneWidget);
    });
  });
}
