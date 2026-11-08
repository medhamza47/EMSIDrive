import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/flow_page.dart';
import '../data/demo_drivers.dart';

class NearbyDriversScreen extends StatefulWidget {
  const NearbyDriversScreen({super.key});

  @override
  State<NearbyDriversScreen> createState() => _NearbyDriversScreenState();
}

class _NearbyDriversScreenState extends State<NearbyDriversScreen> {
  bool _sortByRating = false;
  bool? _motorcycles;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final number = NumberFormat.decimalPattern('fr');
    final drivers = DemoDriver.all
        .where(
          (driver) =>
              _motorcycles == null || driver.isMotorcycle == _motorcycles,
        )
        .toList();
    if (_sortByRating) drivers.sort((a, b) => b.rating.compareTo(a.rating));

    return FlowPage(
      title: l.nearbyTitle,
      children: [
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(l.nearestSort),
              selected: !_sortByRating,
              onSelected: (_) => setState(() => _sortByRating = false),
            ),
            FilterChip(
              label: Text(l.vehicleMotorcycle),
              selected: _motorcycles == true,
              onSelected: (selected) =>
                  setState(() => _motorcycles = selected ? true : null),
            ),
            FilterChip(
              label: Text(l.vehicleCar),
              selected: _motorcycles == false,
              onSelected: (selected) =>
                  setState(() => _motorcycles = selected ? false : null),
            ),
            ChoiceChip(
              label: Text(l.ratingSort),
              selected: _sortByRating,
              onSelected: (_) => setState(() => _sortByRating = true),
            ),
          ],
        ),
        for (final driver in drivers)
          AppCard(
            leading: Avatar(name: driver.name),
            onTap: () => context.push(AppRoutes.driverDetail(driver.id)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppBadge(
                  label: driver.isMotorcycle
                      ? l.vehicleMotorcycle
                      : l.vehicleCar,
                ),
                const SizedBox(height: 6),
                Text(
                  l.amountMad(driver.fare),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowCopy(
                  driver.name,
                  l.nearbyDriverSummary(
                    driver.major,
                    number.format(driver.distance),
                    driver.time,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RatingStars(rating: driver.rating, size: 13),
                    Text(
                      number.format(driver.rating),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({required this.driver, super.key});

  final DemoDriver driver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final vehicle = driver.isMotorcycle ? l.vehicleMotorcycle : l.vehicleCar;
    final number = NumberFormat.decimalPattern('fr');
    return FlowPage(
      title: l.driverTitle,
      children: [
        AppCard(
          leading: Avatar(name: driver.name, size: 54),
          child: FlowCopy(driver.name, l.driverAcademicSummary(driver.major)),
        ),
        AppCard(
          child: Row(
            children: [
              Expanded(child: FlowCopy('${driver.tripCount}', l.navRides)),
              Expanded(
                child: FlowCopy(number.format(driver.rating), l.averageRating),
              ),
              Expanded(child: FlowCopy(vehicle, l.vehicleLabel)),
            ],
          ),
        ),
        SectionTitle(title: l.offeredTrip),
        FlowValue(l.tripOrigin, l.demoDistrict),
        FlowValue(l.tripDestination, l.demoCampus),
        FlowValue(l.demoDay, driver.time),
        FlowValue(l.remainingSeats, driver.isMotorcycle ? '1' : '2'),
        FlowValue(l.fuelContribution, l.amountMad(driver.fare)),
        PrimaryButton(
          label: l.sendRequest,
          onPressed: () => context.push(AppRoutes.trackingFor(driver.id)),
        ),
      ],
    );
  }
}
