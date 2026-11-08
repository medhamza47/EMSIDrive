import '../../../core/errors/error_mapper.dart';
import '../../../core/network/authenticated_api.dart';
import '../domain/student_profile.dart';
import 'profile_repository.dart';

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api);
  final AuthenticatedApi _api;
  @override
  Future<StudentProfile> loadProfile() => _request('GET');
  @override
  Future<StudentProfile> saveProfile(StudentProfile profile) =>
      _request('PUT', profile.toUpdateJson());
  Future<StudentProfile> _request(
    String method, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      return StudentProfile.fromJson(
        (await _api.request<Map<String, dynamic>>(method, '/me', data: body))!,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
