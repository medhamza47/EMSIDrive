import 'package:flutter/material.dart';

/// Raw brand palette for EMSIDrive.
///
/// Values mirror the design tokens documented in `CONTEXT.md` §5. Widgets must
/// never reference these constants directly: they read colors from
/// [ThemeData.colorScheme] or from the semantic tokens extension so that light
/// and dark themes stay consistent.
abstract final class AppColors {
  /// EMSI dark green — app bars, titles, primary actions.
  static const Color primary = Color(0xFF015629);

  /// EMSI light green — secondary actions, badges, active states.
  static const Color accent = Color(0xFF7ECC18);

  // Light theme.
  static const Color primaryContainerLight = Color(0xFFC9EBD8);
  static const Color onPrimaryContainerLight = Color(0xFF00210F);
  static const Color secondaryContainerLight = Color(0xFFE4F8CC);
  static const Color onSecondaryContainerLight = Color(0xFF143300);
  static const Color tertiaryLight = Color(0xFF4A6352);
  static const Color tertiaryContainerLight = Color(0xFFCCE9D6);
  static const Color onTertiaryContainerLight = Color(0xFF06210F);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1C1A);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFF6F8F5);
  static const Color surfaceContainerLight = Color(0xFFF0F3EF);
  static const Color surfaceContainerHighLight = Color(0xFFEAEDE9);
  static const Color surfaceContainerHighestLight = Color(0xFFE4E7E3);
  static const Color onSurfaceVariantLight = Color(0xFF414942);
  static const Color outlineLight = Color(0xFF717971);
  static const Color outlineVariantLight = Color(0xFFC1C9C0);

  // Dark theme.
  static const Color primaryDark = Color(0xFF7FD8A4);
  static const Color onPrimaryDark = Color(0xFF00391B);
  static const Color primaryContainerDark = Color(0xFF00522A);
  static const Color onPrimaryContainerDark = Color(0xFF9CF7BC);
  static const Color secondaryContainerDark = Color(0xFF2C4600);
  static const Color onSecondaryContainerDark = Color(0xFFC7F58F);
  static const Color tertiaryDark = Color(0xFFA7D3B8);
  static const Color onTertiaryDark = Color(0xFF10381F);
  static const Color tertiaryContainerDark = Color(0xFF2A4E33);
  static const Color onTertiaryContainerDark = Color(0xFFC3EBD0);
  static const Color surfaceDark = Color(0xFF0F1511);
  static const Color onSurfaceDark = Color(0xFFE0E3DE);
  static const Color surfaceContainerLowestDark = Color(0xFF0A0F0B);
  static const Color surfaceContainerLowDark = Color(0xFF171D18);
  static const Color surfaceContainerDark = Color(0xFF1B211C);
  static const Color surfaceContainerHighDark = Color(0xFF252B26);
  static const Color surfaceContainerHighestDark = Color(0xFF303631);
  static const Color onSurfaceVariantDark = Color(0xFFBFC9C1);
  static const Color outlineDark = Color(0xFF89938B);
  static const Color outlineVariantDark = Color(0xFF414942);

  // Feedback colors, shared by both themes through [AppSemanticColors].
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color errorContainerLight = Color(0xFFFFDAD6);
  static const Color onErrorContainerLight = Color(0xFF410002);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  static const Color successLight = Color(0xFF2E6B12);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFD7F5B4);
  static const Color onSuccessContainerLight = Color(0xFF102400);
  static const Color successDark = Color(0xFF7ECC18);
  static const Color onSuccessDark = Color(0xFF162900);
  static const Color successContainerDark = Color(0xFF2E4D00);
  static const Color onSuccessContainerDark = Color(0xFFC7F58F);

  static const Color warningLight = Color(0xFF8A5300);
  static const Color onWarningLight = Color(0xFFFFFFFF);
  static const Color warningContainerLight = Color(0xFFFFDDB3);
  static const Color onWarningContainerLight = Color(0xFF2C1700);
  static const Color warningDark = Color(0xFFFFB95C);
  static const Color onWarningDark = Color(0xFF492900);
  static const Color warningContainerDark = Color(0xFF683C00);
  static const Color onWarningContainerDark = Color(0xFFFFDDB3);

  /// Gold used by rating stars, taken from the mockups (`--gold`).
  static const Color ratingLight = Color(0xFFF2A900);
  static const Color ratingDark = Color(0xFFFFC94D);

  static const Color infoLight = Color(0xFF1B5E8C);
  static const Color onInfoLight = Color(0xFFFFFFFF);
  static const Color infoContainerLight = Color(0xFFCFE7FA);
  static const Color onInfoContainerLight = Color(0xFF001E30);
  static const Color infoDark = Color(0xFF8ECFFA);
  static const Color onInfoDark = Color(0xFF00344F);
  static const Color infoContainerDark = Color(0xFF004C6F);
  static const Color onInfoContainerDark = Color(0xFFCFE7FA);
}
