import 'dart:ui' show Brightness;

/// Asset paths bundled with the application.
///
/// Centralized so a renamed file only breaks one line and widgets never embed
/// string literals.
abstract final class AppAssets {
  /// EMSIDrive wordmark on a transparent background, for the light theme.
  static const String logo = 'assets/images/logo.png';

  /// Same wordmark for the dark theme: white text and a brighter green so it
  /// stays readable on dark surfaces.
  static const String logoDark = 'assets/images/logo_dark.png';

  /// Wordmark matching the theme [brightness].
  static String logoFor(Brightness brightness) =>
      brightness == Brightness.dark ? logoDark : logo;
}
