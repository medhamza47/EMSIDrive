import 'package:emsidrive_mobile/core/theme/app_colors.dart';
import 'package:emsidrive_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and forwards taps', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: PrimaryButton(label: 'Se connecter', onPressed: () => taps++),
        ),
      );

      expect(find.text('Se connecter'), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('is disabled while loading and shows a spinner', (tester) async {
      var taps = 0;

      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: PrimaryButton(
            label: 'Se connecter',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('uses the EMSI dark green background', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(body: PrimaryButton(label: 'Continuer', onPressed: () {})),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final background = button.style?.backgroundColor?.resolve(<WidgetState>{});

      expect(background, AppColors.primary);
    });

    testWidgets('richer content renders the leading icon', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: PrimaryButton(
            label: 'Publier',
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Publier'), findsOneWidget);
    });
  });

  group('SecondaryButton', () {
    testWidgets('uses the EMSI light green background', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(body: SecondaryButton(label: 'Annuler', onPressed: () {})),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final background = button.style?.backgroundColor?.resolve(<WidgetState>{});

      expect(background, AppColors.accent);
    });
  });
}
