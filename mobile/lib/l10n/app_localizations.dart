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

  /// No description provided for @demoPhotoName.
  ///
  /// In fr, this message translates to:
  /// **'emploi_du_temps_2DSI.jpg'**
  String get demoPhotoName;

  /// No description provided for @demoPdfName.
  ///
  /// In fr, this message translates to:
  /// **'emploi_du_temps_2DSI.pdf'**
  String get demoPdfName;

  /// No description provided for @demoFileReady.
  ///
  /// In fr, this message translates to:
  /// **'Fichier de démonstration · prêt à analyser'**
  String get demoFileReady;

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

  /// No description provided for @demoMondayHours.
  ///
  /// In fr, this message translates to:
  /// **'08:30 – 12:30'**
  String get demoMondayHours;

  /// No description provided for @demoTuesdayHours.
  ///
  /// In fr, this message translates to:
  /// **'08:30 – 10:30'**
  String get demoTuesdayHours;

  /// No description provided for @demoWednesdayHours.
  ///
  /// In fr, this message translates to:
  /// **'16:00 – 18:30'**
  String get demoWednesdayHours;

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

  /// No description provided for @campusTargaProvisionalAddress.
  ///
  /// In fr, this message translates to:
  /// **'Repère provisoire à Guéliz · adresse Targa à confirmer'**
  String get campusTargaProvisionalAddress;

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
