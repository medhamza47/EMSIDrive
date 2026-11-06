import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';

/// Read-only star rating with an optional numeric score.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.showValue = false,
    this.reviewCount,
    super.key,
  });

  /// Current rating, between 0 and [maxRating]. Halves are rounded up so a
  /// rating of 4.2 still paints four filled stars plus one partial.
  final double rating;

  /// Number of stars to paint.
  final int maxRating;

  /// Icon size in logical pixels.
  final double size;

  /// Appends the numeric score after the stars.
  final bool showValue;

  /// Appends a review count in parentheses when [showValue] is enabled.
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;
    final clamped = rating.clamp(0, maxRating.toDouble());
    final filledCount = clamped.round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < maxRating; index++)
          Icon(
            index < filledCount ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: index < filledCount
                ? semantic.rating
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        if (showValue) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            reviewCount == null
                ? clamped.toStringAsFixed(1)
                : '${clamped.toStringAsFixed(1)} ($reviewCount)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
