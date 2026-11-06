import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'fake_profile_repository.dart';
import 'profile_repository.dart';

part 'profile_repository_provider.g.dart';

/// Exposes the [ProfileRepository] used by the Profil tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => const FakeProfileRepository();
