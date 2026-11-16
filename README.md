# EMSIDrive

Windows + Android team presentation: [ready-to-run package and source setup](presentation/TEAM-SETUP.md).

Application de covoiturage pour les étudiants de l’EMSI Marrakech. Chaque trajet relie
l’un des deux campus à un point situé dans Marrakech ou Méchouar-Kasba.

## État du projet

| Partie | Disponible |
| --- | --- |
| Comptes | Inscription avec un domaine étudiant autorisé, connexion, stockage sécurisé des jetons et déconnexion révoquée côté serveur. Après une première connexion par mot de passe, le téléphone peut être lié pour se reconnecter **par empreinte**. L’API renouvelle les jetons et permet de consulter ou modifier son profil et de gérer ses véhicules. |
| Mobile | Interface Flutter avec les onglets **Accueil**, **Trajets**, **Planning** et **Profil**. Les notifications restent accessibles par la cloche. L’accueil conserve les deux actions **Trouver un trajet** et **Proposer un trajet**. |
| Profil | Consultation et modification du nom, téléphone, filière, année universitaire et préférences de campus/véhicule. Les données sont enregistrées par compte dans PostgreSQL et rechargées à la connexion. |
| Planning et Gemini | Import JPEG/PNG/PDF en arrière-plan avec modèles de secours, reprise depuis Planning ou Profil, puis validation des horaires de présence. Recherche d’offres réservables selon le campus, les horaires et la proximité du point choisi. Aucun OCR local à installer. |
| Carte de Marrakech | Choix du sens **Vers l’EMSI** ou **Depuis l’EMSI**, puis du campus **Targa** ou **Centre**. Pour l’autre extrémité, l’étudiant place un repère sur la carte ou utilise **Ma position**. L’aperçu routier affiche le tracé, la distance et la durée estimée. |
| Annonces | **Trajets** sépare les **Demandes**, les **Offres** et **Mes trajets**. La publication et l’acceptation passent par l’API. La fiche d’une annonce affiche le tracé avant l’acceptation. |
| Acceptation | L’API réserve la place et crée, dans la même transaction, une notification pour l’auteur de l’annonce. Les deux participants retrouvent le trajet dans **Mes trajets** et peuvent s’écrire dans un chat privé. |
| Suivi | Depuis un trajet accepté, le conducteur peut activer **Partager ma position**. Le passager voit le repère s’actualiser sur sa carte toutes les quelques secondes. |

Le point en ville est arrondi dans l’annonce publique. Les coordonnées exactes, le chat
et la position du conducteur sont accessibles aux participants via le trajet accepté.
Le partage s’arrête lorsque le conducteur quitte le trajet ou met l’application en
arrière-plan. Le serveur masque une position datant de plus de 30 secondes. Les
notifications d’acceptation apparaissent dans l’application, avec un indicateur de non-lu.

L’accueil affiche le nom du compte et ses prochains trajets confirmés depuis l’API.
Certains anciens écrans issus des maquettes, le partage des frais et les évaluations
utilisent encore des interactions simulées. L’API de gestion des véhicules existe.
Les notifications système et le back-office restent à réaliser.

## Modifications intégrées le 8 novembre 2026

Cette section décrit la version historique avec Groq. Le parcours actuel utilise Gemini
décrit dans « Analyser un emploi du temps » et dans `backend/SCHEDULE.md`.

Cette mise à jour regroupe le travail sur l’analyse des emplois du temps, la refonte
mobile et la conservation des données de chaque utilisateur.

