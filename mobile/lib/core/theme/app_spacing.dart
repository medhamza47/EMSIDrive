/// Spacing scale, in logical pixels.
///
/// Always compose layouts from these steps so padding and gaps stay consistent
/// across features.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal page padding.
  static const double pageHorizontal = lg;

  /// Standard vertical page padding.
  static const double pageVertical = lg;
}
