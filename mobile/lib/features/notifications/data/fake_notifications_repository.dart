import '../domain/app_notification.dart';
import 'notifications_repository.dart';

/// In-memory [NotificationsRepository] serving realistic French sample data.
///
/// Used until the notification endpoints are wired to the mobile app.
class FakeNotificationsRepository implements NotificationsRepository {
  const FakeNotificationsRepository({
    this.latency = const Duration(milliseconds: 500),
  });

  /// Simulated network latency.
  final Duration latency;

  @override
  Future<List<AppNotification>> loadNotifications() async {
    await Future<void>.delayed(latency);
    return const <AppNotification>[
      AppNotification(
        id: 'notif-1',
        title: 'Trajet confirmé',
        message: 'Salma B. a accepté votre demande pour Guéliz vers EMSI Marrakech.',
        timeLabel: 'Il y a 12 min',
      ),
      AppNotification(
        id: 'notif-2',
        title: 'Nouveau trajet disponible',
        message: 'Omar E. propose 3 places pour Massira vers EMSI Marrakech.',
        timeLabel: 'Il y a 1 h',
      ),
      AppNotification(
        id: 'notif-3',
        title: 'Frais d\'essence partagés',
        message: 'Votre part de 15 MAD a été enregistrée.',
        timeLabel: 'Hier',
        isRead: true,
      ),
    ];
  }
}
