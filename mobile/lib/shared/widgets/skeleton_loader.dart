import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// Pulsing grey placeholder shown while content is loading.
///
/// Use [SkeletonLoader.line] for text placeholders and [SkeletonLoader.box]
/// for media or grouped blocks. All instances share the same timing so a
/// skeleton screen animates in sync.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    this.width,
    required this.height,
    this.radius = AppRadius.md,
    this.pulse = true,
    super.key,
  });

  /// Full-width text line.
  const SkeletonLoader.line({
    this.width,
    this.radius = AppRadius.xs,
    super.key,
  }) : height = 12,
       pulse = true;

  /// Larger rectangular block, e.g. a card or an image.
  const SkeletonLoader.box({
    this.width,
    required this.height,
    this.radius = AppRadius.lg,
    super.key,
  }) : pulse = true;

  /// Width of the placeholder. When `null` it expands to the parent width.
  final double? width;

  /// Height of the placeholder.
  final double height;

  /// Corner radius of the placeholder.
  final double radius;

  /// When `false` the placeholder is painted statically.
  final bool pulse;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;

    final placeholder = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );

    if (!widget.pulse) {
      return placeholder;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: placeholder,
    );
  }
}
