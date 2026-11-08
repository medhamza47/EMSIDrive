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

  @override
  String get requestTitle => 'Nouvelle demande';

  @override
  String get offerTitle => 'Proposer un trajet';

  @override
  String get vehicleMotorcycle => 'Moto';

  @override
  String get vehicleCar => 'Voiture';

  @override
  String get vehicleAny => 'Peu importe';

  @override
  String get flowRequired => 'Renseignez ce champ.';

  @override
  String get demoOrigin => 'Guéliz, Marrakech';

  @override
  String get demoDistrict => 'Guéliz';

  @override
  String get demoCampus => 'EMSI Marrakech';

  @override
  String get tripOrigin => 'Départ';

  @override
  String get tripDestination => 'Destination';

  @override
  String get vehiclePreference => 'Véhicule souhaité';

  @override
  String get seatCount => 'Nombre de places';

  @override
  String get removeSeat => 'Retirer une place';

  @override
  String get addSeat => 'Ajouter une place';

  @override
  String get optionalMessage => 'Message (facultatif)';

  @override
  String get demoRideMessage => 'Je peux aussi partir à 08:30.';

  @override
  String get publishOffer => 'Publier le trajet';

  @override
  String get publishRequest => 'Publier la demande';

  @override
  String get demoOfferSaved => 'Trajet proposé dans la démonstration.';

  @override
  String get nearbyTitle => 'Conducteurs proches';

  @override
  String get nearestSort => 'Plus proches';

  @override
  String get ratingSort => 'Mieux notés';

  @override
  String get driverTitle => 'Conducteur';

  @override
  String get averageRating => 'Note moyenne';

  @override
  String get vehicleLabel => 'Véhicule';

  @override
  String get offeredTrip => 'Trajet proposé';

  @override
  String get demoDay => 'Lundi 2 nov.';

  @override
  String get remainingSeats => 'Places restantes';

  @override
  String get fuelContribution => 'Part des frais d’essence';

  @override
  String get sendRequest => 'Envoyer une demande';

  @override
  String get trackingTitle => 'Suivi du trajet';

  @override
  String get arrivalDistance => 'À 1,2 km de votre point de départ.';

  @override
  String get onTheWay => 'En route';

  @override
  String get messageDriver => 'Message';

  @override
  String get callDriver => 'Appeler';

  @override
  String get cancelRideRequest => 'Annuler la demande';

  @override
  String get demoOnlyAction => 'Action indisponible dans la démonstration.';

  @override
  String get fuelTitle => 'Frais d’essence';

  @override
  String get fuelSummary => 'Total 40 MAD, partagé entre 4 personnes';

  @override
  String get yourShare => 'Votre part';

  @override
  String get costBreakdown => 'Répartition';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get passengers => 'Passagers';

  @override
  String get sharePerPerson => 'Part de chacun';

  @override
  String get participants => 'Participants';

  @override
  String get youLabel => 'Vous';

  @override
  String get confirmShare => 'Confirmer ma part';

  @override
  String get reviewTitle => 'Évaluer le trajet';

  @override
  String get reviewPrompt => 'Comment était le trajet avec Salma ?';

  @override
  String get demoRoute => 'Guéliz vers EMSI Marrakech';

  @override
  String get reviewHighlights => 'Ce qui vous a plu';

  @override
  String get reviewPunctual => 'Ponctuelle';

  @override
  String get reviewSafe => 'Conduite sûre';

  @override
  String get reviewFriendly => 'Sympathique';

  @override
  String get reviewClean => 'Véhicule propre';

  @override
  String get reviewComment => 'Commentaire (facultatif)';

  @override
  String get demoReviewComment =>
      'Trajet agréable, arrivée à l’heure avant le cours.';

  @override
  String get submitReview => 'Envoyer l’évaluation';

  @override
  String get demoReviewSaved => 'Évaluation envoyée dans la démonstration.';

  @override
  String get scheduleTitle => 'Mon emploi du temps';

  @override
  String get scheduleImportTitle => 'Importez votre emploi du temps';

  @override
  String get scheduleFormats => 'Photo, capture d’écran ou PDF';

  @override
  String get chooseFile => 'Choisir un fichier';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get removeFile => 'Retirer';

  @override
  String get demoPhotoName => 'emploi_du_temps_2DSI.jpg';

  @override
  String get demoPdfName => 'emploi_du_temps_2DSI.pdf';

  @override
  String get demoFileReady => 'Fichier de démonstration · prêt à analyser';

  @override
  String get scheduleAssistant =>
      'L’assistant repère vos heures d’arrivée et de départ et cherche les conducteurs aux mêmes horaires. Cet aperçu utilise un emploi du temps de démonstration.';

  @override
  String get analyzeSchedule => 'Analyser mon emploi du temps';

  @override
  String get slotsTitle => 'Vérifier mes créneaux';

  @override
  String get reviewSlotsHint =>
      'Corrigez si besoin avant de lancer la recherche.';

  @override
  String get mondayShort => 'Lun';

  @override
  String get tuesdayShort => 'Mar';

  @override
  String get wednesdayShort => 'Mer';

  @override
  String get thursdayShort => 'Jeu';

  @override
  String get fridayShort => 'Ven';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get demoMondayHours => '08:30 – 12:30';

  @override
  String get demoTuesdayHours => '08:30 – 10:30';

  @override
  String get demoWednesdayHours => '16:00 – 18:30';

  @override
  String get morningTrip => 'Trajet du matin';

  @override
  String get eveningTrip => 'Trajet du soir';

  @override
  String get searchSharedTrips => 'Chercher des trajets partagés';

  @override
  String get aiLabel => 'IA';

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String get suggestionsIntro =>
      '4 conducteurs ont des horaires proches des vôtres. Triés par compatibilité.';

  @override
  String get mondayMorning => 'Lun matin';

  @override
  String get tuesdayMorning => 'Mar matin';

  @override
  String get thursdayMorning => 'Jeu matin';

  @override
  String get wednesdayEvening => 'Mer soir';

  @override
  String get fridayEvening => 'Ven soir';

  @override
  String get proposeAction => 'Proposer';

  @override
  String get compatibilityTitle => 'Compatibilité';

  @override
  String get yourClasses => 'Vos cours';

  @override
  String get driverClasses => 'Ses cours';

  @override
  String get sharedClasses => 'En commun';

  @override
  String get matchEveningTime => 'Retour 18:30';

  @override
  String get matchRoundTrip => 'Aller 08:15 – retour 12:30';

  @override
  String get fuelPerTrip => 'Part d’essence par trajet';

  @override
  String get proposeCarpool => 'Proposer le covoiturage';

  @override
  String get ignoreSuggestion => 'Ignorer';

  @override
  String get demoProposalSaved => 'Proposition envoyée dans la démonstration.';

  @override
  String get proposalNotification => 'Omar K. vous propose de covoiturer';

  @override
  String get proposalNotificationBody =>
      '4 créneaux en commun : lundi, mardi et jeudi matin. Compatibilité 85 %.';

  @override
  String get acceptedNotification => 'Salma B. a accepté votre proposition';

  @override
  String get acceptedNotificationBody =>
      'Premier trajet lundi à 08:15, départ Guéliz.';

  @override
  String get matchNotification => 'Nouveau conducteur compatible';

  @override
  String get matchNotificationBody =>
      'Imane R. a un trajet mercredi soir qui correspond à votre emploi du temps.';

  @override
  String get reminderNotification => 'Rappel de trajet';

  @override
  String get reminderNotificationBody =>
      'Demain 08:15 avec Salma B. Pensez à confirmer votre part d’essence.';

  @override
  String get acceptProposal => 'Accepter';

  @override
  String get declineProposal => 'Refuser';

  @override
  String get proposalAccepted => 'Proposition acceptée';

  @override
  String get proposalDeclined => 'Proposition refusée';

  @override
  String get signOutLabel => 'Se déconnecter';

  @override
  String get signOutError => 'La déconnexion a échoué. Réessayez.';

  @override
  String get rideRequests => 'Demandes';

  @override
  String get rideOffers => 'Offres';

  @override
  String get myAcceptedRides => 'Mes trajets';

  @override
  String get refreshListings => 'Actualiser';

  @override
  String get marketplaceLoadError =>
      'Connexion au service indisponible. Réessayez.';

  @override
  String get noRideRequests => 'Aucune demande à venir.';

  @override
  String get noRideOffers => 'Aucune offre à venir.';

  @override
  String get noAcceptedRides => 'Aucun trajet accepté.';

  @override
  String get rideRequestDetail => 'Demande de trajet';

  @override
  String get rideOfferDetail => 'Offre de trajet';

  @override
  String get approximatePickup =>
      'Le point en ville est approximatif avant l’acceptation.';

  @override
  String get acceptRide => 'Accepter le trajet';

  @override
  String get acceptRideError =>
      'Impossible d’accepter ce trajet. Vérifiez sa disponibilité.';

  @override
  String get ownRideListing => 'Vous avez publié cette annonce.';

  @override
  String get rideUnavailable => 'Ce trajet n’est plus disponible.';

  @override
  String get acceptedRideTitle => 'Trajet accepté';

  @override
  String get rideChat => 'Chat';

  @override
  String get driverLocation => 'Position du conducteur';

  @override
  String get sendChatError => 'Le message n’a pas pu être envoyé.';

  @override
  String get liveSharingError =>
      'Le partage de position a rencontré un problème.';

  @override
  String get youDrive => 'Vous conduisez';

  @override
  String get youRide => 'Vous êtes passager';

  @override
  String get locationSharingHint =>
      'Votre passager voit votre position pendant que cet écran reste ouvert et que le partage est actif.';

  @override
  String get startLiveSharing => 'Partager ma position';

  @override
  String get stopLiveSharing => 'Arrêter le partage';

  @override
  String get noLiveLocation =>
      'Le conducteur ne partage pas sa position actuellement.';

  @override
  String get noChatMessages => 'Aucun message pour le moment.';

  @override
  String get writeChatMessage => 'Écrire un message';

  @override
  String get sendChatMessage => 'Envoyer le message';

  @override
  String get noRideNotices => 'Aucune notification de trajet.';

  @override
  String get openAcceptedRide => 'Ouvrir le trajet et le chat';

  @override
  String get departureMustBeFuture =>
      'Choisissez une date et une heure de départ à venir.';

  @override
  String get publishRideError => 'Impossible de publier le trajet. Réessayez.';

  @override
  String requestAcceptedNotice(String name) {
    return '$name a accepté votre demande';
  }

  @override
  String offerAcceptedNotice(String name) {
    return '$name a accepté votre offre';
  }

  @override
  String get campusTarga => 'EMSI Marrakech Targa';

  @override
  String get campusCentre => 'EMSI Marrakech Centre';

  @override
  String get campusCentreAddress => 'Lot Bouizgaren, route de Safi';

  @override
  String get campusDirectionHint =>
      'Choisissez le sens du trajet et un campus EMSI.';

  @override
  String get towardCampus => 'Vers l’EMSI';

  @override
  String get fromCampus => 'Depuis l’EMSI';

  @override
  String get chooseMapPoint => 'Choisir un point sur la carte';

  @override
  String get changeMapPoint => 'Modifier le point ou voir l’itinéraire';

  @override
  String get marrakechMapTitle => 'Carte de Marrakech';

  @override
  String get mapUnavailable => 'La carte de Marrakech est indisponible.';

  @override
  String get pickPointHint =>
      'Touchez la carte pour placer le repère à Marrakech.';

  @override
  String get pointOutsideMarrakech =>
      'Choisissez un point à l’intérieur de Marrakech.';

  @override
  String get locationDisabled =>
      'Activez la localisation ou choisissez un point sur la carte.';

  @override
  String get locationDenied =>
      'Autorisez la localisation dans les réglages ou choisissez un point sur la carte.';

  @override
  String get locationUnavailable =>
      'Position introuvable. Choisissez un point sur la carte.';

  @override
  String get locatingPosition => 'Recherche de la position…';

  @override
  String get useMyLocation => 'Ma position';

  @override
  String get previewRoadRoute => 'Voir l’itinéraire';

  @override
  String get calculatingRoute => 'Calcul en cours…';

  @override
  String get roadRouteError =>
      'Impossible de calculer l’itinéraire. Vous pouvez réessayer.';

  @override
  String get routingPrivacyHint =>
      'Le calcul d’itinéraire envoie les deux points à OSRM.';

  @override
  String get roadRouteSource => 'Itinéraire routier estimé · OSRM';

  @override
  String get confirmMapPoint => 'Confirmer ce point';

  @override
  String chosenCoordinates(String latitude, String longitude) {
    return 'Point choisi : $latitude, $longitude';
  }

  @override
  String roadRouteSummary(String distance, int minutes) {
    return '$distance km · environ $minutes min';
  }

  @override
  String seatsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String nearbyDriverSummary(String major, String distance, String time) {
    return '$major · $distance km · $time';
  }

  @override
  String driverAcademicSummary(String major) {
    return '$major · EMSI Marrakech';
  }

  @override
  String amountMad(int amount) {
    return '$amount MAD';
  }

  @override
  String arrivalEstimate(String name) {
    return '$name arrive dans 4 min';
  }

  @override
  String ratingOutOfFive(int value) {
    return '$value sur 5';
  }

  @override
  String detectedSlots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cours détectés cette semaine',
      one: '1 cours détecté cette semaine',
    );
    return '$_temp0';
  }

  @override
  String commonSlots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count créneaux en commun',
      one: '1 créneau en commun',
    );
    return '$_temp0';
  }

  @override
  String suggestionDriverSummary(String major, String distance) {
    return '$major · $distance km de chez vous';
  }

  @override
  String matchMorningTime(String time) {
    return 'Aller $time';
  }
}
