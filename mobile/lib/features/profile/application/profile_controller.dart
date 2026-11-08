import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/session_id_provider.dart';
import '../../home/application/home_controller.dart';
import '../data/profile_repository_provider.dart';
import '../domain/student_profile.dart';
import '../../../core/errors/app_failure.dart';
part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  Future<StudentProfile> build() {
    ref.watch(sessionIdProvider);
    return ref.watch(profileRepositoryProvider).loadProfile();
  }

  Future<void> save(StudentProfile profile) async {
    final session = ref.read(sessionIdProvider);
    final saved = await ref
        .read(profileRepositoryProvider)
        .saveProfile(profile);
    if (!ref.mounted || ref.read(sessionIdProvider) != session) {
      throw const UnauthorizedFailure(message: 'Account changed');
    }
    state = AsyncData(saved);
    ref.invalidate(homeControllerProvider);
  }
}
