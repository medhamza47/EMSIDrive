import 'package:latlong2/latlong.dart';

enum ListingKind { request, offer }

class RidePath {
  const RidePath({
    required this.origin,
    required this.destination,
    required this.originLabel,
    required this.destinationLabel,
    required this.departure,
  });
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

enum RideStage {
  confirmed('CONFIRMED'),
  enRoute('EN_ROUTE'),
  arrived('ARRIVED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const RideStage(this.wire);
  final String wire;
  bool get active => this != completed && this != cancelled;
  RideStage? get next => switch (this) {
    confirmed => enRoute,
    enRoute => arrived,
    arrived => inProgress,
    inProgress => completed,
    _ => null,
  };
}

class AcceptedRide {
  AcceptedRide.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      offerId = json['ride_offer_id'] as String? ?? json['id'] as String,
      requestId = json['ride_request_id'] as String?,
      partner = json['partner'] as String,
      partnerPhone = json['partner_phone'] as String?,
      isDriver = json['is_driver'] as bool,
      stage =
          RideStage.values
              .where((s) => s.wire == json['tracking_state'])
              .firstOrNull ??
          RideStage.confirmed,
      liveUpdatedAt = json['live_updated_at'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['live_updated_at'] as num).toInt(),
              isUtc: true,
            )
          : null,
      liveAccuracy = (json['live_accuracy'] as num?)?.toDouble(),
      liveHeading = (json['live_heading'] as num?)?.toDouble(),
      path = RidePath.fromJson(json),
      live = json['live_latitude'] == null
          ? null
          : LatLng(
              (json['live_latitude'] as num).toDouble(),
              (json['live_longitude'] as num).toDouble(),
            );

  final String id;
  final String offerId;
  final String? requestId;
  final String partner;
  final String? partnerPhone;
  Uri? get callUri {
    final phone = partnerPhone?.replaceAll(RegExp(r'[\s().-]'), '') ?? '';
    return stage.active && RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)
        ? Uri(scheme: 'tel', path: phone)
        : null;
  }

  Uri? get whatsappUri {
    var phone = callUri?.path;
    if (phone == null) return null;
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    } else if (phone.startsWith('00')) {
      phone = phone.substring(2);
    } else if (RegExp(r'^0[5-7][0-9]{8}$').hasMatch(phone)) {
      phone = '212${phone.substring(1)}';
    } else if (!RegExp(r'^212[5-7][0-9]{8}$').hasMatch(phone)) {
      return null;
    }
    if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(phone)) return null;
    return Uri.https('wa.me', '/$phone');
  }

  final bool isDriver;
  final RidePath path;
  final LatLng? live;
  final RideStage stage;
  final DateTime? liveUpdatedAt;
  final double? liveAccuracy, liveHeading;
  LatLng? freshLocation(DateTime now) =>
      stage.active &&
          live != null &&
          liveUpdatedAt != null &&
          now.difference(liveUpdatedAt!).inSeconds >= -10 &&
          now.difference(liveUpdatedAt!).inSeconds < 30
      ? live
      : null;
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
      title = json['title'] as String,
      createdAt = json['created_at'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as num).toInt(),
              isUtc: true,
            )
          : null,
      isRequest = json['title'] == 'REQUEST_ACCEPTED',
      accepter = json['body'] as String,
      seen = json['seen'] as bool;

  final String id;
  final String bookingId;
  final String title;
  final DateTime? createdAt;
  final bool isRequest;
  final String accepter;
  final bool seen;
}
