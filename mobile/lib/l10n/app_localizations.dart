import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Application name shown in the app bar and store listing
  ///
  /// In fr, this message translates to:
  /// **'EMSIDrive'**
  String get appName;

  /// Bottom navigation label for the home tab
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// Bottom navigation label for the rides tab
  ///
  /// In fr, this message translates to:
  /// **'Trajets'**
  String get navRides;

  /// Bottom navigation label for the notifications tab
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Bottom navigation label for the profile tab
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// Title of the home screen
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// Title of the rides screen
  ///
  /// In fr, this message translates to:
  /// **'Trajets'**
  String get ridesTitle;

  /// Title of the notifications screen
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Title of the profile screen
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// Shown on screens that are not implemented yet
  ///
  /// In fr, this message translates to:
  /// **'Cet écran sera disponible dans une prochaine version.'**
  String get placeholderMessage;

  /// Label of the retry action shown after a failed request
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryLabel;

  /// Tooltip of the password visibility toggle when the password is hidden
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPasswordTooltip;

  /// Tooltip of the password visibility toggle when the password is visible
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePasswordTooltip;

  /// Fallback message for unexpected failures
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get genericErrorMessage;

  /// Message shown when the API cannot be reached
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Vérifiez votre connexion.'**
  String get networkErrorMessage;

  /// Title of the login screen
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// Subtitle of the login screen explaining which email to use
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre adresse email étudiant EMSI.'**
  String get loginSubtitle;

  /// Label of the email field
  ///
  /// In fr, this message translates to:
  /// **'Email étudiant'**
  String get emailLabel;

  /// Placeholder shown in the email field
  ///
  /// In fr, this message translates to:
  /// **'prenom.nom@emsi-edu.ma'**
  String get emailHint;

  /// Label of the password field
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// Link opening the password reset flow
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPasswordLabel;

  /// Shown when the user taps the password reset link, which is not implemented yet
  ///
  /// In fr, this message translates to:
  /// **'La réinitialisation du mot de passe sera disponible prochainement.'**
  String get forgotPasswordUnavailableMessage;

  /// Label of the submit button on the login screen
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmitLabel;

  /// Prompt shown at the bottom of the login screen before the register link
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get loginNoAccountPrompt;

  /// Title of the register screen
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get registerTitle;

  /// Subtitle of the register screen
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte avec votre email étudiant EMSI.'**
  String get registerSubtitle;

  /// Label of the full name field
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullNameLabel;

  /// Placeholder shown in the full name field
  ///
  /// In fr, this message translates to:
  /// **'Yassine El Amrani'**
  String get fullNameHint;

  /// Label of the optional phone number field
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get phoneNumberLabel;

  /// Placeholder shown in the phone number field
  ///
  /// In fr, this message translates to:
  /// **'+212612345678'**
  String get phoneNumberHint;

  /// Helper text under the password field on the register screen
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum.'**
  String get passwordHelper;

  /// Label of the submit button on the register screen
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get registerSubmitLabel;

  /// Prompt shown at the bottom of the register screen before the login link
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get registerHasAccountPrompt;

  /// Link switching from the login screen to the register screen
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccountLinkLabel;

  /// Link switching from the register screen back to the login screen
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginLinkLabel;

  /// Confirmation shown after a successful registration
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a été créé. Bienvenue sur EMSIDrive !'**
  String get registerSuccessMessage;

  /// Validation message when the email field is empty
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse email est obligatoire.'**
  String get validationEmailRequired;

  /// Validation message when the email is malformed
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse email valide.'**
  String get validationEmailInvalid;

  /// Validation message when the email does not use an allowed student domain
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre adresse email étudiante EMSI (@{domain}).'**
  String validationEmailDomain(String domain);

  /// Validation message when the password field is empty
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est obligatoire.'**
  String get validationPasswordRequired;

  /// Validation message when the password is shorter than the backend minimum
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins {min} caractères.'**
  String validationPasswordTooShort(int min);

  /// Validation message when the password exceeds the backend maximum
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe ne peut pas dépasser {max} caractères.'**
  String validationPasswordTooLong(int max);

  /// Validation message when the full name field is empty
  ///
  /// In fr, this message translates to:
  /// **'Le nom complet est obligatoire.'**
  String get validationFullNameRequired;

  /// Validation message when the full name exceeds the backend maximum
  ///
  /// In fr, this message translates to:
  /// **'Le nom complet ne peut pas dépasser {max} caractères.'**
  String validationFullNameTooLong(int max);

  /// Validation message when the phone number does not match the backend pattern
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro valide (9 à 20 chiffres, indicatif autorisé).'**
  String get validationPhoneNumberInvalid;

  /// Message shown when the backend rejects the credentials
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get invalidCredentialsErrorMessage;

  /// Message shown when the email domain is not in the backend allow-list
  ///
  /// In fr, this message translates to:
  /// **'L\'inscription est réservée aux emails étudiants EMSI.'**
  String get emailDomainNotAllowedErrorMessage;

  /// Message shown when registering with an existing email
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse email.'**
  String get emailAlreadyUsedErrorMessage;

  /// Message shown when the account is disabled
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé. Contactez l\'administration.'**
  String get accountDisabledErrorMessage;

  /// Message shown when the request times out
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre. Réessayez.'**
  String get timeoutErrorMessage;

  /// Greeting prefix shown above the student first name on the home screen
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeGreeting;

  /// Title of the home action leading to the ride search
  ///
  /// In fr, this message translates to:
  /// **'Je cherche un trajet'**
  String get homeSearchRideTitle;

  /// Subtitle of the home action leading to the ride search
  ///
  /// In fr, this message translates to:
  /// **'Trouvez un étudiant qui part dans votre direction.'**
  String get homeSearchRideSubtitle;

  /// Title of the home action leading to publishing a ride
  ///
  /// In fr, this message translates to:
  /// **'Je propose un trajet'**
  String get homeOfferRideTitle;

  /// Subtitle of the home action leading to publishing a ride
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre moto ou votre voiture et les frais d\'essence.'**
  String get homeOfferRideSubtitle;

  /// Title of the upcoming trips section on the home screen
  ///
  /// In fr, this message translates to:
  /// **'Prochains trajets'**
  String get homeUpcomingTripsTitle;

  /// Route line of an upcoming trip card
  ///
  /// In fr, this message translates to:
  /// **'{origin} vers {destination}'**
  String homeTripRoute(String origin, String destination);

  /// Subtitle of an upcoming trip card that names the driver
  ///
  /// In fr, this message translates to:
  /// **'{time} - avec {driver}'**
  String homeTripWithDriver(String time, String driver);

  /// Subtitle of an upcoming trip card whose booking is not confirmed yet
  ///
  /// In fr, this message translates to:
  /// **'{time} - en attente'**
  String homeTripPending(String time);

  /// Empty state title when the student has no upcoming trip
  ///
  /// In fr, this message translates to:
  /// **'Aucun trajet à venir'**
  String get homeNoUpcomingTripsTitle;

  /// Empty state message when the student has no upcoming trip
  ///
  /// In fr, this message translates to:
  /// **'Vos prochains trajets confirmés apparaîtront ici.'**
  String get homeNoUpcomingTripsMessage;

  /// Title of the error state on the home screen
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'accueil'**
  String get homeErrorTitle;

  /// Badge label for a confirmed trip
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get tripStatusConfirmed;

  /// Badge label for a trip waiting for the driver answer
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get tripStatusPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
