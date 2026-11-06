import 'package:emsidrive_mobile/core/theme/app_colors.dart';
import 'package:emsidrive_mobile/shared/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Avatar.initialsOf', () {
    test('uses the first and last word of a full name', () {
      expect(Avatar.initialsOf('Yassine Amrani'), 'YA');
    });

    test('ignores extra and repeated spaces', () {
      expect(Avatar.initialsOf('  Mohamed   Hamza  '), 'MH');
    });

    test('keeps three-part names at first and last initials', () {
      expect(Avatar.initialsOf('Mohamed El Amrani'), 'MA');
    });

    test('uses a single letter for a one-word name', () {
      expect(Avatar.initialsOf('salma'), 'S');
    });

    test('falls back to a question mark for an empty name', () {
      expect(Avatar.initialsOf(''), '?');
      expect(Avatar.initialsOf('   '), '?');
    });
  });

  group('Avatar', () {
    testWidgets('renders the initials inside a circular container', (
      tester,
    ) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: Avatar(name: 'Yassine Amrani')),
      );

      expect(find.text('YA'), findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('YA'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.shape, BoxShape.circle);
      expect(container.clipBehavior, Clip.antiAlias);
      expect(tester.getSize(find.byType(Avatar)), const Size.square(46));
    });

    testWidgets('paints the light green ring by default', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: Avatar(name: 'Yassine Amrani')),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('YA'),
          matching: find.byType(Container),
        ).first,
      );
      final border = (container.decoration! as BoxDecoration).border! as Border;

      expect(border.top.color, AppColors.accent);
      expect(border.top.width, 2);
    });

    testWidgets('hides the ring when showBorder is false', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: Avatar(name: 'Yassine Amrani', showBorder: false),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('YA'),
          matching: find.byType(Container),
        ).first,
      );

      expect((container.decoration! as BoxDecoration).border, isNull);
    });

    testWidgets('honours a custom size', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: Avatar(name: 'Yassine Amrani', size: 60)),
      );

      expect(tester.getSize(find.byType(Avatar)), const Size.square(60));
    });

    testWidgets('the xl variant is larger and draws a thicker ring', (
      tester,
    ) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: Avatar.xl(name: 'Yassine Amrani')),
      );

      expect(tester.getSize(find.byType(Avatar)), const Size.square(84));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('YA'),
          matching: find.byType(Container),
        ).first,
      );
      final border = (container.decoration! as BoxDecoration).border! as Border;

      expect(border.top.width, 3);
    });
  });
}
