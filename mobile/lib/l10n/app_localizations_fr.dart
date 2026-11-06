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

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle => 'Utilisez votre adresse email étudiant EMSI.';

  @override
  String get emailLabel => 'Email étudiant';

  @override
  String get emailHint => 'prenom.nom@emsi-edu.ma';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get forgotPasswordLabel => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordUnavailableMessage =>
      'La réinitialisation du mot de passe sera disponible prochainement.';

  @override
  String get loginSubmitLabel => 'Se connecter';

  @override
  String get loginNoAccountPrompt => 'Pas encore de compte ?';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get registerSubtitle =>
      'Créez votre compte avec votre email étudiant EMSI.';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get fullNameHint => 'Yassine El Amrani';

  @override
  String get phoneNumberLabel => 'Téléphone (optionnel)';

  @override
  String get phoneNumberHint => '+212612345678';

  @override
  String get passwordHelper => '8 caractères minimum.';

  @override
  String get registerSubmitLabel => 'Créer mon compte';

  @override
  String get registerHasAccountPrompt => 'Déjà un compte ?';

  @override
  String get createAccountLinkLabel => 'Créer un compte';

  @override
  String get loginLinkLabel => 'Se connecter';

  @override
  String get registerSuccessMessage =>
      'Votre compte a été créé. Bienvenue sur EMSIDrive !';

  @override
  String get validationEmailRequired => 'L\'adresse email est obligatoire.';

  @override
  String get validationEmailInvalid => 'Saisissez une adresse email valide.';

  @override
  String validationEmailDomain(String domain) {
    return 'Utilisez votre adresse email étudiante EMSI (@$domain).';
  }

  @override
  String get validationPasswordRequired => 'Le mot de passe est obligatoire.';

  @override
  String validationPasswordTooShort(int min) {
    return 'Le mot de passe doit contenir au moins $min caractères.';
  }

  @override
  String validationPasswordTooLong(int max) {
    return 'Le mot de passe ne peut pas dépasser $max caractères.';
  }

  @override
  String get validationFullNameRequired => 'Le nom complet est obligatoire.';

  @override
  String validationFullNameTooLong(int max) {
    return 'Le nom complet ne peut pas dépasser $max caractères.';
  }

  @override
  String get validationPhoneNumberInvalid =>
      'Saisissez un numéro valide (9 à 20 chiffres, indicatif autorisé).';

  @override
  String get invalidCredentialsErrorMessage =>
      'Email ou mot de passe incorrect.';

  @override
  String get emailDomainNotAllowedErrorMessage =>
      'L\'inscription est réservée aux emails étudiants EMSI.';

  @override
  String get emailAlreadyUsedErrorMessage =>
      'Un compte existe déjà avec cette adresse email.';

  @override
  String get accountDisabledErrorMessage =>
      'Ce compte est désactivé. Contactez l\'administration.';

  @override
  String get timeoutErrorMessage =>
      'Le serveur met trop de temps à répondre. Réessayez.';

  @override
  String get homeGreeting => 'Bonjour';

  @override
  String get homeSearchRideTitle => 'Je cherche un trajet';

  @override
  String get homeSearchRideSubtitle =>
      'Trouvez un étudiant qui part dans votre direction.';

  @override
  String get homeOfferRideTitle => 'Je propose un trajet';

  @override
  String get homeOfferRideSubtitle =>
      'Partagez votre moto ou votre voiture et les frais d\'essence.';

  @override
  String get homeUpcomingTripsTitle => 'Prochains trajets';

  @override
  String homeTripRoute(String origin, String destination) {
    return '$origin vers $destination';
  }

  @override
  String homeTripWithDriver(String time, String driver) {
    return '$time - avec $driver';
  }

  @override
  String homeTripPending(String time) {
    return '$time - en attente';
  }

  @override
  String get homeNoUpcomingTripsTitle => 'Aucun trajet à venir';

  @override
  String get homeNoUpcomingTripsMessage =>
      'Vos prochains trajets confirmés apparaîtront ici.';

  @override
  String get homeErrorTitle => 'Impossible de charger l\'accueil';

  @override
  String get tripStatusConfirmed => 'Confirmé';

  @override
  String get tripStatusPending => 'En attente';
}
