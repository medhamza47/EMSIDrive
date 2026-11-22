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
  /// **'Trouver un trajet'**
  String get homeSearchRideTitle;

  /// Subtitle of the home action leading to the ride search
  ///
  /// In fr, this message translates to:
  /// **'Consultez les offres pour rejoindre votre campus.'**
  String get homeSearchRideSubtitle;

  /// Title of the home action leading to publishing a ride
  ///
  /// In fr, this message translates to:
  /// **'Proposer un trajet'**
  String get homeOfferRideTitle;

  /// Subtitle of the home action leading to publishing a ride
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre trajet et vos places disponibles.'**
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

  /// No description provided for @requestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get requestTitle;

  /// No description provided for @offerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un trajet'**
  String get offerTitle;

  /// No description provided for @vehicleMotorcycle.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get vehicleMotorcycle;

  /// No description provided for @vehicleCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get vehicleCar;

  /// No description provided for @vehicleAny.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get vehicleAny;

  /// No description provided for @flowRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez ce champ.'**
  String get flowRequired;

  /// No description provided for @demoOrigin.
  ///
  /// In fr, this message translates to:
  /// **'Guéliz, Marrakech'**
  String get demoOrigin;

  /// No description provided for @demoDistrict.
  ///
  /// In fr, this message translates to:
  /// **'Guéliz'**
  String get demoDistrict;

  /// No description provided for @demoCampus.
  ///
  /// In fr, this message translates to:
  /// **'EMSI Marrakech'**
  String get demoCampus;

  /// No description provided for @tripOrigin.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get tripOrigin;

  /// No description provided for @tripDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get tripDestination;

  /// No description provided for @vehiclePreference.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule souhaité'**
  String get vehiclePreference;

  /// No description provided for @seatCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de places'**
  String get seatCount;

  /// No description provided for @removeSeat.
  ///
  /// In fr, this message translates to:
  /// **'Retirer une place'**
  String get removeSeat;

  /// No description provided for @addSeat.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une place'**
  String get addSeat;

  /// No description provided for @optionalMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message (facultatif)'**
  String get optionalMessage;

  /// No description provided for @demoRideMessage.
  ///
  /// In fr, this message translates to:
  /// **'Je peux aussi partir à 08:30.'**
  String get demoRideMessage;

  /// No description provided for @publishOffer.
  ///
  /// In fr, this message translates to:
  /// **'Publier le trajet'**
  String get publishOffer;

  /// No description provided for @publishRequest.
  ///
  /// In fr, this message translates to:
  /// **'Publier la demande'**
  String get publishRequest;

  /// No description provided for @demoOfferSaved.
  ///
  /// In fr, this message translates to:
  /// **'Trajet proposé dans la démonstration.'**
  String get demoOfferSaved;

  /// No description provided for @nearbyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conducteurs proches'**
  String get nearbyTitle;

  /// No description provided for @nearestSort.
  ///
  /// In fr, this message translates to:
  /// **'Plus proches'**
  String get nearestSort;

  /// No description provided for @ratingSort.
  ///
  /// In fr, this message translates to:
  /// **'Mieux notés'**
  String get ratingSort;

  /// No description provided for @driverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conducteur'**
  String get driverTitle;

  /// No description provided for @averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get averageRating;

  /// No description provided for @vehicleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get vehicleLabel;

  /// No description provided for @offeredTrip.
  ///
  /// In fr, this message translates to:
  /// **'Trajet proposé'**
  String get offeredTrip;

  /// No description provided for @demoDay.
  ///
  /// In fr, this message translates to:
  /// **'Lundi 2 nov.'**
  String get demoDay;

  /// No description provided for @remainingSeats.
  ///
  /// In fr, this message translates to:
  /// **'Places restantes'**
  String get remainingSeats;

  /// No description provided for @fuelContribution.
  ///
  /// In fr, this message translates to:
  /// **'Part des frais d’essence'**
  String get fuelContribution;

  /// No description provided for @sendRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une demande'**
  String get sendRequest;

  /// No description provided for @trackingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi du trajet'**
  String get trackingTitle;

  /// No description provided for @arrivalDistance.
  ///
  /// In fr, this message translates to:
  /// **'À 1,2 km de votre point de départ.'**
  String get arrivalDistance;

  /// No description provided for @onTheWay.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get onTheWay;

  /// No description provided for @messageDriver.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get messageDriver;

  /// No description provided for @callDriver.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get callDriver;

  /// No description provided for @cancelRideRequest.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get cancelRideRequest;

  /// No description provided for @demoOnlyAction.
  ///
  /// In fr, this message translates to:
  /// **'Action indisponible dans la démonstration.'**
  String get demoOnlyAction;

  /// No description provided for @fuelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Frais d’essence'**
  String get fuelTitle;

  /// No description provided for @fuelSummary.
  ///
  /// In fr, this message translates to:
  /// **'Total 40 MAD, partagé entre 4 personnes'**
  String get fuelSummary;

  /// No description provided for @yourShare.
  ///
  /// In fr, this message translates to:
  /// **'Votre part'**
  String get yourShare;

  /// No description provided for @costBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Répartition'**
  String get costBreakdown;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get totalAmount;

  /// No description provided for @passengers.
  ///
  /// In fr, this message translates to:
  /// **'Passagers'**
  String get passengers;

  /// No description provided for @sharePerPerson.
  ///
  /// In fr, this message translates to:
  /// **'Part de chacun'**
  String get sharePerPerson;

  /// No description provided for @participants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @youLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get youLabel;

  /// No description provided for @confirmShare.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ma part'**
  String get confirmShare;

  /// No description provided for @reviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer le trajet'**
  String get reviewTitle;

  /// No description provided for @reviewPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Comment était le trajet avec Salma ?'**
  String get reviewPrompt;

  /// No description provided for @demoRoute.
  ///
  /// In fr, this message translates to:
  /// **'Guéliz vers EMSI Marrakech'**
  String get demoRoute;

  /// No description provided for @reviewHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui vous a plu'**
  String get reviewHighlights;

  /// No description provided for @reviewPunctual.
  ///
  /// In fr, this message translates to:
  /// **'Ponctuelle'**
  String get reviewPunctual;

  /// No description provided for @reviewSafe.
  ///
  /// In fr, this message translates to:
  /// **'Conduite sûre'**
  String get reviewSafe;

  /// No description provided for @reviewFriendly.
  ///
  /// In fr, this message translates to:
  /// **'Sympathique'**
  String get reviewFriendly;

  /// No description provided for @reviewClean.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule propre'**
  String get reviewClean;

  /// No description provided for @reviewComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (facultatif)'**
  String get reviewComment;

  /// No description provided for @demoReviewComment.
  ///
  /// In fr, this message translates to:
  /// **'Trajet agréable, arrivée à l’heure avant le cours.'**
  String get demoReviewComment;

  /// No description provided for @submitReview.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l’évaluation'**
  String get submitReview;

  /// No description provided for @demoReviewSaved.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation envoyée dans la démonstration.'**
  String get demoReviewSaved;

  /// No description provided for @scheduleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon emploi du temps'**
  String get scheduleTitle;

  /// No description provided for @scheduleImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importez votre emploi du temps'**
  String get scheduleImportTitle;

  /// No description provided for @scheduleFormats.
  ///
  /// In fr, this message translates to:
  /// **'Photo, capture d’écran ou PDF'**
  String get scheduleFormats;

  /// No description provided for @chooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get chooseFile;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @removeFile.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removeFile;

  /// No description provided for @scheduleAssistant.
  ///
  /// In fr, this message translates to:
  /// **'L’assistant repère vos heures d’arrivée et de départ et cherche les conducteurs aux mêmes horaires. Cet aperçu utilise un emploi du temps de démonstration.'**
  String get scheduleAssistant;

  /// No description provided for @analyzeSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Analyser mon emploi du temps'**
  String get analyzeSchedule;

  /// No description provided for @slotsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mes créneaux'**
  String get slotsTitle;

  /// No description provided for @reviewSlotsHint.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez si besoin avant de lancer la recherche.'**
  String get reviewSlotsHint;

  /// No description provided for @mondayShort.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get fridayShort;

  /// No description provided for @monday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get friday;

  /// No description provided for @morningTrip.
  ///
  /// In fr, this message translates to:
  /// **'Trajet du matin'**
  String get morningTrip;

  /// No description provided for @eveningTrip.
  ///
  /// In fr, this message translates to:
  /// **'Trajet du soir'**
  String get eveningTrip;

  /// No description provided for @searchSharedTrips.
  ///
  /// In fr, this message translates to:
  /// **'Chercher des trajets partagés'**
  String get searchSharedTrips;

  /// No description provided for @aiLabel.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get aiLabel;

  /// No description provided for @suggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @suggestionsIntro.
  ///
  /// In fr, this message translates to:
  /// **'4 conducteurs ont des horaires proches des vôtres. Triés par compatibilité.'**
  String get suggestionsIntro;

  /// No description provided for @mondayMorning.
  ///
  /// In fr, this message translates to:
  /// **'Lun matin'**
  String get mondayMorning;

  /// No description provided for @tuesdayMorning.
  ///
  /// In fr, this message translates to:
  /// **'Mar matin'**
  String get tuesdayMorning;

  /// No description provided for @thursdayMorning.
  ///
  /// In fr, this message translates to:
  /// **'Jeu matin'**
  String get thursdayMorning;

  /// No description provided for @wednesdayEvening.
  ///
  /// In fr, this message translates to:
  /// **'Mer soir'**
  String get wednesdayEvening;

  /// No description provided for @fridayEvening.
  ///
  /// In fr, this message translates to:
  /// **'Ven soir'**
  String get fridayEvening;

  /// No description provided for @proposeAction.
  ///
  /// In fr, this message translates to:
  /// **'Proposer'**
  String get proposeAction;

  /// No description provided for @compatibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité'**
  String get compatibilityTitle;

  /// No description provided for @yourClasses.
  ///
  /// In fr, this message translates to:
  /// **'Vos cours'**
  String get yourClasses;

  /// No description provided for @driverClasses.
  ///
  /// In fr, this message translates to:
  /// **'Ses cours'**
  String get driverClasses;

  /// No description provided for @sharedClasses.
  ///
  /// In fr, this message translates to:
  /// **'En commun'**
  String get sharedClasses;

  /// No description provided for @matchEveningTime.
  ///
  /// In fr, this message translates to:
  /// **'Retour 18:30'**
  String get matchEveningTime;

  /// No description provided for @matchRoundTrip.
  ///
  /// In fr, this message translates to:
  /// **'Aller 08:15 – retour 12:30'**
  String get matchRoundTrip;

  /// No description provided for @fuelPerTrip.
  ///
  /// In fr, this message translates to:
  /// **'Part d’essence par trajet'**
  String get fuelPerTrip;

  /// No description provided for @proposeCarpool.
  ///
  /// In fr, this message translates to:
  /// **'Proposer le covoiturage'**
  String get proposeCarpool;

  /// No description provided for @ignoreSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get ignoreSuggestion;

  /// No description provided for @demoProposalSaved.
  ///
  /// In fr, this message translates to:
  /// **'Proposition envoyée dans la démonstration.'**
  String get demoProposalSaved;

  /// No description provided for @proposalNotification.
  ///
  /// In fr, this message translates to:
  /// **'Omar K. vous propose de covoiturer'**
  String get proposalNotification;

  /// No description provided for @proposalNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'4 créneaux en commun : lundi, mardi et jeudi matin. Compatibilité 85 %.'**
  String get proposalNotificationBody;

  /// No description provided for @acceptedNotification.
  ///
  /// In fr, this message translates to:
  /// **'Salma B. a accepté votre proposition'**
  String get acceptedNotification;

  /// No description provided for @acceptedNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'Premier trajet lundi à 08:15, départ Guéliz.'**
  String get acceptedNotificationBody;

  /// No description provided for @matchNotification.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau conducteur compatible'**
  String get matchNotification;

  /// No description provided for @matchNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'Imane R. a un trajet mercredi soir qui correspond à votre emploi du temps.'**
  String get matchNotificationBody;

  /// No description provided for @reminderNotification.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de trajet'**
  String get reminderNotification;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'Demain 08:15 avec Salma B. Pensez à confirmer votre part d’essence.'**
  String get reminderNotificationBody;

  /// No description provided for @acceptProposal.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get acceptProposal;

  /// No description provided for @declineProposal.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get declineProposal;

  /// No description provided for @proposalAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Proposition acceptée'**
  String get proposalAccepted;

  /// No description provided for @proposalDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Proposition refusée'**
  String get proposalDeclined;

  /// No description provided for @signOutLabel.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOutLabel;

  /// No description provided for @signOutError.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion a échoué. Réessayez.'**
  String get signOutError;

  /// No description provided for @rideRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get rideRequests;

  /// No description provided for @rideOffers.
  ///
  /// In fr, this message translates to:
  /// **'Offres'**
  String get rideOffers;

  /// No description provided for @myAcceptedRides.
  ///
  /// In fr, this message translates to:
  /// **'Mes trajets'**
  String get myAcceptedRides;

  /// No description provided for @refreshListings.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshListings;

  /// No description provided for @marketplaceLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au service indisponible. Réessayez.'**
  String get marketplaceLoadError;

  /// No description provided for @noRideRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande à venir.'**
  String get noRideRequests;

  /// No description provided for @noRideOffers.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre à venir.'**
  String get noRideOffers;

  /// No description provided for @noAcceptedRides.
  ///
  /// In fr, this message translates to:
  /// **'Aucun trajet accepté.'**
  String get noAcceptedRides;

  /// No description provided for @rideRequestDetail.
  ///
  /// In fr, this message translates to:
  /// **'Demande de trajet'**
  String get rideRequestDetail;

  /// No description provided for @rideOfferDetail.
  ///
  /// In fr, this message translates to:
  /// **'Offre de trajet'**
  String get rideOfferDetail;

  /// No description provided for @approximatePickup.
  ///
  /// In fr, this message translates to:
  /// **'Le point en ville est approximatif avant l’acceptation.'**
  String get approximatePickup;

  /// No description provided for @acceptRide.
  ///
  /// In fr, this message translates to:
  /// **'Accepter le trajet'**
  String get acceptRide;

  /// No description provided for @acceptRideError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’accepter ce trajet. Vérifiez sa disponibilité.'**
  String get acceptRideError;

  /// No description provided for @ownRideListing.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez publié cette annonce.'**
  String get ownRideListing;

  /// No description provided for @rideUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce trajet n’est plus disponible.'**
  String get rideUnavailable;

  /// No description provided for @acceptedRideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trajet accepté'**
  String get acceptedRideTitle;

  /// No description provided for @rideChat.
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get rideChat;

  /// No description provided for @driverLocation.
  ///
  /// In fr, this message translates to:
  /// **'Position du conducteur'**
  String get driverLocation;

  /// No description provided for @sendChatError.
  ///
  /// In fr, this message translates to:
  /// **'Le message n’a pas pu être envoyé.'**
  String get sendChatError;

  /// No description provided for @liveSharingError.
  ///
  /// In fr, this message translates to:
  /// **'Le partage de position a rencontré un problème.'**
  String get liveSharingError;

  /// No description provided for @youDrive.
  ///
  /// In fr, this message translates to:
  /// **'Vous conduisez'**
  String get youDrive;

  /// No description provided for @youRide.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes passager'**
  String get youRide;

  /// No description provided for @locationSharingHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre passager voit votre position pendant que cet écran reste ouvert et que le partage est actif.'**
  String get locationSharingHint;

  /// No description provided for @startLiveSharing.
  ///
  /// In fr, this message translates to:
  /// **'Partager ma position'**
  String get startLiveSharing;

  /// No description provided for @stopLiveSharing.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le partage'**
  String get stopLiveSharing;

  /// No description provided for @noLiveLocation.
  ///
  /// In fr, this message translates to:
  /// **'Le conducteur ne partage pas sa position actuellement.'**
  String get noLiveLocation;

  /// No description provided for @noChatMessages.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour le moment.'**
  String get noChatMessages;

  /// No description provided for @writeChatMessage.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un message'**
  String get writeChatMessage;

  /// No description provided for @sendChatMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le message'**
  String get sendChatMessage;

  /// No description provided for @noRideNotices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification de trajet.'**
  String get noRideNotices;

  /// No description provided for @openAcceptedRide.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le trajet et le chat'**
  String get openAcceptedRide;

  /// No description provided for @departureMustBeFuture.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une date et une heure de départ à venir.'**
  String get departureMustBeFuture;

  /// No description provided for @publishRideError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de publier le trajet. Réessayez.'**
  String get publishRideError;

  /// No description provided for @requestAcceptedNotice.
  ///
  /// In fr, this message translates to:
  /// **'{name} a accepté votre demande'**
  String requestAcceptedNotice(String name);

  /// No description provided for @offerAcceptedNotice.
  ///
  /// In fr, this message translates to:
  /// **'{name} a accepté votre offre'**
  String offerAcceptedNotice(String name);

  /// No description provided for @campusTarga.
  ///
  /// In fr, this message translates to:
  /// **'EMSI Marrakech Targa'**
  String get campusTarga;

  /// No description provided for @campusCentre.
  ///
  /// In fr, this message translates to:
  /// **'EMSI Marrakech Centre'**
  String get campusCentre;

  /// No description provided for @campusCentreAddress.
  ///
  /// In fr, this message translates to:
  /// **'Lot Bouizgaren, route de Safi'**
  String get campusCentreAddress;

  /// No description provided for @campusDirectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le sens du trajet et un campus EMSI.'**
  String get campusDirectionHint;

  /// No description provided for @towardCampus.
  ///
  /// In fr, this message translates to:
  /// **'Vers l’EMSI'**
  String get towardCampus;

  /// No description provided for @fromCampus.
  ///
  /// In fr, this message translates to:
  /// **'Depuis l’EMSI'**
  String get fromCampus;

  /// No description provided for @chooseMapPoint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un point sur la carte'**
  String get chooseMapPoint;

  /// No description provided for @changeMapPoint.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le point ou voir l’itinéraire'**
  String get changeMapPoint;

  /// No description provided for @marrakechMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte de Marrakech'**
  String get marrakechMapTitle;

  /// No description provided for @mapUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La carte de Marrakech est indisponible.'**
  String get mapUnavailable;

  /// No description provided for @pickPointHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez la carte pour placer le repère à Marrakech.'**
  String get pickPointHint;

  /// No description provided for @pointOutsideMarrakech.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un point à l’intérieur de Marrakech.'**
  String get pointOutsideMarrakech;

  /// No description provided for @locationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Activez la localisation ou choisissez un point sur la carte.'**
  String get locationDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez la localisation dans les réglages ou choisissez un point sur la carte.'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable. Choisissez un point sur la carte.'**
  String get locationUnavailable;

  /// No description provided for @locatingPosition.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de la position…'**
  String get locatingPosition;

  /// No description provided for @useMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get useMyLocation;

  /// No description provided for @previewRoadRoute.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’itinéraire'**
  String get previewRoadRoute;

  /// No description provided for @calculatingRoute.
  ///
  /// In fr, this message translates to:
  /// **'Calcul en cours…'**
  String get calculatingRoute;

  /// No description provided for @roadRouteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de calculer l’itinéraire. Vous pouvez réessayer.'**
  String get roadRouteError;

  /// No description provided for @routingPrivacyHint.
  ///
  /// In fr, this message translates to:
  /// **'Le calcul d’itinéraire envoie les deux points à OSRM.'**
  String get routingPrivacyHint;

  /// No description provided for @roadRouteSource.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire routier estimé · OSRM'**
  String get roadRouteSource;

  /// No description provided for @confirmMapPoint.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ce point'**
  String get confirmMapPoint;

  /// No description provided for @chosenCoordinates.
  ///
  /// In fr, this message translates to:
  /// **'Point choisi : {latitude}, {longitude}'**
  String chosenCoordinates(String latitude, String longitude);

  /// No description provided for @roadRouteSummary.
  ///
  /// In fr, this message translates to:
  /// **'{distance} km · environ {minutes} min'**
  String roadRouteSummary(String distance, int minutes);

  /// No description provided for @seatsValue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 place} other{{count} places}}'**
  String seatsValue(int count);

  /// No description provided for @nearbyDriverSummary.
  ///
  /// In fr, this message translates to:
  /// **'{major} · {distance} km · {time}'**
  String nearbyDriverSummary(String major, String distance, String time);

  /// No description provided for @driverAcademicSummary.
  ///
  /// In fr, this message translates to:
  /// **'{major} · EMSI Marrakech'**
  String driverAcademicSummary(String major);

  /// No description provided for @amountMad.
  ///
  /// In fr, this message translates to:
  /// **'{amount} MAD'**
  String amountMad(int amount);

  /// No description provided for @arrivalEstimate.
  ///
  /// In fr, this message translates to:
  /// **'{name} arrive dans 4 min'**
  String arrivalEstimate(String name);

  /// No description provided for @ratingOutOfFive.
  ///
  /// In fr, this message translates to:
  /// **'{value} sur 5'**
  String ratingOutOfFive(int value);

  /// No description provided for @detectedSlots.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 cours détecté cette semaine} other{{count} cours détectés cette semaine}}'**
  String detectedSlots(int count);

  /// No description provided for @commonSlots.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 créneau en commun} other{{count} créneaux en commun}}'**
  String commonSlots(int count);

  /// No description provided for @suggestionDriverSummary.
  ///
  /// In fr, this message translates to:
  /// **'{major} · {distance} km de chez vous'**
  String suggestionDriverSummary(String major, String distance);

  /// No description provided for @matchMorningTime.
  ///
  /// In fr, this message translates to:
  /// **'Aller {time}'**
  String matchMorningTime(String time);

  /// No description provided for @timetableImportHint.
  ///
  /// In fr, this message translates to:
  /// **'Importez un seul emploi du temps lisible, recadré sur votre groupe. JPEG, PNG ou PDF (3 pages maximum), jusqu’à 8 Mo.'**
  String get timetableImportHint;

  /// No description provided for @timetableGroup.
  ///
  /// In fr, this message translates to:
  /// **'Classe / groupe'**
  String get timetableGroup;

  /// No description provided for @timetableGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le groupe exact si le document en contient plusieurs.'**
  String get timetableGroupHint;

  /// No description provided for @timetableAiNotice.
  ///
  /// In fr, this message translates to:
  /// **'L’analyse transmet votre document à Groq. Vérifiez les cours extraits avant de les enregistrer. Le serveur ne conserve pas votre photo.'**
  String get timetableAiNotice;

  /// No description provided for @timetableManual.
  ///
  /// In fr, this message translates to:
  /// **'Saisir mes cours manuellement'**
  String get timetableManual;

  /// No description provided for @timetableEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon emploi du temps'**
  String get timetableEdit;

  /// No description provided for @timetableDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon emploi du temps'**
  String get timetableDelete;

  /// No description provided for @timetableDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les cours enregistrés et désactiver leurs suggestions ?'**
  String get timetableDeleteConfirm;

  /// No description provided for @timetableCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get timetableCancel;

  /// No description provided for @timetableReload.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get timetableReload;

  /// No description provided for @timetableReview.
  ///
  /// In fr, this message translates to:
  /// **'Comparez chaque cours au document original. Corrigez les champs incertains et indiquez la période pendant laquelle ce planning hebdomadaire s’applique.'**
  String get timetableReview;

  /// No description provided for @timetableOriginal.
  ///
  /// In fr, this message translates to:
  /// **'Voir la photo originale'**
  String get timetableOriginal;

  /// No description provided for @timetableName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’emploi du temps'**
  String get timetableName;

  /// No description provided for @timetableFrom.
  ///
  /// In fr, this message translates to:
  /// **'Valable à partir du'**
  String get timetableFrom;

  /// No description provided for @timetableUntil.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu’au'**
  String get timetableUntil;

  /// No description provided for @timetableUnknown.
  ///
  /// In fr, this message translates to:
  /// **'À renseigner'**
  String get timetableUnknown;

  /// No description provided for @timetableNeedsReview.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier : touchez ce cours pour le corriger et le valider.'**
  String get timetableNeedsReview;

  /// No description provided for @timetableRemoveCourse.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce cours'**
  String get timetableRemoveCourse;

  /// No description provided for @timetableAddCourse.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un cours'**
  String get timetableAddCourse;

  /// No description provided for @timetableOverlap.
  ///
  /// In fr, this message translates to:
  /// **'Des cours se chevauchent le même jour. Corrigez les horaires.'**
  String get timetableOverlap;

  /// No description provided for @timetableIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le nom, des dates ordonnées (un an maximum) et tous les cours : jour, campus, heures de début et de fin. Validez chaque cours incertain.'**
  String get timetableIncomplete;

  /// No description provided for @timetableConfirm.
  ///
  /// In fr, this message translates to:
  /// **'J’ai vérifié les cours, les horaires, les campus et les dates.'**
  String get timetableConfirm;

  /// No description provided for @timetableSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer mon emploi du temps'**
  String get timetableSave;

  /// No description provided for @timetableThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get timetableThursday;

  /// No description provided for @timetableFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get timetableFriday;

  /// No description provided for @timetableSaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get timetableSaturday;

  /// No description provided for @timetableSunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get timetableSunday;

  /// No description provided for @timetableCourse.
  ///
  /// In fr, this message translates to:
  /// **'Corriger un cours'**
  String get timetableCourse;

  /// No description provided for @timetableSubject.
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get timetableSubject;

  /// No description provided for @timetableDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get timetableDay;

  /// No description provided for @timetableStart.
  ///
  /// In fr, this message translates to:
  /// **'Début (HH:mm)'**
  String get timetableStart;

  /// No description provided for @timetableEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin (HH:mm)'**
  String get timetableEnd;

  /// No description provided for @timetableCampus.
  ///
  /// In fr, this message translates to:
  /// **'Campus'**
  String get timetableCampus;

  /// No description provided for @timetableRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle / lieu (facultatif)'**
  String get timetableRoom;

  /// No description provided for @timetableRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get timetableRequired;

  /// No description provided for @timetableTimeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez HH:mm et une fin après le début.'**
  String get timetableTimeInvalid;

  /// No description provided for @timetableValidateCourse.
  ///
  /// In fr, this message translates to:
  /// **'Valider ce cours'**
  String get timetableValidateCourse;

  /// No description provided for @timetableMatchingHint.
  ///
  /// In fr, this message translates to:
  /// **'Offres publiées pour les 7 prochains jours, selon votre premier et dernier cours et leur campus. Pour l’aller : durée estimée + 10 min de marge, avec jusqu’à 60 min d’avance. Pour le retour : départ dans l’heure après le dernier cours. Vérifiez le point de rendez-vous et le trajet avant de réserver.'**
  String get timetableMatchingHint;

  /// No description provided for @timetableCommute.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée de votre trajet : {minutes} min'**
  String timetableCommute(int minutes);

  /// No description provided for @timetableNoMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre disponible ne correspond actuellement à vos horaires et à votre campus. Réessayez quand de nouveaux trajets seront publiés.'**
  String get timetableNoMatches;

  /// No description provided for @timetableBeforeCourse.
  ///
  /// In fr, this message translates to:
  /// **'Début du premier cours :'**
  String get timetableBeforeCourse;

  /// No description provided for @timetableAfterCourse.
  ///
  /// In fr, this message translates to:
  /// **'Fin du dernier cours :'**
  String get timetableAfterCourse;

  /// No description provided for @timetableFileSize.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier doit contenir entre 1 octet et 8 Mo.'**
  String get timetableFileSize;

  /// No description provided for @timetablePdfPages.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un PDF de 1 à 3 pages.'**
  String get timetablePdfPages;

  /// No description provided for @timetableFileError.
  ///
  /// In fr, this message translates to:
  /// **'Document illisible ou format non pris en charge. Choisissez une image JPEG/PNG ou un PDF non protégé.'**
  String get timetableFileError;

  /// No description provided for @timetableSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Reconnectez-vous pour accéder à votre emploi du temps.'**
  String get timetableSignIn;

  /// No description provided for @timetableNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible ou délai dépassé. Vérifiez votre connexion puis réessayez.'**
  String get timetableNetworkError;

  /// No description provided for @timetableAmbiguous.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs groupes ou tableaux sont visibles. Recadrez votre emploi du temps ou précisez le groupe exact.'**
  String get timetableAmbiguous;

  /// No description provided for @timetableNotDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun emploi du temps exploitable détecté. Choisissez une image plus nette et bien cadrée.'**
  String get timetableNotDetected;

  /// No description provided for @timetableRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’analyses ou service occupé. Patientez avant de réessayer ; vous pouvez aussi saisir vos cours manuellement.'**
  String get timetableRateLimit;

  /// No description provided for @timetableAiError.
  ///
  /// In fr, this message translates to:
  /// **'L’analyse IA est momentanément indisponible. Réessayez ou saisissez vos cours manuellement.'**
  String get timetableAiError;

  /// No description provided for @timetableChanged.
  ///
  /// In fr, this message translates to:
  /// **'Votre emploi du temps a changé depuis son ouverture. Revenez à l’import, actualisez puis ouvrez la dernière version.'**
  String get timetableChanged;

  /// No description provided for @timetableNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez et confirmez d’abord votre emploi du temps.'**
  String get timetableNotSaved;

  /// No description provided for @timetableGenericError.
  ///
  /// In fr, this message translates to:
  /// **'L’opération a échoué. Réessayez ; votre emploi du temps enregistré reste disponible.'**
  String get timetableGenericError;

  /// No description provided for @navPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Planning'**
  String get navPlanning;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes informations'**
  String get profileEdit;

  /// No description provided for @profileEditHint.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez vos informations à chaque connexion. Les champs facultatifs peuvent être complétés plus tard.'**
  String get profileEditHint;

  /// No description provided for @profilePersonal.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profilePersonal;

  /// No description provided for @profileStudies.
  ///
  /// In fr, this message translates to:
  /// **'Mes études'**
  String get profileStudies;

  /// No description provided for @profilePreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de trajet'**
  String get profilePreferences;

  /// No description provided for @profilePreferencesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ces choix seront proposés dans vos prochains formulaires.'**
  String get profilePreferencesHint;

  /// No description provided for @profileCampus.
  ///
  /// In fr, this message translates to:
  /// **'Campus habituel'**
  String get profileCampus;

  /// No description provided for @profileNoPreference.
  ///
  /// In fr, this message translates to:
  /// **'Aucune préférence'**
  String get profileNoPreference;

  /// No description provided for @profileMajor.
  ///
  /// In fr, this message translates to:
  /// **'Filière / groupe'**
  String get profileMajor;

  /// No description provided for @profileMajorHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : 5IIR · 2DSI'**
  String get profileMajorHint;

  /// No description provided for @profileYear.
  ///
  /// In fr, this message translates to:
  /// **'Année universitaire'**
  String get profileYear;

  /// No description provided for @profileYearHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : 2026-2027'**
  String get profileYearHint;

  /// No description provided for @profileNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileNotSet;

  /// No description provided for @profileEmailFixed.
  ///
  /// In fr, this message translates to:
  /// **'Cet email identifie votre compte.'**
  String get profileEmailFixed;

  /// No description provided for @profileNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez votre nom complet.'**
  String get profileNameRequired;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide : 9 à 20 chiffres, avec éventuellement un + au début (20 caractères maximum).'**
  String get profilePhoneInvalid;

  /// No description provided for @profileSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations sont enregistrées.'**
  String get profileSaved;

  /// No description provided for @profileSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour retrouver votre profil.'**
  String get profileSignIn;

  /// No description provided for @profileOperationError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ou d’enregistrer vos informations. Réessayez.'**
  String get profileOperationError;

  /// No description provided for @planningIntro.
  ///
  /// In fr, this message translates to:
  /// **'Vos cours et vos trajets, organisés par journée.'**
  String get planningIntro;

  /// No description provided for @planningEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre semaine commence ici'**
  String get planningEmptyTitle;

  /// No description provided for @planningEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Importez votre emploi du temps ou saisissez vos cours pour trouver des trajets adaptés à vos horaires.'**
  String get planningEmptyHint;

  /// No description provided for @planningImport.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mon emploi du temps'**
  String get planningImport;

  /// No description provided for @planningManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon emploi du temps'**
  String get planningManage;

  /// No description provided for @planningFreeDay.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours enregistré pour cette journée.'**
  String get planningFreeDay;

  /// No description provided for @homeActionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment voyagez-vous ?'**
  String get homeActionsTitle;

  /// No description provided for @ridesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez une place, proposez la vôtre et retrouvez vos réservations.'**
  String get ridesIntro;

  /// No description provided for @ridesTools.
  ///
  /// In fr, this message translates to:
  /// **'Autres outils'**
  String get ridesTools;

  /// No description provided for @rideFormRoute.
  ///
  /// In fr, this message translates to:
  /// **'Votre itinéraire'**
  String get rideFormRoute;

  /// No description provided for @rideFormRouteHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le campus et votre point de rendez-vous.'**
  String get rideFormRouteHint;

  /// No description provided for @rideFormDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get rideFormDeparture;

  /// No description provided for @rideFormDetails.
  ///
  /// In fr, this message translates to:
  /// **'Places et préférences'**
  String get rideFormDetails;

  /// No description provided for @rideFormSummary.
  ///
  /// In fr, this message translates to:
  /// **'Votre trajet en un coup d’œil'**
  String get rideFormSummary;

  /// No description provided for @ridePointReady.
  ///
  /// In fr, this message translates to:
  /// **'Point de rendez-vous sélectionné'**
  String get ridePointReady;

  /// No description provided for @mapSelectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre point de rendez-vous'**
  String get mapSelectionTitle;

  /// No description provided for @mapSelectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un lieu sur la carte ou utilisez votre position.'**
  String get mapSelectionHint;

  /// No description provided for @mapSelectedHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez déplacer le repère en touchant un autre lieu.'**
  String get mapSelectedHint;

  /// No description provided for @mapCampusSummary.
  ///
  /// In fr, this message translates to:
  /// **'Campus du trajet'**
  String get mapCampusSummary;

  /// No description provided for @mapCoordinatesDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les coordonnées'**
  String get mapCoordinatesDetails;

  /// No description provided for @mapRouteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de l’itinéraire'**
  String get mapRouteLabel;

  /// No description provided for @rideMyListings.
  ///
  /// In fr, this message translates to:
  /// **'Mes annonces'**
  String get rideMyListings;

  /// No description provided for @rideActiveTrips.
  ///
  /// In fr, this message translates to:
  /// **'En cours et à venir'**
  String get rideActiveTrips;

  /// No description provided for @rideHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get rideHistory;

  /// No description provided for @rideNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun trajet terminé ou annulé.'**
  String get rideNoHistory;

  /// No description provided for @rideEditListing.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’annonce'**
  String get rideEditListing;

  /// No description provided for @rideSaveListing.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get rideSaveListing;

  /// No description provided for @rideCancelListing.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’annonce'**
  String get rideCancelListing;

  /// No description provided for @rideCancelBooking.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette réservation'**
  String get rideCancelBooking;

  /// No description provided for @rideStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le trajet'**
  String get rideStart;

  /// No description provided for @rideComplete.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le trajet'**
  String get rideComplete;

  /// No description provided for @rideActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible. Le trajet a peut-être changé. Actualisez puis réessayez.'**
  String get rideActionFailed;

  /// No description provided for @rideConfirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l’action'**
  String get rideConfirmAction;

  /// No description provided for @rideCancelListingHint.
  ///
  /// In fr, this message translates to:
  /// **'L’annonce sera fermée et toutes ses réservations actives seront annulées. Les participants seront prévenus.'**
  String get rideCancelListingHint;

  /// No description provided for @rideCancelBookingHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation sera annulée et l’autre participant sera prévenu.'**
  String get rideCancelBookingHint;

  /// No description provided for @rideStartHint.
  ///
  /// In fr, this message translates to:
  /// **'Le trajet commencera pour tous les passagers confirmés. Les nouvelles réservations seront fermées.'**
  String get rideStartHint;

  /// No description provided for @rideCompleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Le trajet sera terminé pour tous les passagers et le partage de position sera arrêté.'**
  String get rideCompleteHint;

  /// No description provided for @rideConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get rideConfirm;

  /// No description provided for @rideKeep.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get rideKeep;

  /// No description provided for @rideReadOnlyChat.
  ///
  /// In fr, this message translates to:
  /// **'Ce trajet est clos. Les messages restent consultables.'**
  String get rideReadOnlyChat;

  /// No description provided for @rideEditLocked.
  ///
  /// In fr, this message translates to:
  /// **'La modification est disponible avant toute réservation. Pour changer un trajet déjà réservé, annulez l’annonce et prévenez les participants.'**
  String get rideEditLocked;

  /// No description provided for @rideStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get rideStatusOpen;

  /// No description provided for @rideStatusFull.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get rideStatusFull;

  /// No description provided for @rideStatusMatched.
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get rideStatusMatched;

  /// No description provided for @rideStatusOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get rideStatusOngoing;

  /// No description provided for @rideStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get rideStatusCompleted;

  /// No description provided for @rideStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get rideStatusCancelled;

  /// No description provided for @rideStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get rideStatusExpired;

  /// No description provided for @rideNoticeCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Le trajet a été annulé'**
  String get rideNoticeCancelled;

  /// No description provided for @rideNoticeStarted.
  ///
  /// In fr, this message translates to:
  /// **'Le conducteur a démarré le trajet'**
  String get rideNoticeStarted;

  /// No description provided for @rideNoticeCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Le trajet est terminé'**
  String get rideNoticeCompleted;

  /// No description provided for @sessionRestoring.
  ///
  /// In fr, this message translates to:
  /// **'Restauration de votre session…'**
  String get sessionRestoring;

  /// No description provided for @sessionRestoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier votre session. Vérifiez votre connexion et réessayez. Vos identifiants enregistrés sont conservés.'**
  String get sessionRestoreUnavailable;

  /// No description provided for @sessionRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get sessionRetry;

  /// No description provided for @sessionUseAnotherAccount.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un autre compte'**
  String get sessionUseAnotherAccount;

  /// No description provided for @biometricScanning.
  ///
  /// In fr, this message translates to:
  /// **'Touchez le capteur d’empreinte…'**
  String get biometricScanning;

  /// No description provided for @biometricUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte reconnue'**
  String get biometricUnlocked;

  /// No description provided for @biometricUsePassword.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le mot de passe'**
  String get biometricUsePassword;

  /// No description provided for @biometricEnableReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre empreinte pour activer la connexion rapide'**
  String get biometricEnableReason;

  /// No description provided for @biometricLockedOut.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez plus tard ou utilisez votre mot de passe.'**
  String get biometricLockedOut;

  /// No description provided for @biometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune empreinte n’est disponible sur cet appareil. Utilisez votre mot de passe.'**
  String get biometricUnavailable;

  /// No description provided for @biometricFailed.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte non reconnue. Réessayez.'**
  String get biometricFailed;

  /// No description provided for @biometricSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get biometricSecurityTitle;

  /// No description provided for @biometricSettingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par empreinte'**
  String get biometricSettingTitle;

  /// No description provided for @biometricSettingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous connecter avec votre empreinte au lieu de l’email et du mot de passe.'**
  String get biometricSettingSubtitle;

  /// No description provided for @biometricSettingUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez une empreinte dans les réglages du téléphone pour activer cette option.'**
  String get biometricSettingUnavailable;

  /// No description provided for @biometricOfferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer l’empreinte ?'**
  String get biometricOfferTitle;

  /// No description provided for @biometricOfferBody.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous ensuite d’une simple empreinte, même après une déconnexion. Votre mot de passe n’est jamais enregistré sur le téléphone.'**
  String get biometricOfferBody;

  /// No description provided for @biometricUnlinked.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n’est plus lié à votre compte. Connectez-vous avec votre mot de passe.'**
  String get biometricUnlinked;

  /// No description provided for @biometricNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au serveur impossible. Vérifiez votre réseau et réessayez.'**
  String get biometricNetworkError;

  /// No description provided for @biometricWelcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour, {name}'**
  String biometricWelcomeBack(String name);

  /// No description provided for @biometricSignInButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec l’empreinte'**
  String get biometricSignInButton;

  /// No description provided for @biometricSignInReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre identité pour vous connecter à EMSIDrive'**
  String get biometricSignInReason;

  /// No description provided for @biometricSwitchAccount.
  ///
  /// In fr, this message translates to:
  /// **'Changer de compte'**
  String get biometricSwitchAccount;

  /// No description provided for @biometricPromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à EMSIDrive'**
  String get biometricPromptTitle;

  /// No description provided for @biometricCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get biometricCancel;

  /// No description provided for @biometricPromptHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de votre identité'**
  String get biometricPromptHint;

  /// No description provided for @biometricCancelledHint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte non reconnue ? Réessayez ou utilisez votre mot de passe.'**
  String get biometricCancelledHint;

  /// No description provided for @biometricDisableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la connexion par empreinte ?'**
  String get biometricDisableTitle;

  /// No description provided for @biometricDisableBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez saisir votre email et votre mot de passe pour vous reconnecter. Vous pourrez la réactiver depuis le Profil.'**
  String get biometricDisableBody;

  /// No description provided for @biometricDisableConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get biometricDisableConfirm;

  /// No description provided for @biometricSwitchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer de compte ?'**
  String get biometricSwitchTitle;

  /// No description provided for @biometricSwitchBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone ne sera plus lié à {email}. La connexion par empreinte devra être réactivée.'**
  String biometricSwitchBody(String email);

  /// No description provided for @biometricOfferAccept.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get biometricOfferAccept;

  /// No description provided for @biometricOfferLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get biometricOfferLater;

  /// No description provided for @biometricEnabledMessage.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par empreinte activée.'**
  String get biometricEnabledMessage;

  /// No description provided for @pushSettingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications du téléphone'**
  String get pushSettingTitle;

  /// No description provided for @pushSettingEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer les notifications'**
  String get pushSettingEnable;

  /// No description provided for @pushSettingDescription.
  ///
  /// In fr, this message translates to:
  /// **'Recevez les acceptations, les messages et les changements de trajet même lorsque l’application est fermée.'**
  String get pushSettingDescription;

  /// No description provided for @pushSettingUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La configuration Firebase doit être ajoutée à cette version de l’application.'**
  String get pushSettingUnavailable;

  /// No description provided for @pushSettingDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez les notifications dans les paramètres Android, puis réessayez.'**
  String get pushSettingDenied;

  /// No description provided for @pushSettingError.
  ///
  /// In fr, this message translates to:
  /// **'Activation incomplète. Vérifiez votre connexion et réessayez.'**
  String get pushSettingError;

  /// No description provided for @pushForegroundNotice.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle activité sur votre trajet.'**
  String get pushForegroundNotice;

  /// No description provided for @pushOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get pushOpen;

  /// No description provided for @pushChatMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez reçu un nouveau message dans le chat du trajet.'**
  String get pushChatMessage;

  /// No description provided for @vehiclesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes véhicules'**
  String get vehiclesTitle;

  /// No description provided for @vehiclesDescription.
  ///
  /// In fr, this message translates to:
  /// **'Gérez les véhicules associés à votre compte conducteur.'**
  String get vehiclesDescription;

  /// No description provided for @vehiclesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’avez pas encore ajouté de véhicule.'**
  String get vehiclesEmpty;

  /// No description provided for @vehiclesAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get vehiclesAdd;

  /// No description provided for @vehiclesEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le véhicule'**
  String get vehiclesEdit;

  /// No description provided for @vehiclesDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le véhicule'**
  String get vehiclesDelete;

  /// No description provided for @vehiclesDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {name} de votre compte ?'**
  String vehiclesDeleteConfirm(String name);

  /// No description provided for @vehiclesCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get vehiclesCancel;

  /// No description provided for @vehiclesType.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule'**
  String get vehiclesType;

  /// No description provided for @vehiclesBrand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get vehiclesBrand;

  /// No description provided for @vehiclesModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get vehiclesModel;

  /// No description provided for @vehiclesColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur (facultative)'**
  String get vehiclesColor;

  /// No description provided for @vehiclesSeats.
  ///
  /// In fr, this message translates to:
  /// **'Places passagers'**
  String get vehiclesSeats;

  /// No description provided for @vehiclesSeatCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} place(s) passager(s)'**
  String vehiclesSeatCount(int count);

  /// No description provided for @vehiclesRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get vehiclesRequired;

  /// No description provided for @vehiclesSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le véhicule'**
  String get vehiclesSave;

  /// No description provided for @tripVehicleHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre véhicule pour que les passagers puissent le reconnaître.'**
  String get tripVehicleHint;

  /// No description provided for @tripVehicleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule de cette offre'**
  String get tripVehicleLabel;

  /// No description provided for @tripVehicleUnspecified.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule non renseigné'**
  String get tripVehicleUnspecified;

  /// No description provided for @tripRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'★ {rating}/5 · {count} avis'**
  String tripRatingLabel(String rating, int count);

  /// No description provided for @tripSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bilan du trajet'**
  String get tripSummaryTitle;

  /// No description provided for @tripSummaryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir le bilan et évaluer'**
  String get tripSummaryOpen;

  /// No description provided for @tripParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get tripParticipants;

  /// No description provided for @tripDriver.
  ///
  /// In fr, this message translates to:
  /// **'Conducteur'**
  String get tripDriver;

  /// No description provided for @tripDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée réelle · {minutes} min'**
  String tripDuration(int minutes);

  /// No description provided for @tripReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer {name}'**
  String tripReviewTitle(String name);

  /// No description provided for @tripReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Une seule évaluation définitive est autorisée par participant pour ce trajet.'**
  String get tripReviewHint;

  /// No description provided for @tripReviewStars.
  ///
  /// In fr, this message translates to:
  /// **'{score} étoiles'**
  String tripReviewStars(int score);

  /// No description provided for @tripReviewSaved.
  ///
  /// In fr, this message translates to:
  /// **'Votre évaluation a été enregistrée · {score}/5'**
  String tripReviewSaved(int score);

  /// No description provided for @tripReviewComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (facultatif)'**
  String get tripReviewComment;

  /// No description provided for @tripReviewSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon évaluation'**
  String get tripReviewSubmit;

  /// No description provided for @tripCostsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage des frais'**
  String get tripCostsTitle;

  /// No description provided for @tripCostsRule.
  ///
  /// In fr, this message translates to:
  /// **'Les frais en MAD sont répartis par place occupée, conducteur compris. Une réservation de plusieurs places prend en charge ces places. Les centimes restants sont répartis en commençant par le conducteur. Le montant est définitif après confirmation.'**
  String get tripCostsRule;

  /// No description provided for @tripCostsAmount.
  ///
  /// In fr, this message translates to:
  /// **'Frais totaux du trajet'**
  String get tripCostsAmount;

  /// No description provided for @tripCostsInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant de 0 à 99 999,99 MAD, avec deux décimales maximum.'**
  String get tripCostsInvalid;

  /// No description provided for @tripCostsPublish.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le partage'**
  String get tripCostsPublish;

  /// No description provided for @tripCostConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Publier définitivement ce montant et sa répartition entre les participants ?'**
  String get tripCostConfirm;

  /// No description provided for @tripCostsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total du trajet · {amount} MAD'**
  String tripCostsTotal(String amount);

  /// No description provided for @tripCostsWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Le conducteur pourra renseigner les frais de ce trajet.'**
  String get tripCostsWaiting;

  /// No description provided for @tripYourShare.
  ///
  /// In fr, this message translates to:
  /// **'Votre contribution'**
  String get tripYourShare;
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
