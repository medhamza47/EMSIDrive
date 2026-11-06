import 'package:flutter/material.dart';

/// Circular user avatar showing the initials of a name.
///
/// Initials are the fallback because profile pictures are optional; when
/// [imageUrl] is provided it is rendered on top so a broken remote image still
/// leaves a readable placeholder.
class Avatar extends StatelessWidget {
  const Avatar({
    required this.name,
    this.imageUrl,
    this.size = 46,
    this.showBorder = true,
    super.key,
  });

  /// Extra-large avatar used on profile headers.
  const Avatar.xl({
    required this.name,
    this.imageUrl,
    this.showBorder = true,
    super.key,
  }) : size = 84;

  /// Full name used to derive the initials.
  final String name;

  /// Optional profile picture URL.
  final String? imageUrl;

  /// Diameter of the circle.
  final double size;

  /// Draws the light green ring used in the mockups.
  final bool showBorder;

  /// Uppercase initials built from the first and last word of [name].
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderWidth = size >= 72 ? 3.0 : 2.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: scheme.secondary, width: borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl == null
          ? _initials(context)
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) =>
                      _initials(context),
            ),
    );
  }

  Widget _initials(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      initialsOf(name),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.34,
      ),
    );
  }
}
