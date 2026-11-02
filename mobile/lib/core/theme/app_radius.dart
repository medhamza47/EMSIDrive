import 'package:flutter/material.dart';

/// Corner radius scale, in logical pixels.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Radius used by cards and sheet surfaces.
  static const double card = lg;

  /// Radius used by buttons and inputs.
  static const double control = md;

  /// Radius that turns a shape into a pill (badges, chips).
  static const double pill = 999;

  static const BorderRadius badge = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius controlShape = BorderRadius.all(Radius.circular(control));
  static const BorderRadius cardShape = BorderRadius.all(Radius.circular(card));
}
