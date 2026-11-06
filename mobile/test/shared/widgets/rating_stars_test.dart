import 'package:emsidrive_mobile/core/theme/app_semantic_colors.dart';
import 'package:emsidrive_mobile/shared/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  int filledStars(WidgetTester tester) =>
      tester.widgetList(find.byIcon(Icons.star_rounded)).length;

  int outlinedStars(WidgetTester tester) =>
      tester.widgetList(find.byIcon(Icons.star_outline_rounded)).length;

  group('RatingStars', () {
    testWidgets('paints five stars for a perfect rating', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 5)),
      );

      expect(filledStars(tester), 5);
      expect(outlinedStars(tester), 0);
    });

    testWidgets('rounds a rating to the nearest star', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 4.7)),
      );

      expect(filledStars(tester), 5);
      expect(outlinedStars(tester), 0);
    });

    testWidgets('leaves the remaining stars outlined', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 3.2)),
      );

      expect(filledStars(tester), 3);
      expect(outlinedStars(tester), 2);
    });

    testWidgets('clamps a negative rating to zero', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: -2)),
      );

      expect(filledStars(tester), 0);
      expect(outlinedStars(tester), 5);
    });

    testWidgets('clamps a rating above the maximum', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 9)),
      );

      expect(filledStars(tester), 5);
      expect(outlinedStars(tester), 0);
    });

    testWidgets('supports a custom maximum', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 2, maxRating: 3)),
      );

      expect(filledStars(tester), 2);
      expect(outlinedStars(tester), 1);
    });

    testWidgets('colours filled stars with the rating token', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 5)),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star_rounded).first);
      final rating = Theme.of(
        tester.element(find.byType(RatingStars)),
      ).semanticColors.rating;

      expect(icon.color, rating);
    });

    testWidgets('hides the numeric value by default', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 4.7)),
      );

      expect(find.text('4.7'), findsNothing);
    });

    testWidgets('shows the numeric value when asked', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(body: RatingStars(rating: 4.7, showValue: true)),
      );

      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets('appends the review count', (tester) async {
      await pumpWidgetWithApp(
        tester,
        const Scaffold(
          body: RatingStars(rating: 4.7, showValue: true, reviewCount: 18),
        ),
      );

      expect(find.text('4.7 (18)'), findsOneWidget);
    });
  });
}
