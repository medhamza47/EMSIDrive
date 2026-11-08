import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/demo_drivers.dart';

class RideTrackingScreen extends StatelessWidget {
  const RideTrackingScreen({required this.driver, super.key});

  final DemoDriver driver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    void showPreviewNotice() =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.demoOnlyAction)));

    return FlowPage(
      title: l.trackingTitle,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.12,
            child: CustomPaint(painter: _RouteMap(scheme)),
          ),
        ),
        FlowCopy(
          l.arrivalEstimate(driver.name.split(' ').first),
          l.arrivalDistance,
        ),
        AppCard(
          leading: Avatar(name: driver.name),
          trailing: AppBadge(label: l.onTheWay),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(driver.name, style: Theme.of(context).textTheme.titleSmall),
              Text(driver.isMotorcycle ? l.vehicleMotorcycle : l.vehicleCar),
              RatingStars(rating: driver.rating, showValue: true, size: 12),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlineButton(
                label: l.messageDriver,
                onPressed: showPreviewNotice,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlineButton(
                label: l.callDriver,
                onPressed: showPreviewNotice,
              ),
            ),
          ],
        ),
        PrimaryButton(
          label: l.fuelTitle,
          onPressed: () => context.push(AppRoutes.fuelSplit),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => context.go(AppRoutes.rides),
          child: Text(l.cancelRideRequest),
        ),
      ],
    );
  }
}

class _RouteMap extends CustomPainter {
  const _RouteMap(this.colors);

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 470);
    final paint = Paint()..color = colors.primaryContainer;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 470), paint);
    paint.color = colors.secondary.withValues(alpha: .28);
    for (final park in [
      const Rect.fromLTWH(250, 40, 110, 90),
      const Rect.fromLTWH(20, 300, 90, 70),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(park, const Radius.circular(14)),
        paint,
      );
    }
    paint
      ..color = colors.surface
      ..strokeWidth = 14;
    for (final y in [120.0, 220.0, 330.0]) {
      canvas.drawLine(Offset(0, y), Offset(390, y), paint);
    }
    for (final x in [90.0, 190.0, 300.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x, 470), paint);
    }

    final route = Path()
      ..moveTo(90, 400)
      ..lineTo(90, 330)
      ..lineTo(190, 330)
      ..lineTo(190, 220)
      ..lineTo(300, 220)
      ..lineTo(300, 90);
    paint
      ..color = colors.primary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(route, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(90, 400), 11, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(291, 81, 18, 18),
        const Radius.circular(4),
      ),
      paint,
    );
    paint.color = colors.secondary;
    canvas.drawCircle(const Offset(90, 400), 7, paint);
    canvas.drawCircle(
      const Offset(190, 276),
      15,
      paint..color = colors.secondary.withValues(alpha: .4),
    );
    canvas.drawCircle(
      const Offset(190, 276),
      10,
      paint..color = colors.surface,
    );
    canvas.drawCircle(const Offset(190, 276), 7, paint..color = colors.primary);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RouteMap oldDelegate) => colors != oldDelegate.colors;
}
