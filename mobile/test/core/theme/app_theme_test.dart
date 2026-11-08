import 'package:emsidrive_mobile/core/theme/app_colors.dart';
import 'package:emsidrive_mobile/core/theme/app_semantic_colors.dart';
import 'package:emsidrive_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses the EMSI brand colors', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.accent);
      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    });

    test('dark theme stays Material 3 with the light green accent', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.secondary, AppColors.accent);
    });

    test('both themes expose the semantic color extension', () {
      expect(AppTheme.light().semanticColors.success, AppColors.successLight);
      expect(AppTheme.dark().semanticColors.success, AppColors.successDark);
      expect(AppTheme.light().semanticColors.rating, AppColors.ratingLight);
      expect(AppTheme.dark().semanticColors.rating, AppColors.ratingDark);
      expect(
        AppTheme.light().extension<AppSemanticColors>(),
        isA<AppSemanticColors>(),
      );
    });

    test('app bar uses a quiet surface with readable text', () {
      final theme = AppTheme.light();

      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
      expect(theme.appBarTheme.elevation, 0);
    });

    test('semantic colors interpolate and copy', () {
      final lerped = AppSemanticColors.light.lerp(AppSemanticColors.dark, 0.5);

      expect(lerped.success, isNot(AppSemanticColors.light.success));
      expect(
        AppSemanticColors.light.copyWith(warning: Colors.pink).warning,
        Colors.pink,
      );
    });
  });
}
