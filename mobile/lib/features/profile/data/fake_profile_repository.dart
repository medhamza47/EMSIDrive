import '../domain/student_profile.dart';
import 'profile_repository.dart';

/// In-memory [ProfileRepository] serving realistic French sample data.
///
/// Used until the profile endpoints are wired to the mobile app.
class FakeProfileRepository implements ProfileRepository {
  const FakeProfileRepository({
    this.latency = const Duration(milliseconds: 500),
  });

  /// Simulated network latency.
  final Duration latency;

  @override
  Future<StudentProfile> loadProfile() async {
    await Future<void>.delayed(latency);
    return const StudentProfile(
      id: 'user-1',
      fullName: 'Yassine Amrani',
      email: 'yassine.amrani@emsi-edu.ma',
      major: 'Génie informatique',
      academicYear: '3ème année',
      rating: 4.7,
      ratingCount: 18,
    );
  }
}
