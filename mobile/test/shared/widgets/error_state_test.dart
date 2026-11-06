import 'package:emsidrive_mobile/shared/widgets/error_state.dart';
import 'package:emsidrive_mobile/shared/widgets/outline_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ErrorState', () {
    testWidgets('renders the message', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: ErrorState(message: 'Connexion impossible.')),
      );

      expect(find.text('Connexion impossible.'), findsOneWidget);
    });

    testWidgets('renders the optional title', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: ErrorState(
            title: "Impossible de charger l'accueil",
            message: 'Connexion impossible.',
          ),
        ),
      );

      expect(find.text("Impossible de charger l'accueil"), findsOneWidget);
      expect(find.text('Connexion impossible.'), findsOneWidget);
    });

    testWidgets('defaults to the cloud-off icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: ErrorState(message: 'Connexion impossible.')),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('accepts a custom icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: ErrorState(message: 'Erreur', icon: Icons.lock_outline),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    });

    testWidgets('tints the icon badge with the error colour', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: ErrorState(message: 'Connexion impossible.')),
      );

      final scheme = Theme.of(
        tester.element(find.byType(ErrorState)),
      ).colorScheme;
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.cloud_off_rounded),
              matching: find.byType(Container),
            )
            .first,
      );

      expect((container.decoration! as BoxDecoration).color, scheme.errorContainer);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.cloud_off_rounded)).color,
        scheme.error,
      );
    });

    testWidgets('hides the retry button without a callback', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: ErrorState(message: 'Connexion impossible.', retryLabel: 'Réessayer'),
        ),
      );

      expect(find.byType(OutlineButton), findsNothing);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('renders the retry button and fires it', (tester) async {
      var retries = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: ErrorState(
            message: 'Connexion impossible.',
            retryLabel: 'Réessayer',
            onRetry: () => retries++,
          ),
        ),
      );

      expect(find.byType(OutlineButton), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('does not wrap itself in a scaffold', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: ErrorState(message: 'Connexion impossible.')),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
