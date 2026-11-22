import 'package:latlong2/latlong.dart';

enum ListingKind { request, offer }

class RidePath {
  RidePath.fromJson(Map<String, dynamic> json)
    : origin = LatLng(
        (json['origin_latitude'] as num).toDouble(),
        (json['origin_longitude'] as num).toDouble(),
      ),
      destination = LatLng(
        (json['destination_latitude'] as num).toDouble(),
        (json['destination_longitude'] as num).toDouble(),
      ),
      originLabel = json['origin_label'] as String,
      destinationLabel = json['destination_label'] as String,
      departure = DateTime.fromMillisecondsSinceEpoch(
        (json['departure'] as num).toInt(),
        isUtc: true,
      ).toLocal();

  final LatLng origin;
  final LatLng destination;
  final String originLabel;
  final String destinationLabel;
  final DateTime departure;

  String get title => '$originLabel → $destinationLabel';
}

class RideListing {
  RideListing.fromJson(Map<String, dynamic> json, this.kind)
    : id = json['id'] as String,
      author = json['author'] as String,
      own = json['own'] as bool,
      canAccept = json['can_accept'] as bool,
      seats = json['seats'] as int,
      notes = json['notes'] as String?,
      status = json['status'] as String? ?? 'OPEN',
      revision = json['revision'] as String? ?? '',
      canEdit = json['can_edit'] as bool? ?? false,
      canCancel = json['can_cancel'] as bool? ?? false,
      vehicle = json['vehicle_preference'] as String? ?? 'ANY',
      vehicleId = json['vehicle_id'] as String?,
      vehicleDetails = RideVehicleDetails.fromJson(json),
      authorRating = (json['author_rating'] as num?)?.toDouble(),
      authorRatingCount = (json['author_rating_count'] as num?)?.toInt() ?? 0,
      path = RidePath.fromJson(json);

  final String id;
  final ListingKind kind;
  final String author;
  final bool own;
  final bool canAccept;
  final int seats;
  final String? notes;
  final String status;
  final String revision;
  final bool canEdit;
  final bool canCancel;
  final String vehicle;
  final String? vehicleId;
  final RideVehicleDetails? vehicleDetails;
  final double? authorRating;
  final int authorRatingCount;
  final RidePath path;
}

class AcceptedRide {
  AcceptedRide.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      partner = json['partner'] as String,
      isDriver = json['is_driver'] as bool,
      status = json['status'] as String? ?? 'CONFIRMED',
      vehicleDetails = RideVehicleDetails.fromJson(json),
      path = RidePath.fromJson(json),
      live = json['live_latitude'] == null
          ? null
          : LatLng(
              (json['live_latitude'] as num).toDouble(),
              (json['live_longitude'] as num).toDouble(),
            );

  final String id;
  final String partner;
  final bool isDriver;
  final String status;
  final RideVehicleDetails? vehicleDetails;
  bool get active => status == 'CONFIRMED' || status == 'ONGOING';
  final RidePath path;
  final LatLng? live;
}

class RideVehicleDetails {
  const RideVehicleDetails(this.brand, this.model, this.color);
  static RideVehicleDetails? fromJson(Map<String, dynamic> json) =>
      json['vehicle_brand'] == null
      ? null
      : RideVehicleDetails(
          json['vehicle_brand'] as String,
          json['vehicle_model'] as String? ?? '',
          json['vehicle_color'] as String?,
        );
  final String brand, model;
  final String? color;
  String get label =>
      [brand, model, if (color?.isNotEmpty == true) color!].join(' · ');
}

class RideMessage {
  RideMessage.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      body = json['body'] as String,
      mine = json['mine'] as bool;

  final int id;
  final String body;
  final bool mine;
}

class RideNotice {
  RideNotice.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      bookingId = json['booking_id'] as String,
      isRequest = json['title'] == 'REQUEST_ACCEPTED',
      title = json['title'] as String,
      accepter = json['body'] as String,
      seen = json['seen'] as bool;

  final String id;
  final String bookingId;
  final bool isRequest;
  final String title;
  final String accepter;
  final bool seen;
}
