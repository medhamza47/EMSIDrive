import '../domain/student_profile.dart';

/// Access to the profile shown on the Profil tab.
///
/// Throws `AppFailure` so the presentation layer can render French copy from a
/// single error taxonomy.
abstract interface class ProfileRepository {
  /// Loads the profile of the signed-in student.
  Future<StudentProfile> loadProfile();
}
