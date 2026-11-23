import 'dart:io';
import 'dart:ui' as ui;

import 'package:emsidrive_mobile/features/home/data/home_repository.dart';
import 'package:emsidrive_mobile/features/home/data/home_repository_provider.dart';
import 'package:emsidrive_mobile/features/home/domain/home_overview.dart';
import 'package:emsidrive_mobile/features/home/presentation/home_screen.dart';
import 'package:emsidrive_mobile/features/notifications/data/ride_notices_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class PreviewHome implements HomeRepository {
  @override
  Future<HomeOverview> loadOverview() async =>
      const HomeOverview(displayName: 'Yassine');
}

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('home fits 360px, dark=$dark, text=$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Optional local font for readable design previews, never required in CI.
        final fontPath = Platform.environment['QA_FONT_PATH'];
        if (fontPath != null) {
          await tester.runAsync(() async {
            final font = FontLoader('Roboto')
              ..addFont(
                File(fontPath)
                    .readAsBytes()
                    .then((bytes) => ByteData.sublistView(bytes)),
              );
            await font.load();
            final iconsPath = Platform.environment['QA_ICON_FONT_PATH'];
            if (iconsPath != null) {
              final icons = FontLoader('MaterialIcons')
                ..addFont(
                  File(iconsPath)
                      .readAsBytes()
                      .then((bytes) => ByteData.sublistView(bytes)),
                );
              await icons.load();
            }
          });
        }
        final capture = GlobalKey();
        await pumpWidgetWithApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(key: capture, child: const HomeScreen()),
            ),
          ),
          dark: dark,
          overrides: [
            homeRepositoryProvider.overrideWithValue(PreviewHome()),
            rideNoticesProvider.overrideWith((ref) => Stream.value([])),
          ],
        );
        expect(tester.takeException(), isNull);
        if (scale > 1) {
          await tester.ensureVisible(find.text(l10nOf().homeSearchRideTitle));
          await tester.pumpAndSettle();
        }
        expect(
          find.text(l10nOf().homeSearchRideTitle).hitTestable(),
          findsOneWidget,
        );
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/qa/home-${dark ? 'dark' : 'light'}-$scale.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
