import 'package:flutter/foundation.dart';

/// A notification addressed to the student.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isRead = false,
  });

  /// Stable identifier of the notification.
  final String id;

  /// Short headline.
  final String title;

  /// Body of the notification.
  final String message;

  /// Human readable relative time, already formatted by the data layer.
  final String timeLabel;

  /// Whether the student already opened it.
  final bool isRead;

  @override
  bool operator ==(Object other) {
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.timeLabel == timeLabel &&
        other.isRead == isRead;
  }

  @override
  int get hashCode => Object.hash(id, title, message, timeLabel, isRead);
}
