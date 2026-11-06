import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'fake_rides_repository.dart';
import 'rides_repository.dart';

part 'rides_repository_provider.g.dart';

/// Exposes the [RidesRepository] used by the Trajets tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.
@Riverpod(keepAlive: true)
RidesRepository ridesRepository(Ref ref) => const FakeRidesRepository();