| Évolution | Résultat dans le projet |
| --- | --- |
| Analyse IA côté backend | Le document est envoyé à l’API authentifiée, contrôlé puis analysé avec Groq. La clé reste côté serveur dans l’environnement ou dans `backend/.env.local`. |
| Suppression des données fictives du planning | Les fichiers, cours et suggestions de démonstration du parcours d’emploi du temps sont remplacés par un import réel et des données enregistrées. |
| Séances doubles | Détection des bordures de grille et des cellules fusionnées sur les photos exploitables. La fin du cours correspond à la dernière colonne couverte, avec priorité aux horaires écrits dans la case. |
| Préservation des traits fins | Les photos sont normalisées en PNG pour éviter qu’une seconde compression JPEG efface les séparations entre les séances. |
| Contrôle de la réponse IA | Les cellules sont identifiées côté serveur. Les identifiants manquants ou inventés, les clés JSON dupliquées, les réponses tronquées et les en-têtes incohérents sont refusés. |
| Enregistrement du planning | Vérification des champs incertains, dates de validité, campus par cours, confirmation obligatoire et contrôle des chevauchements. Une révision empêche d’écraser une version modifiée entre-temps. |
| Suggestions de trajets | Utilisation des offres réellement disponibles des sept prochains jours, du campus et du premier/dernier cours de la journée. Aucun score ou conducteur fictif n’est ajouté. |
| Refonte visuelle | Fonds neutres, cartes blanches en thème clair, accents verts EMSI, formulaires organisés par sections et navigation **Accueil / Trajets / Planning / Profil**. |
| Deux parcours de trajet | **Trouver un trajet** ouvre les offres ; **Proposer un trajet** ouvre le formulaire de publication. Les demandes et les réservations restent accessibles dans Trajets. |
| Profil persistant | Lecture et modification du vrai profil via `/api/v1/me`, avec stockage du nom, téléphone, filière, année et préférences de trajet dans PostgreSQL. |
| Isolation des comptes | Les données affichées sont réinitialisées au changement de compte. Une réponse tardive de l’ancien compte ne doit pas remplacer le profil ou l’accueil du nouveau compte. |
| Préférences réutilisées | Le campus et le véhicule habituels préremplissent les formulaires sans écraser les choix déjà modifiés par l’utilisateur. |
| Carte et formulaires | Sections itinéraire, date/heure et places/préférences ; récapitulatif avant publication ; confirmation du point sur la carte toujours accessible en bas. |
| Authentification partagée | Les appels du planning, du profil et de la marketplace partagent le renouvellement des jetons. Un envoi multipart peut être réessayé après un renouvellement sans réutiliser un formulaire déjà consommé. |

### Correction des séances de trois heures

L’analyse ne suppose plus qu’un cours dure systématiquement 1 h 30. Pour une grille
détectable, le serveur mesure les cellules physiques, les découpe en vues agrandies
et demande à Groq d’en transcrire le contenu. Les horaires sont ensuite associés aux
colonnes couvertes par la cellule mesurée.

Sur la photo utilisée pour reproduire le problème, les contrôles ont notamment vérifié :

| Cours | Jour | Horaire attendu |
| --- | --- | --- |
| Deep Learning | Lundi | 08:30–11:45 |
| JEE et architecture microservices | Samedi | 08:30–11:45 |
| ERP | Vendredi | 08:30–10:00 |
| Développement multi-plateforme | Samedi | 12:00–13:30 |

Deux séances de 1 h 30 séparées par une pause de 15 minutes occupent donc l’intervalle
complet **08:30–11:45**. Un cours voisin d’une case vide n’est pas automatiquement
prolongé. Les horaires explicitement imprimés dans une case restent prioritaires.
Les champs peu lisibles restent à corriger avant confirmation ; les documents sans
grille exploitable utilisent une lecture globale avec vérification des incertitudes.

Le fonctionnement détaillé, les limites et le contrat API sont documentés dans
[`backend/SCHEDULE.md`](./backend/SCHEDULE.md).

### Migrations ajoutées

| Migration | Rôle |
| --- | --- |
| [`V21__schedule_validity_and_campus.sql`](./backend/src/main/resources/db/migration/V21__schedule_validity_and_campus.sql) | Dates de validité, révision du planning, campus par cours et unicité du planning actif par compte. Les anciens imports non confirmés sont désactivés et doivent être confirmés dans le nouveau parcours. |
| [`V22__profile_travel_preferences.sql`](./backend/src/main/resources/db/migration/V22__profile_travel_preferences.sql) | Préférences de campus et de véhicule, avec contraintes sur les valeurs autorisées. |
| [`V25__marketplace_ride_lifecycle.sql`](./backend/src/main/resources/db/migration/V25__marketplace_ride_lifecycle.sql) | Horodatages des trajets et historique des réservations annulées, avec unicité limitée aux réservations actives. |
| [`V26__create_biometric_devices_table.sql`](./backend/src/main/resources/db/migration/V26__create_biometric_devices_table.sql) | Téléphones liés pour la connexion par empreinte : seul le hash SHA-256 de la clé d’appareil est stocké, avec date de dernière utilisation et de révocation. |

