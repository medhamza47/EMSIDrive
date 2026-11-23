import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../../rides/domain/marketplace_models.dart';

class CourseSlot {
  const CourseSlot({
    this.label,
    this.location,
    this.weekday,
    this.startTime,
    this.endTime,
    this.campus,
    this.needsReview = false,
  });
  final String? label, location, startTime, endTime, campus;
  final int? weekday;
  final bool needsReview;
  factory CourseSlot.fromJson(Map<String, dynamic> json) => CourseSlot(
    label: json['label'] as String?,
    location: json['location'] as String?,
    weekday: json['weekday'] as int?,
    startTime: _time(json['startTime']),
    endTime: _time(json['endTime']),
    campus: json['campus'] as String?,
    needsReview: json['needsReview'] as bool? ?? false,
  );
  static String? _time(Object? value) =>
      value is String && value.length >= 5 ? value.substring(0, 5) : null;
  Map<String, dynamic> toJson() => {
    'label': label,
    'location': location,
    'weekday': weekday,
    'startTime': startTime,
    'endTime': endTime,
    'campus': campus,
  };
  bool get complete =>
      weekday != null &&
      weekday! >= 1 &&
      weekday! <= 7 &&
      minutes(startTime) != null &&
      minutes(endTime) != null &&
      minutes(endTime)! > minutes(startTime)!;
  static int compare(CourseSlot a, CourseSlot b) {
    final day = (a.weekday ?? 8).compareTo(b.weekday ?? 8);
    if (day != 0) return day;
    final start = (minutes(a.startTime) ?? 1440).compareTo(
      minutes(b.startTime) ?? 1440,
    );
    return start != 0
        ? start
        : (minutes(a.endTime) ?? 1440).compareTo(minutes(b.endTime) ?? 1440);
  }

  static int? minutes(String? text) {
    if (text == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) return null;
    final parts = text.split(':').map(int.parse).toList();
    return parts[0] < 24 && parts[1] < 60 ? parts[0] * 60 + parts[1] : null;
  }
}

class Timetable {
  const Timetable({
    required this.name,
    required this.source,
    required this.slots,
    this.validFrom,
    this.validUntil,
    this.revision = 0,
    this.warnings = const [],
    this.preview,
    this.analysisJobId,
  });
  final String name, source;
  final List<CourseSlot> slots;
  final DateTime? validFrom, validUntil;
  final int revision;
  final List<String> warnings;
  final Uint8List? preview;
  final String? analysisJobId;
  factory Timetable.fromJson(
    Map<String, dynamic> json, {
    int? revision,
    Uint8List? preview,
    String? analysisJobId,
  }) => Timetable(
    name: json['name'] as String? ?? '',
    source: json['source'] as String,
    slots: (json['slots'] as List)
        .map((s) => CourseSlot.fromJson(s as Map<String, dynamic>))
        .toList(),
    validFrom: DateTime.tryParse(json['validFrom'] as String? ?? ''),
    validUntil: DateTime.tryParse(json['validUntil'] as String? ?? ''),
    revision: revision ?? json['revision'] as int? ?? 0,
    warnings: (json['warnings'] as List? ?? []).cast<String>(),
    preview: preview,
    analysisJobId: analysisJobId,
  );
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'source': source,
    'revision': revision,
    'confirmed': true,
    'validFrom': date(validFrom!),
    'validUntil': date(validUntil!),
    'slots': slots.map((s) => s.toJson()).toList(),
    if (analysisJobId != null) 'analysisJobId': analysisJobId,
  };
  List<AttendanceWindow> get attendance {
    final days = <int, List<CourseSlot>>{};
    for (final slot in slots.where((s) => s.complete)) {
      days.putIfAbsent(slot.weekday!, () => []).add(slot);
    }
    return [
      for (final day in days.keys.toList()..sort())
        AttendanceWindow(
          day,
          days[day]!
              .map((s) => s.startTime!)
              .reduce((a, b) => a.compareTo(b) < 0 ? a : b),
          days[day]!
              .map((s) => s.endTime!)
              .reduce((a, b) => a.compareTo(b) > 0 ? a : b),
        ),
    ];
  }

  static String date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static bool overlaps(List<CourseSlot> slots) {
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final a = slots[i], b = slots[j];
        if (a.complete &&
            b.complete &&
            a.weekday == b.weekday &&
            CourseSlot.minutes(a.startTime)! < CourseSlot.minutes(b.endTime)! &&
            CourseSlot.minutes(b.startTime)! < CourseSlot.minutes(a.endTime)!) {
          return true;
        }
      }
    }
    return false;
  }
}

class ScheduleSuggestion {
  ScheduleSuggestion.fromJson(Map<String, dynamic> json)
    : listing = RideListing.fromJson(
        json['listing'] as Map<String, dynamic>,
        ListingKind.offer,
      ),
      toCampus = json['toCampus'] as bool,
      courseTime = (json['courseTime'] as String).substring(0, 5),
      distanceMeters = (json['distanceMeters'] as num?)?.toInt();
  final RideListing listing;
  final bool toCampus;
  final String courseTime;
  final int? distanceMeters;
}

class AttendanceWindow {
  const AttendanceWindow(this.weekday, this.arrival, this.leaving);
  final int weekday;
  final String arrival, leaving;
}

class ScheduleImportJob {
  ScheduleImportJob.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      status = json['status'] as String,
      errorCode = json['errorCode'] as String?,
      draft = json['draft'] == null
          ? null
          : Timetable.fromJson(
              json['draft'] as Map<String, dynamic>,
              revision: json['revision'] as int,
              analysisJobId: json['id'] as String,
            );
  final String id, status;
  final String? errorCode;
  final Timetable? draft;
  bool get pending => status == 'QUEUED' || status == 'PROCESSING';
}

class ScheduleTravelPreferences {
  const ScheduleTravelPreferences({
    required this.campus,
    required this.point,
    this.radiusMeters = 2000,
    this.commuteMinutes = 30,
    this.marginMinutes = 10,
  });
  final String campus;
  final LatLng point;
  final int radiusMeters, commuteMinutes, marginMinutes;
  factory ScheduleTravelPreferences.fromJson(Map<String, dynamic> json) =>
      ScheduleTravelPreferences(
        campus: json['campus'] as String,
        point: LatLng(
          (json['point']['latitude'] as num).toDouble(),
          (json['point']['longitude'] as num).toDouble(),
        ),
        radiusMeters: json['radiusMeters'] as int,
        commuteMinutes: json['commuteMinutes'] as int,
        marginMinutes: json['marginMinutes'] as int,
      );
  Map<String, dynamic> toJson() => {
    'campus': campus,
    'point': {'latitude': point.latitude, 'longitude': point.longitude},
    'radiusMeters': radiusMeters,
    'commuteMinutes': commuteMinutes,
    'marginMinutes': marginMinutes,
  };
}
