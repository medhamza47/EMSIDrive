import 'dart:typed_data';

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
      label != null &&
      label!.trim().isNotEmpty &&
      weekday != null &&
      weekday! >= 1 &&
      weekday! <= 7 &&
      minutes(startTime) != null &&
      minutes(endTime) != null &&
      minutes(endTime)! > minutes(startTime)! &&
      const ['TARGA', 'CENTRE'].contains(campus);
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
  });
  final String name, source;
  final List<CourseSlot> slots;
  final DateTime? validFrom, validUntil;
  final int revision;
  final List<String> warnings;
  final Uint8List? preview;
  factory Timetable.fromJson(
    Map<String, dynamic> json, {
    int? revision,
    Uint8List? preview,
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
  );
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'source': source,
    'revision': revision,
    'confirmed': true,
    'validFrom': date(validFrom!),
    'validUntil': date(validUntil!),
    'slots': slots.map((s) => s.toJson()).toList(),
  };
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
      courseTime = (json['courseTime'] as String).substring(0, 5);
  final RideListing listing;
  final bool toCampus;
  final String courseTime;
}
