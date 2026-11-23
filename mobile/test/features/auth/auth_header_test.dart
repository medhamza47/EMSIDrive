import 'package:emsidrive_mobile/core/constants/app_assets.dart';
import 'package:emsidrive_mobile/features/auth/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  String shownLogo(WidgetTester tester) =>
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

  testWidgets('shows the transparent wordmark on the light theme', (tester) async {
    await pumpWidgetWithApp(tester, const AuthHeader(title: 'Connexion', subtitle: 'Bienvenue'));

    expect(shownLogo(tester), AppAssets.logo);
  });

  testWidgets('shows the light-text wordmark on the dark theme', (tester) async {
    await pumpWidgetWithApp(
      tester,
      const AuthHeader(title: 'Connexion', subtitle: 'Bienvenue'),
      dark: true,
    );

    expect(shownLogo(tester), AppAssets.logoDark);
  });
}