Flyway applique ces migrations au démarrage du backend.
Les migrations locales V23 (imports de planning) et V24 (suivi GPS) sont conservées.
Les ajouts de l’équipe utilisent V25 (cycle de vie) et V26 (empreinte) pour éviter
les numéros en double. Une base créée avec les anciennes V23/V24 de l’équipe
nécessite une réconciliation de son historique Flyway avant de démarrer cette
version ; ne pas supprimer ses données.

## Lancer le projet

Prévoir un JDK 17 ou supérieur, Maven 3.9+, Docker, Flutter avec une version de Dart
compatible avec [pubspec.yaml](./mobile/pubspec.yaml), et un téléphone Android ou un émulateur.

Pour une copie clonée du dépôt, les commandes suivantes permettent de récupérer la
branche [`develop`](https://github.com/medhamza47/EMSIDrive/tree/develop).

```bash
git fetch origin
git switch develop
git pull --ff-only origin develop
```

Depuis `backend/`, démarrer PostgreSQL 16 et l’API. Flyway applique les migrations au
démarrage, dont V20 pour les annonces et le chat, V21 pour les emplois du temps confirmés
et V22 pour les préférences de trajet du profil.

```bash
docker compose up -d
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

PostgreSQL écoute sur le port 5433 de la machine et l’API sur le port 8080.
[`/health`](http://localhost:8080/health) permet de vérifier l’API et
[Swagger](http://localhost:8080/swagger-ui.html) présente les routes. Sous Windows,
[`scripts/start-backend.ps1`](./scripts/start-backend.ps1) peut démarrer les deux services
avec le JDK Android Studio et Maven.

Lancer Flutter depuis `mobile/` une fois l’émulateur démarré.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Sur un téléphone physique, utiliser l’adresse de la machine sur le réseau local, ou suivre
les exemples de [`mobile/.env.example`](./mobile/.env.example). L’URL est intégrée lors de
la compilation. La carte et l’aperçu routier utilisent OpenStreetMap et OSRM en
développement. Leur configuration est décrite dans le [guide mobile](./mobile/README.md#marrakech-ride-map).

### Téléphone Android physique en USB

Activer les options développeur et le débogage USB, brancher le téléphone puis accepter
l’autorisation de débogage affichée sur celui-ci. Aucun émulateur n’est nécessaire.
Le backend doit être démarré sur l’ordinateur avant l’utilisation de l’application.

Depuis la racine du projet :

```powershell
adb devices
adb -s IDENTIFIANT_TELEPHONE reverse tcp:8080 tcp:8080
cd mobile
flutter devices
flutter run -d IDENTIFIANT_TELEPHONE --dart-define=API_BASE_URL=http://localhost:8080
```

Remplacer `IDENTIFIANT_TELEPHONE` par l’identifiant affiché par `adb devices` ou
`flutter devices`, et non par le nom commercial du téléphone. Le transfert `adb reverse`
fait correspondre le port 8080 du téléphone à celui du backend sur l’ordinateur.
Le relancer après une déconnexion USB si la connexion à l’API ne fonctionne plus.

Sous Windows, si les outils ne sont pas dans le `PATH`, l’environnement utilisé pour
la validation dispose de Flutter dans `C:\src\flutter` :

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
& 'C:\src\flutter\bin\flutter.bat' devices
```

La validation a utilisé Flutter **3.47.8**, Dart **3.13.7** et le JDK fourni avec Android
Studio. Choisir un SDK compatible avec les contraintes du projet si plusieurs versions
de Flutter sont installées.

Pour produire un APK depuis `mobile/` avec la connexion USB au backend :

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://localhost:8080
```

Le fichier est généré dans `mobile/build/app/outputs/flutter-apk/app-debug.apk` depuis
la racine du dépôt. Une mise à jour avec le même identifiant d’application et la même
signature conserve les données locales de l’application.

### Connexion persistante

Au démarrage, l’app vérifie les jetons conservés dans le stockage sécurisé en
appelant `/api/v1/me`. Une session valide ouvre directement l’accueil. Un jeton
d’accès expiré est renouvelé via `/api/v1/auth/refresh`, avec la même logique de
renouvellement utilisée par le planning, le profil et les trajets. Les données
enregistrées par les versions précédentes restent compatibles.

Une réponse refusant définitivement les jetons efface la session et ramène à la
connexion. Une panne réseau ou une erreur serveur temporaire conserve les jetons
et affiche un écran de reprise avec **Réessayer** et **Utiliser un autre compte**.
Les écrans privés sont protégés pendant la vérification et après déconnexion.
Une destination privée demandée pendant la vérification est reprise si la session
est valide. Se déconnecter révoque le refresh token sur le serveur
(`POST /api/v1/auth/logout`), puis efface les deux jetons avant le retour à la
connexion. Hors ligne, la déconnexion locale a lieu quand même.

Le mot de passe n’est pas conservé. Le renouvellement des jetons ne change pas
l’identité du compte et les réponses tardives d’un ancien compte sont ignorées.
Les tests couvrent le redémarrage, les jetons expirés, le renouvellement partagé,
la reprise réseau, les routes privées et les changements de compte concurrents.
La suite mobile complète passe avec 183 tests. La restauration a également été
vérifiée sur le Pixel 5 après fermeture complète et relance de l’application.

### Connexion par empreinte

Après une connexion par mot de passe, l’app propose **Activer l’empreinte ?**. On
peut aussi l’activer ou la désactiver dans **Profil → Sécurité**. L’activation
demande une empreinte, puis le serveur lie le téléphone et lui remet une clé
d’appareil aléatoire, conservée dans le stockage sécurisé.

| Situation | Écran |
| --- | --- |
| Session encore ouverte | L’accueil s’ouvre directement, sans empreinte. |
| Après **Se déconnecter**, téléphone lié | **Bon retour, Prénom** avec **Se connecter avec l’empreinte**, **Utiliser le mot de passe** et **Changer de compte**. |
| Lancement de l’app déconnectée, téléphone lié | Même écran ; la demande d’empreinte s’ouvre d’elle-même. |
| Téléphone non lié | Formulaire email et mot de passe habituel. |

L’empreinte est vérifiée par le téléphone uniquement : elle n’est jamais envoyée au
serveur et le mot de passe n’est jamais enregistré. Après la vérification, l’app
présente la clé d’appareil ; le serveur répond par une nouvelle session et une
nouvelle clé. Une clé déjà remplacée qui revient est considérée comme copiée et
le téléphone est délié. **Changer de compte** et la désactivation dans le profil
demandent une confirmation, puis révoquent le lien sur le serveur. Une connexion
par mot de passe avec un autre compte retire le lien de l’ancien compte.

La fenêtre d’empreinte est dessinée par Android ou iOS ; l’app en fixe seulement
les textes (titre, sous-titre et bouton **Utiliser le mot de passe**). Android gère
lui-même les essais refusés dans cette fenêtre et ne prévient l’app qu’à la fin ;
après une annulation, l’écran affiche donc un rappel neutre plutôt qu’une erreur.
Trop d’essais refusés bloquent le capteur : Android demande alors le code du téléphone.

| Action API | Route |
| --- | --- |
| Lier le téléphone (session requise) | `POST /api/v1/me/biometric-devices` |
| Se connecter avec la clé d’appareil | `POST /api/v1/auth/biometric/login` |
| Délier le téléphone | `POST /api/v1/auth/biometric/revoke` |
| Révoquer la session | `POST /api/v1/auth/logout` |

Sur l’émulateur, définir un code (`adb shell locksettings set-pin 1234`), ajouter une
empreinte dans **Réglages → Sécurité → Déverrouillage**, puis simuler le doigt avec
`adb emu finger touch 1` (un autre numéro simule un doigt inconnu).

### Accueil

Les cartes **Trouver un trajet** et **Proposer un trajet** sont plus compactes pour
garder **Prochains trajets** visible sur les petits écrans. Elles se réduisent à 97 %
sous le doigt, sans rebond. Les blocs apparaissent l’un après l’autre (30 ms d’écart),
l’onglet **Trajets** et l’état vide utilisent une icône de voiture et les horaires
utilisent des chiffres à chasse fixe. Le texte secondaire des cartes atteint un
contraste de 7,5:1. Le réglage système de réduction des animations est respecté.

### Gestion des annonces et cycle de vie des trajets

Depuis **Trajets → Demandes / Offres → Mes annonces**, l’auteur retrouve ses
annonces, y compris celles qui sont fermées. La fiche permet de modifier une
annonce à venir sans réservation, ou de l’annuler après confirmation.
L’édition reprend les coordonnées exactes de l’auteur et vérifie la révision
pour refuser une sauvegarde devenue obsolète. Dès qu’une réservation a existé,
la modification est bloquée afin de préserver son itinéraire dans l’historique.

Depuis **Mes trajets**, les participants retrouvent leurs réservations actives.
Chacun peut annuler sa réservation avant le départ. Le conducteur peut démarrer
puis terminer le trajet pour tous les passagers confirmés de la même offre.
Annuler une annonce ferme toutes ses réservations actives et prévient les
participants. Annuler une réservation d’offre restitue les places une seule fois.
Si un conducteur annule une demande acceptée, la demande est remise en attente.
Si le passager annule sa propre demande, celle-ci est fermée.

**Mes trajets → Historique** affiche les trajets terminés ou annulés avec leur
fiche et leurs anciens messages. Le chat devient consultable en lecture seule
et toute position partagée est masquée à la clôture du trajet. Les notifications
d’annulation, de départ et d’arrivée ouvrent également la fiche concernée.

La migration **V23** conserve les réservations annulées et permet une nouvelle
réservation du même passager, avec un nouvel identifiant. Les actions verrouillent
les données dans une transaction pour éviter les doubles réservations et les
restitutions de places multiples. Le départ est une action explicite du conducteur.

| Action API authentifiée | Route sous `/api/v1/marketplace` |
| --- | --- |
| Mes annonces | `GET /listings?kind=OFFER&mine=true` ou `kind=REQUEST` |
| Modifier | `PUT /listings/{kind}/{id}` avec `listing` et `revision` |
| Annuler l’annonce | `POST /listings/{kind}/{id}/cancel` |
| Départ / arrivée / annulation d’une réservation | `POST /trips/{id}/actions/START`, `COMPLETE` ou `CANCEL` |
| Historique | `GET /trips?history=true` |

Validation du 15 novembre 2026 avec 166 tests mobiles et 6 tests d’intégration
marketplace, dont les accès par rôle, les transitions, l’historique, les éditions
obsolètes et les acceptations / annulations concurrentes.

### Comptes de démonstration locaux

#### Validation à deux comptes du 15 novembre 2026

Le test `RideMarketplaceIntegrationTest` passe sur une base PostgreSQL isolée.
Un essai supplémentaire sur l’API locale a vérifié la publication d’une offre,
son acceptation et sa répétition sans double réservation, les rôles des deux
participants, les notifications, les messages dans les deux sens, puis
l’acceptation d’une demande par le conducteur. Le partage de position a été
vérifié avec une coordonnée de test envoyée à l’API puis supprimée. La réception
d’une position issue du capteur GPS Android reste à vérifier sur deux appareils.

Deux comptes de démonstration existent dans le volume PostgreSQL local, avec
le mot de passe `EmsiDemo2026!` pour chacun.

| Rôle | Email |
| --- | --- |
| Conducteur | `conducteur.demo@emsi-edu.ma` |
| Passager | `passager.demo@emsi-edu.ma` |

Leurs trajets et messages d’essai portent la mention `DEMO`. Ces comptes ne sont
pas créés automatiquement dans une nouvelle base.

Sur ce PC, Jenkins occupe le port 8080. Démarrer EMSIDrive avec
`./scripts/start-backend.ps1 -Port 8081` et compiler l’app pour l’émulateur avec
`--dart-define=API_BASE_URL=http://10.0.2.2:8081`.

#### Compte de test initial

Un compte a été créé et sa connexion vérifiée dans la base locale utilisée pour les essais :

| Champ | Valeur |
| --- | --- |
| Email | `test@emsi-edu.ma` |
| Mot de passe | `test@emsi-edu.ma` |

Ce compte sert aux essais locaux. Il est conservé dans le volume PostgreSQL, mais n’est
pas créé automatiquement sur une base neuve : dans ce cas, le créer depuis l’inscription.
L’analyse nécessite une clé Gemini côté serveur ; une offre gratuite avec quotas est disponible.

### Analyser un emploi du temps

Créer une clé sur [Google AI Studio](https://aistudio.google.com/api-keys), puis
ajouter dans `backend/.env.local` (ignoré par Git) :

```properties
GEMINI_API_KEY=votre_cle
GEMINI_MODEL=gemini-3.8-flash
GEMINI_FALLBACK_MODELS=gemini-3.5-flash-lite,gemini-3.1-flash-lite
GEMINI_ATTEMPT_SECONDS=20
# Secours Groq optionnel, après le premier modèle Gemini :
GROQ_API_KEY=votre_cle_groq
GROQ_MODEL=qwen/qwen3.8-27b
```

Redémarrer le backend après configuration. Aucune clé dans Flutter ; aucune installation
Tesseract ni modèle local. Les offres gratuites sont soumises aux quotas des fournisseurs.

Dans **Planning → Ajouter mon emploi du temps**, sélectionner une photo JPEG/PNG ou un PDF
de 1 à 3 pages (8 Mo maximum). Recadrer le tableau sur son groupe et préciser celui-ci
si nécessaire. Après l’envoi, l’analyse continue en arrière-plan ; l’utilisateur peut
changer d’écran ou fermer l’application. Le résultat reste accessible dans Planning
et Profil. Le serveur passe au modèle de secours sur quota, délai ou résultat invalide.
Vérifier les horaires de présence et la période, puis confirmer l’enregistrement.
Le document est transmis à Google ou à Groq en secours et retenu temporairement en base pendant le travail,
puis supprimé à la fin ; les imports expirent après 24 h. La saisie manuelle reste disponible.

Les suggestions utilisent uniquement les offres publiées et disponibles des 7 prochains
jours, le campus choisi, les premiers/derniers horaires et le rayon autour du point
personnel choisi sur la carte. Le rayon utilise une distance à vol d’oiseau, pas la
distance routière. Le point et le rayon sont conservés dans le compte. La durée du trajet est
calculée automatiquement via OSRM, modifiable dans les filtres si nécessaire. La carte
affiche les points de rendez-vous approximatifs des conducteurs compatibles ; toucher
une voiture affiche son trajet. La fiche de l’offre permet ensuite de réserver.
En debug avec backend `dev`, « Ajouter 3 trajets de test » crée trois offres fictives
signalées TEST et adaptées à la prochaine présence. Leur réservation fonctionne comme
une offre réelle ; l’action est idempotente et ne réinitialise pas les réservations.
Cet endpoint est absent des profils de production.
Une clé manquante, un quota atteint ou une réponse inexploitable produit une erreur ; les erreurs
sont affichées sans remplacer l’emploi du temps déjà enregistré.

Voir le [contrat et les limites de l’analyse](./backend/SCHEDULE.md).

Dans **Profil → Apparence**, choisir Clair, Sombre ou Auto. Le choix est mémorisé sur
le téléphone. Les jours du planning et de son éditeur sont affichés dans l’ordre.

### Personnaliser son profil

Ouvrir **Profil → Modifier mes informations**, compléter les champs puis enregistrer.
L’email reste celui du compte connecté. Les préférences de campus et de véhicule
préremplissent les prochains formulaires de trajet ; elles restent modifiables avant
publication. Les données sont conservées côté serveur après déconnexion et reconnexion.
Un changement de compte réinitialise les données affichées de l’accueil, du profil et
du planning ; aucune fiche de démonstration ne remplace un profil indisponible.

Les formulaires de trajet sont regroupés en itinéraire, date/heure et places/préférences.
Sur la carte, le bouton de confirmation reste visible pendant le choix du point.

### Essayer le parcours à deux

1. Créer deux comptes distincts sur l’API locale, avec le domaine `emsi-edu.ma` par défaut.
2. Avec le premier compte, publier une demande ou une offre. Choisir un campus, un point
   sur la carte et une heure de départ à venir.
3. Avec le second compte, ouvrir **Trajets → Demandes** ou **Offres**, choisir l’annonce,
   vérifier l’itinéraire et l’accepter.
4. Revenir sur le compte auteur et ouvrir **Notifications**, puis le trajet. Envoyer un
   message et vérifier sa réception sur l’autre compte.
5. Dans le trajet accepté, activer le partage de position côté conducteur et ouvrir la carte
   côté passager. Utiliser deux appareils ou émulateurs pour observer le suivi simultanément.

## Repères pour contribuer

| Emplacement | Ce qu’on y trouve |
| --- | --- |
| [`CONTEXT.md`](./CONTEXT.md) | Architecture cible, règles de contribution et critères de validation. |
| [`backend/`](./backend) | API Spring Boot et migrations Flyway. Les routes de publication, d’acceptation, de chat et de suivi vivent sous `/api/v1/marketplace`. |
| [`mobile/lib/features/rides/`](./mobile/lib/features/rides) | Formulaire, listes et fiches de trajet, carte, chat et suivi. |
| [`mobile/lib/features/notifications/`](./mobile/lib/features/notifications) | Notifications d’acceptation et indicateur de non-lu. |
| [`mobile/lib/features/profile/`](./mobile/lib/features/profile) | Profil réel, formulaire de modification et chargement des données du compte connecté. |
| [`mobile/lib/features/auth/`](./mobile/lib/features/auth) | Connexion, session, liaison du téléphone et connexion par empreinte (`biometric_link_service.dart`, `widgets/biometric_quick_login.dart`). |
| [`backend/src/main/java/ma/emsi/emsidrive/auth/`](./backend/src/main/java/ma/emsi/emsidrive/auth) | JWT, déconnexion révoquée et clés d’appareil (`BiometricDeviceService`). |
| [`mobile/lib/features/schedule/`](./mobile/lib/features/schedule) | Planning par journée, import, vérification des cours et accès aux suggestions. |
| [`backend/src/main/java/ma/emsi/emsidrive/schedule/`](./backend/src/main/java/ma/emsi/emsidrive/schedule) | Analyse Gemini, lecture des documents, mesure des cellules et persistance du planning. |
| [`mobile/assets/maps/marrakech.geojson`](./mobile/assets/maps/marrakech.geojson) | Périmètre utilisé pour valider les points dans l’app et dans l’API. |

Créer une branche de travail depuis `develop`, faire des commits ciblés et ouvrir une
pull request vers `develop`. Suivre les conventions de
[`CONTEXT.md`](./CONTEXT.md). Le code, les commentaires et les commits sont en anglais.
Les textes d’interface sont en français et passent par les fichiers de localisation Flutter.

| Vérification | Commande et dossier |
| --- | --- |
| Serveur | `mvn clean verify` depuis `backend/`, avec Docker pour les tests d’intégration PostgreSQL. |
| Parcours à deux comptes | `mvn -Dtest=RideMarketplaceIntegrationTest test` depuis `backend/`. Le test couvre les deux types d’annonce, les accès privés, les notifications, le chat et la position. |
| Mobile | `flutter analyze` puis `flutter test` depuis `mobile/`. Les tests couvrent aussi la confirmation des cours, les champs incertains et les réponses vides. |

### Dernière validation : connexion par empreinte

Vérifications effectuées le **15 novembre 2026** :

| Contrôle | Résultat |
| --- | --- |
| `mvn test` | **116 tests backend réussis**, dont 8 tests d’intégration PostgreSQL pour la liaison, la rotation de clé, la détection de réutilisation, la révocation et la déconnexion. |
| `flutter analyze` | Aucun problème signalé. |
| `flutter test` | **203 tests Flutter réussis**, dont 24 pour l’empreinte (liaison, connexion, annulation, capteur bloqué, lien révoqué, panne réseau, confirmations, changement de compte). |
| Émulateur Android 17 | Liaison depuis le profil, déconnexion, écran **Bon retour**, connexion par empreinte, doigt inconnu, blocage après plusieurs essais et textes français de la fenêtre système. |

### Validation précédente

Vérifications effectuées le **8 novembre 2026** :

| Contrôle | Résultat |
| --- | --- |
| `mvn verify` | **103 tests backend réussis**, avec PostgreSQL dans Docker pour les tests d’intégration. |
| `flutter analyze` | Aucun problème signalé. |
| `flutter test` | **161 tests Flutter réussis**. |
| Compilation Android | APK de débogage compilé et installé sur le téléphone Infinix utilisé pour les essais. |
| Analyse réelle avec Groq | Vérification de la photo signalée : 13 cours, deux séances doubles, ERP et position du cours suivant du samedi. |
| Persistance et séparation des profils | Vérification après une nouvelle connexion et contrôle qu’un autre compte reste inchangé. |
| Interface | Revue visuelle de l’accueil, du profil, de son formulaire, du planning, des annonces et de la sélection sur la carte. |

Les tests automatisés simulent les réponses de Groq ; les essais réels du fournisseur
ont été effectués séparément. La fonctionnalité de carte étudiante a été reportée et
ne fait pas partie de cette mise à jour.

Les détails techniques se trouvent dans les guides [API](./backend/README.md) et
[mobile](./mobile/README.md).
