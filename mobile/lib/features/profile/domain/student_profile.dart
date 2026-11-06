import 'package:flutter/foundation.dart';

/// Profile summary of the signed-in student.
@immutable
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.major,
    this.academicYear,
    this.photoUrl,
    this.rating,
    this.ratingCount = 0,
  });

  /// Stable identifier of the user.
  final String id;

  /// First and last name.
  final String fullName;

  /// EMSI email address.
  final String email;

  /// Study programme, for example `Génie informatique`.
  final String? major;

  /// Academic year, for example `3ème année`.
  final String? academicYear;

  /// Optional profile picture URL.
  final String? photoUrl;

  /// Average rating out of five, absent until the student receives reviews.
  final double? rating;

  /// Number of reviews backing [rating].
  final int ratingCount;

  @override
  bool operator ==(Object other) {
    return other is StudentProfile &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.major == major &&
        other.academicYear == academicYear &&
        other.photoUrl == photoUrl &&
        other.rating == rating &&
        other.ratingCount == ratingCount;
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    email,
    major,
    academicYear,
    photoUrl,
    rating,
    ratingCount,
  );
}
