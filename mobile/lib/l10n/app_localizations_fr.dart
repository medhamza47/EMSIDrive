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
  String get homeSearchRideTitle => 'Trouver un trajet';

  @override
  String get homeSearchRideSubtitle =>
      'Consultez les offres pour rejoindre votre campus.';

  @override
  String get homeOfferRideTitle => 'Proposer un trajet';

  @override
  String get homeOfferRideSubtitle =>
      'Partagez votre trajet et vos places disponibles.';

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

  @override
  String get timetableImportHint =>
      'Importez un seul emploi du temps lisible, recadré sur votre groupe. JPEG, PNG ou PDF (3 pages maximum), jusqu’à 8 Mo.';

  @override
  String get timetableGroup => 'Classe / groupe';

  @override
  String get timetableGroupHint =>
      'Indiquez le groupe exact si le document en contient plusieurs.';

  @override
  String get timetableAiNotice =>
      'L’analyse transmet votre document à Groq. Vérifiez les cours extraits avant de les enregistrer. Le serveur ne conserve pas votre photo.';

  @override
  String get timetableManual => 'Saisir mes cours manuellement';

  @override
  String get timetableEdit => 'Modifier mon emploi du temps';

  @override
  String get timetableDelete => 'Supprimer mon emploi du temps';

  @override
  String get timetableDeleteConfirm =>
      'Supprimer les cours enregistrés et désactiver leurs suggestions ?';

  @override
  String get timetableCancel => 'Annuler';

  @override
  String get timetableReload => 'Actualiser';

  @override
  String get timetableReview =>
      'Comparez chaque cours au document original. Corrigez les champs incertains et indiquez la période pendant laquelle ce planning hebdomadaire s’applique.';

  @override
  String get timetableOriginal => 'Voir la photo originale';

  @override
  String get timetableName => 'Nom de l’emploi du temps';

  @override
  String get timetableFrom => 'Valable à partir du';

  @override
  String get timetableUntil => 'Valable jusqu’au';

  @override
  String get timetableUnknown => 'À renseigner';

  @override
  String get timetableNeedsReview =>
      'À vérifier : touchez ce cours pour le corriger et le valider.';

  @override
  String get timetableRemoveCourse => 'Supprimer ce cours';

  @override
  String get timetableAddCourse => 'Ajouter un cours';

  @override
  String get timetableOverlap =>
      'Des cours se chevauchent le même jour. Corrigez les horaires.';

  @override
  String get timetableIncomplete =>
      'Renseignez le nom, des dates ordonnées (un an maximum) et tous les cours : jour, campus, heures de début et de fin. Validez chaque cours incertain.';

  @override
  String get timetableConfirm =>
      'J’ai vérifié les cours, les horaires, les campus et les dates.';

  @override
  String get timetableSave => 'Enregistrer mon emploi du temps';

  @override
  String get timetableThursday => 'Jeudi';

  @override
  String get timetableFriday => 'Vendredi';

  @override
  String get timetableSaturday => 'Samedi';

  @override
  String get timetableSunday => 'Dimanche';

  @override
  String get timetableCourse => 'Corriger un cours';

  @override
  String get timetableSubject => 'Matière';

  @override
  String get timetableDay => 'Jour';

  @override
  String get timetableStart => 'Début (HH:mm)';

  @override
  String get timetableEnd => 'Fin (HH:mm)';

  @override
  String get timetableCampus => 'Campus';

  @override
  String get timetableRoom => 'Salle / lieu (facultatif)';

  @override
  String get timetableRequired => 'Champ obligatoire';

  @override
  String get timetableTimeInvalid =>
      'Utilisez HH:mm et une fin après le début.';

  @override
  String get timetableValidateCourse => 'Valider ce cours';

  @override
  String get timetableMatchingHint =>
      'Offres publiées pour les 7 prochains jours, selon votre premier et dernier cours et leur campus. Pour l’aller : durée estimée + 10 min de marge, avec jusqu’à 60 min d’avance. Pour le retour : départ dans l’heure après le dernier cours. Vérifiez le point de rendez-vous et le trajet avant de réserver.';

  @override
  String timetableCommute(int minutes) {
    return 'Durée estimée de votre trajet : $minutes min';
  }

  @override
  String get timetableNoMatches =>
      'Aucune offre disponible ne correspond actuellement à vos horaires et à votre campus. Réessayez quand de nouveaux trajets seront publiés.';

  @override
  String get timetableBeforeCourse => 'Début du premier cours :';

  @override
  String get timetableAfterCourse => 'Fin du dernier cours :';

  @override
  String get timetableFileSize =>
      'Le fichier doit contenir entre 1 octet et 8 Mo.';

  @override
  String get timetablePdfPages => 'Choisissez un PDF de 1 à 3 pages.';

  @override
  String get timetableFileError =>
      'Document illisible ou format non pris en charge. Choisissez une image JPEG/PNG ou un PDF non protégé.';

  @override
  String get timetableSignIn =>
      'Reconnectez-vous pour accéder à votre emploi du temps.';

  @override
  String get timetableNetworkError =>
      'Connexion impossible ou délai dépassé. Vérifiez votre connexion puis réessayez.';

  @override
  String get timetableAmbiguous =>
      'Plusieurs groupes ou tableaux sont visibles. Recadrez votre emploi du temps ou précisez le groupe exact.';

  @override
  String get timetableNotDetected =>
      'Aucun emploi du temps exploitable détecté. Choisissez une image plus nette et bien cadrée.';

  @override
  String get timetableRateLimit =>
      'Trop d’analyses ou service occupé. Patientez avant de réessayer ; vous pouvez aussi saisir vos cours manuellement.';

  @override
  String get timetableAiError =>
      'L’analyse IA est momentanément indisponible. Réessayez ou saisissez vos cours manuellement.';

  @override
  String get timetableChanged =>
      'Votre emploi du temps a changé depuis son ouverture. Revenez à l’import, actualisez puis ouvrez la dernière version.';

  @override
  String get timetableNotSaved =>
      'Enregistrez et confirmez d’abord votre emploi du temps.';

  @override
  String get timetableGenericError =>
      'L’opération a échoué. Réessayez ; votre emploi du temps enregistré reste disponible.';

  @override
  String get navPlanning => 'Planning';

  @override
  String get profileEdit => 'Modifier mes informations';

  @override
  String get profileEditHint =>
      'Retrouvez vos informations à chaque connexion. Les champs facultatifs peuvent être complétés plus tard.';

  @override
  String get profilePersonal => 'Informations personnelles';

  @override
  String get profileStudies => 'Mes études';

  @override
  String get profilePreferences => 'Préférences de trajet';

  @override
  String get profilePreferencesHint =>
      'Ces choix seront proposés dans vos prochains formulaires.';

  @override
  String get profileCampus => 'Campus habituel';

  @override
  String get profileNoPreference => 'Aucune préférence';

  @override
  String get profileMajor => 'Filière / groupe';

  @override
  String get profileMajorHint => 'Ex. : 5IIR · 2DSI';

  @override
  String get profileYear => 'Année universitaire';

  @override
  String get profileYearHint => 'Ex. : 2026-2027';

  @override
  String get profileNotSet => 'Non renseigné';

  @override
  String get profileEmailFixed => 'Cet email identifie votre compte.';

  @override
  String get profileNameRequired => 'Renseignez votre nom complet.';

  @override
  String get profilePhoneInvalid =>
      'Numéro invalide : 9 à 20 chiffres, avec éventuellement un + au début (20 caractères maximum).';

  @override
  String get profileSave => 'Enregistrer les modifications';

  @override
  String get profileSaved => 'Vos informations sont enregistrées.';

  @override
  String get profileSignIn => 'Connectez-vous pour retrouver votre profil.';

  @override
  String get profileOperationError =>
      'Impossible de charger ou d’enregistrer vos informations. Réessayez.';

  @override
  String get planningIntro =>
      'Vos cours et vos trajets, organisés par journée.';

  @override
  String get planningEmptyTitle => 'Votre semaine commence ici';

  @override
  String get planningEmptyHint =>
      'Importez votre emploi du temps ou saisissez vos cours pour trouver des trajets adaptés à vos horaires.';

  @override
  String get planningImport => 'Ajouter mon emploi du temps';

  @override
  String get planningManage => 'Gérer mon emploi du temps';

  @override
  String get planningFreeDay => 'Aucun cours enregistré pour cette journée.';

  @override
  String get homeActionsTitle => 'Comment voyagez-vous ?';

  @override
  String get ridesIntro =>
      'Trouvez une place, proposez la vôtre et retrouvez vos réservations.';

  @override
  String get ridesTools => 'Autres outils';

  @override
  String get rideFormRoute => 'Votre itinéraire';

  @override
  String get rideFormRouteHint =>
      'Choisissez le campus et votre point de rendez-vous.';

  @override
  String get rideFormDeparture => 'Date et heure';

  @override
  String get rideFormDetails => 'Places et préférences';

  @override
  String get rideFormSummary => 'Votre trajet en un coup d’œil';

  @override
  String get ridePointReady => 'Point de rendez-vous sélectionné';

  @override
  String get mapSelectionTitle => 'Votre point de rendez-vous';

  @override
  String get mapSelectionHint =>
      'Touchez un lieu sur la carte ou utilisez votre position.';

  @override
  String get mapSelectedHint =>
      'Vous pouvez déplacer le repère en touchant un autre lieu.';

  @override
  String get mapCampusSummary => 'Campus du trajet';

  @override
  String get mapCoordinatesDetails => 'Voir les coordonnées';

  @override
  String get mapRouteLabel => 'Aperçu de l’itinéraire';
}
