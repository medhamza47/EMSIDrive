import 'package:flutter/material.dart';

/// Typography scale for EMSIDrive.
///
/// Material 3's default [TextTheme] is used as the base and only the weights
/// that matter for the brand are adjusted. Screens should read text styles from
/// `Theme.of(context).textTheme` rather than instantiating [TextStyle]s.
abstract final class AppTypography {
  /// Font family used across the app. `null` keeps the platform default
  /// (Roboto on Android, SF Pro on iOS) which keeps bundle size down.
  static const String? fontFamily = null;

  /// Applies the brand weights on top of the default Material 3 text theme.
  static TextTheme apply(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
