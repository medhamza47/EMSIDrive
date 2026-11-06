import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'fake_notifications_repository.dart';
import 'notifications_repository.dart';

part 'notifications_repository_provider.g.dart';

/// Exposes the [NotificationsRepository] used by the Notifications tab.
///
/// Kept alive so switching tabs does not rebuild the repository. Tests override
/// this provider to inject deterministic data.
@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    const FakeNotificationsRepository();
