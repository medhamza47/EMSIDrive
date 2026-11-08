import 'package:intl/intl.dart';

import '../../../core/errors/error_mapper.dart';
import '../../profile/data/profile_repository.dart';
import '../../rides/data/marketplace_api.dart';
import '../domain/home_overview.dart';
import '../domain/upcoming_trip.dart';
import 'home_repository.dart';

class HttpHomeRepository implements HomeRepository {
  HttpHomeRepository(this._profiles, this._rides);
  final ProfileRepository _profiles;
  final MarketplaceApi _rides;
  @override
  Future<HomeOverview> loadOverview() async {
    try {
      final profile = await _profiles.loadProfile();
      final trips = await _rides.trips();
      final upcoming =
          trips.where((t) => t.path.departure.isAfter(DateTime.now())).toList()
            ..sort((a, b) => a.path.departure.compareTo(b.path.departure));
      return HomeOverview(
        displayName: profile.fullName,
        upcomingTrips: [
          for (final trip in upcoming.take(3))
            UpcomingTrip(
              id: trip.id,
              origin: trip.path.originLabel,
              destination: trip.path.destinationLabel,
              timeLabel: DateFormat.MMMEd('fr')
                  .add_Hm()
                  .format(trip.path.departure),
              driverName: trip.partner,
            ),
        ],
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
