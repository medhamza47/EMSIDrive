import 'package:emsidrive_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  TextField field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField));

  group('AppTextField', () {
    testWidgets('renders the label above the input', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: AppTextField(label: 'Adresse email', hint: 'prenom.nom@emsi-edu.ma'),
        ),
      );

      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('prenom.nom@emsi-edu.ma'), findsOneWidget);
    });

    testWidgets('forwards typed text to the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpWidgetWithApp(
        tester,
        Scaffold(body: AppTextField(label: 'Nom complet', controller: controller)),
      );

      await tester.enterText(find.byType(TextFormField), 'Yassine El Amrani');
      await tester.pump();

      expect(controller.text, 'Yassine El Amrani');
    });

    testWidgets('toggles password visibility with the French tooltips', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(body: AppTextField(label: 'Mot de passe', obscureText: true)),
      );
      final l10n = l10nOf();

      expect(field(tester).obscureText, isTrue);
      expect(tester.widget<IconButton>(find.byType(IconButton)).tooltip, l10n.showPasswordTooltip);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(field(tester).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(tester.widget<IconButton>(find.byType(IconButton)).tooltip, l10n.hidePasswordTooltip);
    });

    testWidgets('has no visibility toggle for regular fields', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(body: AppTextField(label: 'Adresse email', prefixIcon: Icons.mail_outline)),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    });

    testWidgets('displays server side errors', (tester) async {
      await pumpWidgetWithApp(
        tester,
        Scaffold(
          body: AppTextField(
            label: 'Adresse email',
            errorText: 'Seuls les emails EMSI sont acceptés',
          ),
        ),
      );

      expect(find.text('Seuls les emails EMSI sont acceptés'), findsOneWidget);
    });
  });
}
