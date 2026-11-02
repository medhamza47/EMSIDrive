import 'package:emsidrive_mobile/app.dart';
import 'package:emsidrive_mobile/core/theme/app_theme.dart';
import 'package:emsidrive_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in the minimal tree required by EMSIDrive widgets: a
/// `ProviderScope`, the French localization delegates and the EMSI theme.
///
/// Set [settle] to `false` when the subtree contains an animation that never
/// ends, such as a [CircularProgressIndicator].
Future<void> pumpWidgetWithApp(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool settle = true,
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps the real application, router included.
Future<void> pumpEmsiDriveApp(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: const EmsiDriveApp()));
  await tester.pumpAndSettle();
}

/// Generated localization strings for the French locale.
AppLocalizations l10nOf() => lookupAppLocalizations(const Locale('fr'));
