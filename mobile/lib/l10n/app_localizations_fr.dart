// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'EMSIDrive';

  @override
  String get navHome => 'Accueil';

  @override
  String get navRides => 'Trajets';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get ridesTitle => 'Trajets';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get profileTitle => 'Profil';

  @override
  String get placeholderMessage =>
      'Cet écran sera disponible dans une prochaine version.';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get showPasswordTooltip => 'Afficher le mot de passe';

  @override
  String get hidePasswordTooltip => 'Masquer le mot de passe';

  @override
  String get genericErrorMessage =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get networkErrorMessage =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.';
}
