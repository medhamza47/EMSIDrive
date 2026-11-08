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
      path = RidePath.fromJson(json);

  final String id;
  final ListingKind kind;
  final String author;
  final bool own;
  final bool canAccept;
  final int seats;
  final String? notes;
  final RidePath path;
}

class AcceptedRide {
  AcceptedRide.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      partner = json['partner'] as String,
      isDriver = json['is_driver'] as bool,
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
  final RidePath path;
  final LatLng? live;
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
      accepter = json['body'] as String,
      seen = json['seen'] as bool;

  final String id;
  final String bookingId;
  final bool isRequest;
  final String accepter;
  final bool seen;
}
