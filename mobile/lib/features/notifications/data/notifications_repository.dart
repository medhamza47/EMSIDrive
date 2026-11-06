import '../domain/app_notification.dart';

/// Access to the notifications shown on the Notifications tab.
///
/// Throws `AppFailure` so the presentation layer can render French copy from a
/// single error taxonomy.
abstract interface class NotificationsRepository {
  /// Loads the notifications of the signed-in student, newest first.
  Future<List<AppNotification>> loadNotifications();
}
