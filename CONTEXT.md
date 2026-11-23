# CONTEXT.md — EMSIDrive

Document de référence du projet : contexte, architecture, structure des dossiers et conventions.
À lire avant toute contribution. Toute décision structurante doit être répercutée ici.

---

## 1. Le projet

### Configuration locale OpenRouter du 23 novembre 2026

- Les trois paramètres OpenRouter sont configurés dans `backend/.env.local`,
  ignoré par Git. Le modèle est `particle-ai/particle-1:free`, avec un délai
  de réponse de 120 secondes. La clé reste uniquement sur le poste.
- Le catalogue du fournisseur confirme la prise en charge des images et un
  appel texte authentifié a réussi. Le backend a été redémarré sur 8081.
- Les trois tests ciblés `OpenRouterScheduleAnalyzerTest` et
  `ScheduleAnalyzerTest` passent. L’essai réel via `/api/v1/schedules/analyze`
  avec l’image de démonstration a reçu successivement une limitation 429
  (`SCHEDULE_AI_RATE_LIMIT`), puis une réponse rejetée par la validation
  (`SCHEDULE_AI_INVALID`, HTTP 502). L’analyse complète en ligne reste donc
  à valider avec ce fournisseur. L’estimation globale reste à 87 %.

### Intégration d’équipe du 23 novembre 2026

- La branche `feature/full-integration-ocr-presentation` est intégrée dans `develop`.
  Elle apporte la lecture locale des emplois du temps sur Android avec les modèles
  PaddleOCR embarqués, les imports serveur asynchrones et les préférences de recherche.
- Le suivi GPS ajoute les états de déplacement, d’arrivée et de trajet en cours,
  un accès persistant au trajet actif et le partage Android avec service au premier plan.
  Le profil permet de choisir le thème. Les présentations sont dans `presentation/`.
- Les migrations V1 à V27 conservent leur numérotation publiée sur `develop`.
  Les imports de planning deviennent V28, le suivi des réservations V29.
  V30 relie les nouveaux événements de suivi à la file Firebase. Le chat conserve
  l’événement `CHAT_MESSAGE` attendu par les clients existants.
  `DatabaseMigrationIntegrationTest` vérifie la mise à niveau depuis V27, la
  conservation des contrôles de somme et la reprise des états des anciennes réservations.
- Une sauvegarde de la base locale avant intégration est conservée dans
  `%LOCALAPPDATA%\EMSIDrive\backups\pre-team-integration-*.dump`.
  Le proxy Angular continue de cibler l’API locale sur 8081.
- Validation de l’intégration avec 156 tests backend, 254 tests Flutter et 11 tests
  Angular réussis, analyse Flutter propre et compilation Angular réussie. La base
  locale a appliqué V28 à V30 au démarrage de l’API sur 8081.
- L’APK debug embarquant l’OCR compile sur le poste. Un écran noir au retour de
  l’ancien état de l’émulateur a nécessité un démarrage à froid de Pixel_5 avec
  `-no-snapshot-load -gpu swiftshader_indirect`, puis une relance Flutter sur 8081.
- L’estimation reste à 87 % pendant cette intégration. Les essais complets sur deux
  téléphones et le déploiement restent les validations principales du périmètre.

### Administration Angular et modération du 22 novembre 2026

- À la demande de l’utilisateur, `admin-web/` utilise Angular 21 LTS et TypeScript,
  avec composants standalone et routes chargées à la demande. Node 22.17 est
  compatible. `npm start` expose `127.0.0.1:4200` avec un proxy `/api` vers 8081.
- `/api/v1/admin/**` exige le rôle ADMIN dans Spring Security et dans le contrôleur.
  Le filtre JWT vérifie le compte actif, son rôle actuel et la date d’invalidation
  des accès. Les anciens JWT sans `issuedMillis` utilisent leur `iat`.
- `ModerationService` fournit indicateurs cumulés, comptes, fiches, accès motivé,
  offres/demandes filtrées, dossiers de signalement et historique. Pagination de 20,
  contrôle des filtres et de la révision, verrouillage des décisions, transactions
  communes avec `admin_actions`. Les comptes ADMIN sont protégés contre la suspension.
- V27 ajoute `access_invalidated_at`, les révisions et identifiants d’envoi des
  signalements, leur référence de demande et la table `admin_actions`.
- La suspension révoque refresh tokens, liens biométriques et appareils push.
  Les connexions et renouvellements verrouillent le compte avant leur écriture.
  La connexion biométrique suit l’ordre compte → appareil. `User` utilise
  `DynamicUpdate` pour préserver une décision concurrente lors d’une modification
  du profil. L’acceptation vérifie et verrouille les deux comptes actifs.
- `PUT /api/v1/reports/{submissionId}` accepte un contexte réservation, ou une
  annonce avec son type. Le serveur déduit le compte signalé et refuse l’auto-
  signalement. Même identifiant et contenu donnent le même dossier. Un contenu
  différent avec cet identifiant produit 409. `GET /reports` reste limité à l’auteur.
- Flutter ajoute le formulaire depuis les fiches d’annonce et de trajet, avec
  champs verrouillés après la première tentative pour permettre un réessai identique.
  `Profil → Mes signalements` suit les 100 derniers dossiers du compte.
- La session Angular reste dans `sessionStorage`, avec renouvellement partagé,
  déconnexion et rejet des réponses provenant d’une session précédente. L’API
  protège les autorisations indépendamment du navigateur.
- `scripts/grant-admin.ps1` attribue le rôle à un compte déjà inscrit et actif
  dans le conteneur local, avec audit. Le compte local dédié et son mot de passe
  aléatoire sont décrits dans le README. Les identifiants restent hors du dépôt.
- Avancement fonctionnel estimé après cette étape, 87 %, contre 82 % auparavant.
  Validation avec 128 tests backend, 220 tests Flutter et 11 tests Angular réussis.
  La vérification visuelle automatisée a été interrompue par le contrôle Chrome.
  Vérifier manuellement le rendu, puis poursuivre les essais à deux téléphones et
  le déploiement. La compilation et les tests servent de validation technique.

### Parcours complet et bilan du 22 novembre 2026

- `ListingInput.vehicleId` est facultatif pour les clients existants. L’API
  vérifie le propriétaire, l’état actif, le type et les places du véhicule choisi
  pour une offre. V26 conserve marque, modèle et couleur sur l’offre.
- `GET /marketplace/trips/{id}/summary` renvoie aux participants d’une réservation
  terminée le trajet, la durée serveur, les participants, leur propre avis et les
  frais de l’offre avec les contributions. Les réservations annulées sont exclues.
- `PUT /marketplace/trips/{id}/review` accepte une note 1–5 et un commentaire de
  500 caractères maximum. Le serveur déduit le destinataire. Un seul avis définitif
  par réservation et auteur. Les répétitions identiques sont idempotentes.
- `PUT /marketplace/trips/{id}/costs` publie une seule répartition définitive, par
  le conducteur après la fin. Total de 0 à 99 999,99 MAD, deux décimales maximum.
  Répartition entière au centime, pondérée par les places réservées, conducteur
  compris. Les centimes restants vont au conducteur puis aux passagers par UUID.
- Les tables `ratings`, `fuel_splits` et `fuel_shares` existantes sont réutilisées.
  Les écritures suivent le verrouillage demande → offre → réservation du cycle
  de vie. Le profil renvoie `rating` et `ratingCount`. Les annonces affichent la
  réputation de leur auteur.
- Flutter ouvre `TripSummaryScreen` depuis le trajet terminé. Les anciens accès
  aux frais et avis redirigent vers l’historique. Les frais constituent un
  récapitulatif à régler entre les participants.
- Avancement estimé après cette étape, 82 %, contre 74 % auparavant. La grille du
  README conserve les pondérations. Les essais sur deux téléphones physiques,
  le back-office et le déploiement restent à traiter.
- Validation locale avec le conducteur de démonstration via l’API et le compte
  ouvert dans l’émulateur. Chat, position de test, démarrage, fin, bilan et deux
  avis enregistrés. Répartition de 10,01 MAD en 5,01 MAD et 5,00 MAD. La vraie
  notification FCM « Trajet terminé » a été reçue en arrière-plan et a rouvert le
  trajet. Le trajet et ses données de démonstration restent dans l’historique.
- 123 tests backend et 217 tests Flutter réussis. Analyse Flutter sans erreur.
  APK debug reconstruite avec l’API de l’émulateur sur `10.0.2.2:8081`.

### Gestion mobile des véhicules du 22 novembre 2026

- `Profil → Mes véhicules` utilise les routes existantes `/api/v1/me/vehicles`.
  Liste, création, modification et suppression avec confirmation sont reliées à
  PostgreSQL. Champs alignés sur `VehicleRequest`, avec 1 à 8 places passagers.
- `vehiclesProvider` observe `sessionIdProvider` pour recharger au changement de
  compte. Le formulaire conserve ses champs après erreur et refuse les mutations
  si sa session d’origine a changé.
- La sélection d’un véhicule précis dans les offres reste à relier.
- À la demande de l’utilisateur, annoncer le pourcentage après chaque tâche
  terminée et mettre à jour la grille du README. Estimation globale après cette
  étape, 74 %, contre 70 % avant la gestion mobile des véhicules. Les pondérations
  incluent le back-office et le déploiement et restent des estimations.

### Intégration des notifications système du 22 novembre 2026

- V25 crée `push_devices` et `push_deliveries`. Un trigger lie la file à la
  transaction d’insertion des notifications de trajet, y compris `CHAT_MESSAGE`.
- `PUT /api/v1/me/push-devices` inscrit un identifiant d’installation FCM avec le
  refresh token actif du même compte. `DELETE` retire uniquement l’appareil du
  compte authentifié. La rotation transfère le lien vers le nouveau refresh token.
- `PushDeliveryWorker` verrouille les envois et appareils avec `SKIP LOCKED`,
  vérifie le compte, la génération et la session, puis envoie via `PushSender`.
  Réessais bornés à cinq, expiration après une heure, suppression des cibles FCM
  désinscrites. Un expéditeur simulé permet les tests sans compte Firebase.
- Flutter utilise `PushService`, `PushHost` et `PushSetting`. Inscription après
  consentement, réessai au retour au premier plan, validation des UUID et du compte
  pour les liens, retrait lors de la déconnexion. Les textes sont dans `app_fr.arb`.
- Le plugin Google Services Android est conditionnel au fichier local
  `mobile/android/app/google-services.json`. Le SDK Flutter utilise `register()`
  et `onRegistered`, le SDK Admin 9.12 utilise `setFid()`.
  Le manifeste active `firebase_messaging_installation_id_enabled`, requis pour
  l’enregistrement FID. Toute modification du manifeste exige une reconstruction.
- L’activation demande `PUSH_ENABLED=true` côté serveur avec des credentials ADC.
  Android charge la configuration native par défaut. Les fichiers Firebase et clés
  de service sont exclus du dépôt. Les commandes figurent dans le README.
- Le projet Firebase `emsidrive-a62d1` est configuré le 22 novembre, avec
  l’application Android et Cloud Messaging HTTP v1 activé. `google-services.json`
  est installé localement. La clé privée reste dans
  `%LOCALAPPDATA%\EMSIDrive\firebase-service-account.json`, hors du dépôt.
  `start-backend.ps1` détecte ce fichier ou accepte `-FirebaseCredentials`.
  Flutter essaie la configuration native par défaut et accepte une désactivation
  explicite avec `PUSH_ENABLED=false`. Le push iOS attend sa configuration APNs.
- Après correction du manifeste, l’activation inscrit l’émulateur Pixel 5 dans
  `push_devices`. Réception réelle vérifiée avec un envoi direct SDK Admin,
  application en arrière-plan. Le parcours complet de trajet entre deux appareils
  et la réception après fermeture normale restent à valider.
- Le projet utilise le forfait Spark. Analytics et les options Gemini et
  Google Developer Program ont été désactivés pendant sa création.

**EMSIDrive** est une plateforme de covoiturage réservée aux étudiants de l'**EMSI Marrakech**.

Elle permet à un étudiant de publier ou de demander un trajet, de trouver des conducteurs proches,
de partager les frais d'essence, d'importer son emploi du temps et de recevoir des suggestions
de trajets partagés, puis d'évaluer le trajet effectué.

### Composants

| Composant | Rôle | Technologie |
|-----------|------|-------------|
| **API** | Back-end métier, authentification, persistance, notifications | Spring Boot 3.5 (Java 17) + PostgreSQL 16 |
| **Mobile** | Application étudiante (conducteur / passager) | Flutter (Dart) |
| **Admin web** | Back-office de modération et de supervision | Angular 21 LTS + TypeScript |

### Périmètre fonctionnel (issu des maquettes)

1. Connexion / inscription étudiant
2. Nouvelle demande de trajet
3. Conducteurs proches (géolocalisation)
4. Fiche conducteur
5. Partage des frais d'essence
6. Évaluation du trajet
7. Import de l'emploi du temps
8. Créneaux détectés automatiquement
9. Suggestions de trajets partagés + détail d'une suggestion
10. Notifications et propositions

La référence visuelle mobile est [EMSIDrive_maquettes_mobile.html](EMSIDrive_maquettes_mobile.html).

### Rôles utilisateurs

- **Étudiant** : publie une demande, réserve une place, évalue.
- **Conducteur** : étudiant proposant des places sur son trajet.
- **Administrateur** : modère via l'admin web (comptes, signalements, statistiques).

---

## 2. Structure des dossiers

Monorepo : les trois composants vivent dans le même dépôt et évoluent ensemble.
L'arborescence ci-dessous est la **cible** du projet. Le serveur et l'application mobile
sont en développement. Le [README](./README.md) décrit les fonctionnalités disponibles
et les écrans qui utilisent encore des données de démonstration.

```
EMSIDrive/
├── CONTEXT.md                    # Ce document
├── README.md                     # Démarrage rapide
├── .editorconfig                 # Indentation et fins de ligne
├── .gitignore
├── EMSIDrive_maquettes_mobile.html  # Maquettes mobiles (référence UI)
│
├── backend/                      # API Spring Boot + PostgreSQL
│   ├── pom.xml
│   ├── docker-compose.yml        # PostgreSQL 16 pour le développement local
│   ├── README.md
│   └── src/
│       ├── main/java/ma/emsi/emsidrive/
│       │   ├── EmsiDriveApplication.java
│       │   ├── config/           # Sécurité, OpenAPI, CORS
│       │   ├── common/           # web/ (health), exception/ (contrat d'erreur)
│       │   ├── auth/             # Inscription, connexion, refresh token, déconnexion, clés d'appareil (empreinte)
│       │   ├── user/             # Étudiants, profils
│       │   ├── vehicle/          # Véhicules des conducteurs
│       │   ├── ride/             # Trajets proposés
│       │   ├── booking/          # Réservations de places
│       │   ├── tracking/         # Suivi temps réel du trajet
│       │   ├── fuel/             # Frais d'essence et répartition
│       │   ├── rating/           # Évaluations conducteur/passager
│       │   ├── schedule/         # Emploi du temps et créneaux détectés
│       │   ├── matching/         # Suggestions de trajets partagés
│       │   ├── notification/     # Notifications et propositions
│       │   └── admin/            # Back-office et modération
│       │       (chaque module : controller/ service/ repository/ entity/ dto/ mapper/)
│       ├── main/resources/
│       │   ├── application.yml
│       │   ├── application-dev.yml
│       │   ├── application-prod.yml            # (à venir)
│       │   └── db/migration/     # Scripts Flyway versionnés
│       └── test/
│           ├── java/ma/emsi/emsidrive/   # Tests unitaires et d'intégration
│           └── resources/application-test.yml  # Profil de test (H2, Flyway off)
│
├── mobile/                       # Application Flutter
│   ├── pubspec.yaml
│   ├── l10n.yaml                 # Configuration de la génération des traductions
│   ├── assets/images/            # Logo EMSIDrive (extrait des maquettes)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart              # MaterialApp.router, thème, routes
│   │   ├── core/                 # theme/, constants/, network/, router/, errors/
│   │   ├── features/             # auth/, home/, rides/, notifications/, profile/
│   │   │                         # (chaque module : domain/, data/, application/,
│   │   │                         #  presentation/)
│   │   ├── l10n/                 # app_fr.arb + fichiers générés
│   │   └── shared/               # widgets/ (design system), utils/
│   ├── test/                     # Tests unitaires et widget tests
│   │   ├── helpers/              # pump_app.dart, fakes partagés
│   │   ├── shared/widgets/       # Tests des widgets du design system
│   │   └── features/<feature>/   # Un dossier de tests par fonctionnalité
│   └── integration_test/         # Tests d'intégration (à venir)
│
├── admin-web/                    # Back-office Angular
│   ├── package.json
│   ├── proxy.conf.json           # /api → API locale sur 8081
│   └── src/
│       ├── app/
│       │   ├── core/             # Session HTTP, états des listes
│       │   ├── features/         # Login, shell, dashboard, users, rides, reports, audit
│       │   ├── shared/           # Pagination, libellés des états
│       │   └── app.routes.ts     # Routes et garde administrateur
│       └── styles.scss           # Thème EMSI responsive
│
├── docs/                                     # (à venir)
│   ├── scrum/                    # Backlog, sprints, rétrospectives
│   ├── api/                      # Contrat OpenAPI exporté
│   ├── db/                       # Schéma et diagrammes
│   └── design/                   # Thème, composants UI
│
├── scripts/                      # Scripts de dev (démarrage de la pile locale)
│   └── start-backend.ps1         # PostgreSQL + API, attend que /health réponde
└── .github/workflows/            # (à venir) CI : build, tests, lint
```

Chaque composant est autonome : il possède son propre outillage, ses tests et son pipeline.

---

## 3. Méthode de travail : SCRUM

- **Sprints de 2 semaines**, revue et rétrospective en fin de sprint.
- **Backlog** dans `docs/scrum/` : user stories au format
  `En tant que <rôle>, je veux <objectif> afin de <bénéfice>`, avec critères d'acceptation.
- **Estimation** en story points ; priorisation par valeur métier.
- **Board** : `To Do` → `In Progress` → `In Review` → `Done`.

### Definition of Ready (DoR)

- User story formulée avec critères d'acceptation testables.
- Maquette ou description UI disponible (mobile : maquettes HTML).
- Dépendances API identifiées.

### Definition of Done (DoD)

- Code revu et approuvé par au moins un pair (Pull Request).
- **Tests écrits et passants** (voir section 6) ; aucun test désactivé sans justification.
- CI verte : build, tests, lint.
- Textes d'interface en français, code et commentaires en anglais.
- Documentation mise à jour si le comportement ou le contrat API change.

---

## 4. Conventions de nommage

### Règle de langue

- **Code, identifiants, noms de fichiers techniques, commentaires, logs, messages de commit : anglais.**
- **Textes d'interface visibles par l'utilisateur : français** (labels, boutons, erreurs, emails).
- Flutter centralise ses traductions dans les fichiers ARB. Les widgets utilisent
  `AppLocalizations` pour leurs textes.
- L’administration utilise le français dans ses templates Angular. Les libellés
  d’états réutilisés sont centralisés dans `shared/label.ts`.

### API (Spring Boot / Java)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Classes | `PascalCase` | `RideRequestService` |
| Méthodes / variables | `camelCase` | `findNearbyDrivers()` |
| Constantes | `UPPER_SNAKE_CASE` | `MAX_SEATS_PER_RIDE` |
| Packages | minuscules, par domaine | `ma.emsi.emsidrive.ride` |
| DTO | suffixés `Request` / `Response` / `Dto` | `RideCreateRequest` |
| Entités JPA | nom métier au singulier | `Ride`, `RideBooking` |
| Endpoints REST | pluriel, minuscules, kebab-case | `/api/v1/ride-requests` |
| Champs JSON | `camelCase` | `departureTime` |

- Versionnement d'API dans l'URL : `/api/v1/...`.
- Réponses d'erreur normalisées :
  `{ "timestamp": "...", "status": 400, "code": "VALIDATION_ERROR", "message": "...", "details": [...] }`.
  Le champ `details` porte la liste `[{ "field": "...", "message": "..." }]` et n'est
  présent que pour les erreurs de validation.
- Aucune entité JPA exposée directement par un contrôleur (toujours un DTO).

Codes d'erreur utilisés (stables, jamais traduits, le mobile s'appuie dessus) :

| Code | HTTP | Origine |
|------|------|---------|
| `VALIDATION_ERROR` | 400 | Bean Validation sur un DTO |
| `MALFORMED_REQUEST_BODY` | 400 | Corps JSON illisible ou type incompatible |
| `INVALID_PARAMETER` | 400 | Paramètre de chemin / requête mal typé (ex. UUID invalide) |
| `EMAIL_DOMAIN_NOT_ALLOWED` | 400 | Inscription hors domaines étudiants |
| `INVALID_CREDENTIALS` | 401 | Email ou mot de passe incorrect |
| `INVALID_REFRESH_TOKEN` | 401 | Refresh token inconnu, expiré ou révoqué |
| `INVALID_DEVICE_KEY` | 401 | Téléphone non lié, lien révoqué ou clé d'appareil déjà remplacée (le lien est alors révoqué) |
| `UNAUTHORIZED` | 401 | Requête sans jeton valide sur une route protégée |
| `ACCOUNT_DISABLED` | 403 | Compte désactivé |
| `USER_NOT_FOUND` | 404 | Utilisateur du jeton absent en base |
| `VEHICLE_NOT_FOUND` | 404 | Véhicule inexistant **ou** appartenant à un autre utilisateur |
| `EMAIL_ALREADY_USED` | 409 | Inscription sur un email déjà pris |

- Un véhicule d'autrui répond `404 VEHICLE_NOT_FOUND`, jamais `403` : on ne révèle
  pas l'existence d'une ressource à laquelle on n'a pas droit.
- Swagger est protégé par le schéma `bearerAuth` : le bouton **Authorize** accepte
  directement l'`accessToken` renvoyé par `/api/v1/auth/login`.

### Base de données (PostgreSQL)

- Tables et colonnes en `snake_case`, tables au **pluriel** : `ride_requests`, `created_at`.
- Clés primaires `id` (UUID), clés étrangères `<entité>_id` : `driver_id`.
- Index nommés `idx_<table>_<colonnes>` : `idx_ride_requests_departure_time`.
- Chaque évolution de schéma passe par une migration Flyway : `V<numéro>__<description>.sql`.

### Flutter (Dart)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Fichiers | `snake_case` | `ride_request_screen.dart` |
| Classes / widgets | `PascalCase` | `RideRequestCard` |
| Écrans | suffixe `Screen` | `NearbyDriversScreen` |
| Providers / blocs | suffixe `Provider` / `Bloc` | `AuthBloc` |
| Membres privés | préfixe `_` | `_isLoading` |
| JSON | `fromJson` / `toJson` | `RideRequest.fromJson()` |

- Un dossier par fonctionnalité dans `lib/features/<feature>/`
  (`domain/`, `data/`, `application/`, `presentation/`).
- Aucun appel HTTP direct depuis un widget : passer par un repository.
- **Pattern repository** : chaque fonctionnalité expose une interface abstraite
  (`abstract interface class <Feature>Repository`) dans `data/`, une
  implémentation `Fake<Feature>Repository` (données réalistes en français) et un
  provider Riverpod `@Riverpod(keepAlive: true)`. Tant que l'API n'est pas
  branchée, le provider retourne le Fake ; il suffira de changer le provider.
  Les tests surchargent ce provider avec `overrideWithValue`.
- **État** : Riverpod avec génération de code (`@riverpod` / `@Riverpod(keepAlive: true)`),
  fichiers `*.g.dart` versionnés, régénérés par `dart run build_runner build`.
- **Navigation** : go_router avec un `StatefulShellRoute.indexedStack`
  (un onglet = une branche, chacune conserve sa pile). Les écrans
  d'authentification (`/login`, `/register`) vivent au-dessus du shell.
- **Réseau** : un seul client `Dio` exposé par provider ; les erreurs sont
  converties en `AppFailure` par `ErrorMapper`.
- **Widgets partagés** : `lib/shared/widgets/` (`PrimaryButton`, `OutlineButton`,
  `AppTextField`, `AppCard`, `AppBadge`, `Avatar`, `RatingStars`, `SectionTitle`,
  `SkeletonLoader`, `EmptyState`, `ErrorState`, barre de navigation) ; toute
  nouvelle primitive du design system va dans ce dossier.
- **Aucun texte français codé en dur** dans un widget : passer par les ARB
  (`flutter gen-l10n`).
- **Tests de widgets** : `test/features/<feature>/`, helpers partagés dans
  `test/helpers/` (`pumpEmsiDriveApp` pour l'app complète). Les tests qui
  observent un état de chargement passent `settle: false` et augmentent la
  surface de test (`tester.binding.setSurfaceSize`) pour éviter les taps hors écran.

### Admin web (Angular / TypeScript)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Composants standalone | `PascalCase`, un par fichier | `Users` dans `users.ts` |
| État réactif | signals Angular | `selected`, `loading` |
| Fonctions / variables | `camelCase` | `fetchPendingReports()` |
| Types / interfaces | `PascalCase`, sans préfixe `I` | `RideSummary` |
| Fichiers utilitaires | `kebab-case` | `format-date.ts` |

### Git — nommage des branches

Format : `<type>/<ticket>-<slug-court-en-anglais>`

| Type | Usage | Exemple |
|------|-------|---------|
| `feature/` | Nouvelle fonctionnalité | `feature/EMSI-42-nearby-drivers` |
| `fix/` | Correction de bug | `fix/EMSI-57-null-seats` |
| `hotfix/` | Correctif urgent en production | `hotfix/EMSI-61-auth-crash` |
| `chore/` | Maintenance, dépendances, CI | `chore/EMSI-33-upgrade-deps` |
| `docs/` | Documentation seule | `docs/EMSI-12-api-contract` |
| `release/` | Préparation de version | `release/1.4.0` |

Branches longues : `main` (production) et `develop` (intégration).
Toute branche part de `develop` et y revient via Pull Request ; `hotfix/` part de `main`.

### Git — format des commits

**Conventional Commits**, en anglais, à l'impératif, sans point final.

```
<type>(<scope>): <subject>

<body — quoi et pourquoi, pas comment>

Refs: EMSI-42
```

- **Types** : `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **Scopes** : `api`, `mobile`, `admin`, `db`, `auth`, `rides`, `notifications`, `ci`, `docs`.
- Sujet : minuscule, ≤ 72 caractères, pas de « update » seul — décrire l'effet.
- Un commit = un changement cohérent et compilable.
- Référencer le ticket dans le pied de commit (`Refs: EMSI-42`, `Closes: EMSI-42` en fin de story).

Exemples :

```
feat(api): add nearby driver search endpoint

fix(mobile): prevent empty seat count on booking

test(api): cover ride expense split calculation edge cases
```

---

## 5. Design system

Thème **vert EMSI**. Les couleurs ne sont jamais écrites en dur dans les écrans :
elles passent par des tokens partagés entre mobile et admin web.

| Token | Valeur | Usage |
|-------|--------|-------|
| `primary` | `#015629` | Vert foncé : actions principales, icônes et états sélectionnés |
| `primaryContainer` | `#015629` (teintes dérivées) | Surfaces d'accentuation |
| `secondary` / `accent` | `#7ECC18` | Vert clair : CTA secondaires, badges, états actifs |
| `success` | `#7ECC18` | Confirmations |
| `error` | rouge standard du design system | Erreurs de validation |
| `surface` | blanc / gris très clair | Fonds de cartes et d'écrans |

- Contraste : texte blanc sur `#015629` ; texte `#015629` sur `#7ECC18`.
- Les tokens sont définis une seule fois :
  - mobile : `lib/core/theme/`
  - admin web : `src/styles/`
  - documentation : `docs/design/`
- Typographie, rayons et espacements suivent la même source unique.
- Icônes : une seule famille par écran (contour). La cloche et l’onglet **Trajets**
  (voiture) suivent cette règle.
- Texte secondaire : contraste d’au moins 4,5:1 (WCAG AA) ; les cartes de l’accueil
  visent 7:1.

### Mouvement

- Entrées en *ease-out* ; les listes et blocs arrivent décalés de 30 ms.
- Cartes cliquables réduites à 0,97 sous le doigt, retour 20 % plus rapide que
  l’appui, sans rebond ; le reflet d’appui reprend la couleur du texte de la carte.
- Pas de rebond sur l’interface courante. Le badge d’empreinte
  (`BiometricIndicator`) réserve ses mouvements aux états : pulsations limitées en
  attente, ondes pendant la lecture, coche en cas de réussite, secousse en cas d’échec.
- Le réglage système « réduire les animations » coupe ces mouvements ; seules les
  couleurs et les icônes changent.

### Organisation mobile et profils persistants

La navigation comporte Accueil, Trajets, Planning et Profil ; les notifications
s’ouvrent depuis une cloche. Les anciens liens d’import sous `/rides/` redirigent
vers `/planning/`. Les en-têtes utilisent une surface neutre, les cartes une surface
blanche en thème clair et le vert EMSI souligne les actions. `FormSection` regroupe
les champs des formulaires ; la confirmation sur la carte reste fixe en bas.

Le profil mobile utilise les routes authentifiées `GET/PUT /api/v1/me`. V22 ajoute
les préférences de campus et de véhicule aux champs de profil existants. L’identité
vient exclusivement du JWT ; l’email et le rôle ne sont pas modifiables via ce formulaire.
Le profil et l’accueil n’utilisent plus de fiches de démonstration.

`TokenStorage` notifie les changements de compte. `sessionIdProvider` réinitialise les
données du profil, du planning et de l’accueil ; un renouvellement d’access token ne
change pas cette identité de session. Les réponses tardives d’un ancien compte ne
doivent jamais remplacer les données du compte courant. Les préférences de trajet
sont appliquées à l’ouverture du formulaire sans écraser des choix déjà modifiés.

---

## 6. Tests et qualité

Les tests font partie de la Definition of Done : aucune story n'est terminée sans eux.

### Back-end (API)

- **Tests unitaires** : JUnit 5 + Mockito sur les services et la logique métier
  (répartition des frais, détection de créneaux, matching des suggestions).
- **Tests d'intégration** : `@SpringBootTest` + Testcontainers (PostgreSQL réel).
- **Tests de contrat** : vérification des DTO et codes HTTP des contrôleurs.
- Objectif de couverture : **≥ 80 %** sur les services et la logique métier.

```bash
cd backend && mvn verify
```

### Mobile (Flutter)

- **Tests unitaires** : repositories, modèles, logique de présentation.
- **Widget tests** : écrans clés (connexion, nouvelle demande, conducteurs proches).
- **Tests d'intégration** : parcours complet demande → suggestion → évaluation.

```bash
cd mobile
flutter pub get
flutter gen-l10n                              # traductions depuis les ARB
dart run build_runner build                   # providers Riverpod (*.g.dart)
flutter test && flutter analyze
```

L'URL de l'API est injectée par `--dart-define=API_BASE_URL=…`
(défaut : `http://10.0.2.2:8080`, l'hôte de l'émulateur Android).
Sur un téléphone physique, l'émulateur n'existe pas : il faut passer l'IP LAN de
la machine de développement (`--dart-define=API_BASE_URL=http://192.168.1.110:8080`)
et l'API doit être joignable depuis le Wi-Fi (pare-feu Windows autorisant le port 8080).
La permission `INTERNET` est déclarée dans le manifest principal, donc elle est
présente en debug comme en release.

Pour ne pas répéter l'URL à chaque commande, on passe un fichier de définitions :
`mobile/.env.example` est versionné, on le copie en `mobile/.env` (ignoré par Git)
et on renseigne l'IP LAN de sa propre machine.

```bash
cd mobile
flutter run --dart-define-from-file=.env                                  # téléphone branché en USB/Wi-Fi
flutter build apk --release --dart-define-from-file=.env                  # APK à installer à la main
```

Ces valeurs sont **compilées dans le binaire** : changer d'IP ou de réseau impose
un rebuild, pas seulement un redémarrage de l'app.

Symptôme d'une cible injoignable (mauvaise IP, ou API arrêtée) : l'app attend
puis affiche « Le serveur prend beaucoup de temps à répondre » (timeout de 20 s).
Avant de suspecter l'app, vérifier que l'API répond :

```powershell
Invoke-WebRequest http://localhost:8080/health -UseBasicParsing   # doit renvoyer 200
powershell -ExecutionPolicy Bypass -File scripts\start-backend.ps1 # sinon, relancer la pile
```

### Mise à jour sur un téléphone physique

L'APK est installé « à la main » (*sideload*), pas depuis le Play Store : il n'y a
donc **aucun canal de mise à jour automatique**. Toute évolution du code mobile
exige une reconstruction et une réinstallation.

| Ce qui change | Action |
| --- | --- |
| Code Dart (écrans, logique, thème) | `flutter run` → rechargement à chaud (`r` / `R`), ou rebuild + réinstallation |
| Code natif, manifest, plugin, dépendances | Rebuild complet obligatoire |
| Back-end uniquement | Aucun rebuild mobile : l'app interroge l'API à l'exécution |

Tant que l'`applicationId` (`ma.emsi.emsidrive.emsidrive_mobile`) et la clé de
signature restent identiques, la réinstallation est une **mise à jour sur place** :
les données de l'app (dont les jetons en stockage sécurisé) sont conservées.
Une désinstallation, ou un changement de clé de signature, efface les données
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).

### Admin web

- Tests de composants et de services avec le runner du projet ; lint TypeScript obligatoire.

```bash
cd admin-web && npm run build && npm test -- --watch=false
```

### Règles

- Un bug corrigé s'accompagne d'un test de non-régression.
- Les tests ne dépendent pas de données de production ; les jeux de données viennent de `scripts/`.
- La CI exécute build + tests + lint sur chaque Pull Request ; une PR rouge n'est pas fusionnée.

---

## 7. Sécurité et configuration

### Emplois du temps — Gemini

Le parcours utilise `/api/v1/schedules`, Gemini côté serveur et PostgreSQL.
L’OCR local Tesseract a été supprimé ; aucune installation OCR ni modèle local
n’est nécessaire. `GeminiScheduleAnalyzer` utilise l’endpoint compatible de Google
et `VisionScheduleAnalyzer` porte les instructions, la mesure des grilles et la
validation stricte des réponses. `GroqScheduleAnalyzer` reste un adaptateur historique
non enregistré dans Spring, utilisé par les tests de régression.

Créer une clé sur https://aistudio.google.com/api-keys et la placer uniquement dans
`backend/.env.local` (ignoré) ou l’environnement : `GEMINI_API_KEY`.
`GEMINI_MODEL` vaut `gemini-3.8-flash` par défaut. `GEMINI_FALLBACK_MODELS` définit
les modèles de secours (défaut : `gemini-3.5-flash-lite,gemini-3.1-flash-lite`).
Chaque tentative est limitée à `GEMINI_ATTEMPT_SECONDS` (20 s par défaut), trois
modèles maximum. Quota atteint, indisponibilité, délai ou JSON invalide déclenchent
le modèle suivant sans attendre `Retry-After`. Un groupe ambigu n’est pas réinterprété.
Avec `GROQ_API_KEY`, le deuxième essai utilise Groq (`GROQ_MODEL=qwen/qwen3.8-27b`),
puis le premier secours Gemini, toujours trois tentatives maximum. La clé reste côté serveur.
Groq reçoit au maximum trois images par requête ; le budget de temps couvre tous les lots.
Sans clé, l’analyse renvoie
`SCHEDULE_AI_NOT_CONFIGURED` et la saisie manuelle reste accessible. L’offre gratuite
de Google est soumise à ses quotas ; HTTP 429 est traduit en `SCHEDULE_AI_RATE_LIMIT`.

Import JPEG/PNG/PDF (1 à 3 pages), brouillon éditable et confirmation obligatoire.
L’extraction conserve uniquement les jours et horaires, sans matière, salle, personne
ou campus. Les cellules doubles et les pauses sont respectées via les colonnes mesurées,
ou les en-têtes et étendues fournis par Gemini en lecture globale. Une incertitude
impose une correction avant enregistrement. L’import mobile utilise `POST /schedules/imports`
qui renvoie 202 dès la validation et la mise en file ; il ne bloque pas sur Gemini.
V28 ajoute `schedule_import_jobs` et `schedule_travel_preferences`. Le document normalisé
est retenu en base tant que le travail attend ou tourne, puis supprimé à la réussite,
à l’échec ou à l’annulation. Les imports et résultats non utilisés expirent après 24 h.
La transmission à Google et la rétention temporaire sont annoncées dans l’application.

La période de validité d’une semaine type reste à renseigner, sans exceptions datées.
Le planning numérique affiche, par jour, l’arrivée avant la première séance et le départ
après la dernière. La recherche moderne `/schedules/matches` exige un campus explicite,
un point privé sur la carte et un rayon (100 à 10 000 m), enregistrés par compte.
Elle filtre les offres réellement réservables par campus, jour, horaires et distance
à vol d’oiseau entre les points en ville. Le point exact du conducteur reste protégé
par la marketplace ; la réponse ne fournit que la distance et la fiche publique.
Le profil permet de consulter, modifier, remplacer et supprimer le planning.
« Enregistrer et réserver un trajet » ouvre les offres compatibles avec réservation
explicite. Une analyse simultanée par compte, deux workers par instance et au plus
50 imports actifs dans la file partagée. Les workers prennent un bail PostgreSQL et
reprennent les travaux dont le processus est mort ; un jeton de bail empêche une réponse
tardive de remplacer le résultat courant. Annuler supprime le document et interrompt
le worker local si présent. `GET /imports/latest` permet de récupérer le résultat après
navigation ou redémarrage du téléphone. L’empreinte du document déduplique les renvois
identiques pour le même compte pendant 24 h ; aucun cache n’est partagé entre comptes.
La sauvegarde confirme le planning et consomme le résultat d’import dans la même transaction.
L’ancien `/analyze` et `/suggestions` restent compatibles mais ne sont plus le parcours mobile.
Détails dans [backend/SCHEDULE.md](backend/SCHEDULE.md).

Pour un nouvel import sans dates, le mobile propose explicitement les sept prochains
jours, modifiables avant confirmation. Les horaires complets marqués à vérifier peuvent
être validés par la confirmation globale, sans rééditer chaque séance. Les jours/heures
manquants, chevauchements et périodes invalides bloquent toujours l’enregistrement avec
un motif précis. Le nom par défaut est initialisé après disponibilité des traductions.
Gemini reçoit toutes les cartes d’une grille dans un seul appel et utilise
`reasoning_effort=low` afin de réduire l’attente ; les contrôles des cellules restent actifs.

`AuthenticatedApi` est partagé par les emplois du temps et la marketplace pour
coordonner le renouvellement des JWT. Il clone les formulaires multipart lors d’un
nouvel essai après 401 et rejette les réponses d’une session déjà déconnectée.

Le planning affiche la semaine du lundi au dimanche avec une arrivée et un départ
par jour et un bouton de réservation. Les séances sont retriées après chaque ajout
ou modification. Les horaires particuliers imprimés pour une ligne sont conservés
(`dayColumns` en lecture globale, `rowColumns` sur les cartes mesurées) ; un vendredi
après-midi détecté avant 15 h est signalé pour vérification, sans imposer une règle
nationale. L’éditeur propose explicitement un début à 15 h pour le vendredi.

La réservation restaure le point et le campus, calcule automatiquement le trajet
routier avec OSRM et enregistre sa durée estimée pour le matching. Si OSRM échoue,
la durée manuelle reste disponible avec un message explicite. La carte montre les
points de rendez-vous approximatifs des offres compatibles, jamais des positions
GPS en direct avant réservation. Toucher une voiture sélectionne son offre et son
itinéraire ; la réservation utilise le parcours marketplace existant.

En debug, « Ajouter 3 trajets de test » appelle `POST /api/v1/schedules/demo-rides`.
Le contrôleur et le service n’existent que dans le profil Spring `dev`. Les trois
conducteurs sont fictifs, identifiés TEST, avec des identifiants stables par compte.
Les horaires s’alignent sur la prochaine présence dans les sept jours. Répéter l’ajout
ne crée pas de doublon et ne réinitialise jamais les réservations ou leurs places.

Le suivi des réservations utilise `tracking_state` (migration V29) : réservé,
en route, arrivé, trajet commencé, terminé ou annulé. Le conducteur fait avancer
les étapes ; un passager peut annuler avant le départ effectif. Les étapes d'une
même offre sont synchronisées entre ses passagers. Les annulations libèrent les
places une seule fois et les notifications sont privées aux participants.

Après réservation, une confirmation ouvre le suivi ; une barre de trajet actif
permet d'y revenir. Les alertes et l'historique fonctionnent dans l'application.
Les notifications push lorsque l'application passager est fermée ne sont pas
implémentées (FCM/APNs reste à connecter).

Le conducteur active explicitement le GPS. Android utilise un service de premier
plan avec notification persistante pour continuer hors de l'écran du trajet.
Les permissions et restrictions du téléphone restent applicables ; un processus
tué ne partage plus sa position. Le partage s'arrête à la fin du trajet, à la
déconnexion ou après quatre heures. Les positions de plus de 30 secondes sont
masquées côté serveur et mobile. L'estimation OSRM est routière, sans trafic en
direct ; aucune estimation n'est inventée lorsque le GPS ou le routage manque.
Les trois conducteurs TEST sont statiques et ne simulent pas de GPS en direct.

Le bouton Appeler reste accessible depuis les onglets suivi et chat d'une
réservation active. Un menu propose Téléphone (composeur `tel:`, sans appel
automatique) ou WhatsApp (conversation via le lien officiel `wa.me`, puis
bouton d'appel dans WhatsApp). Les numéros marocains 05/06/07 sont convertis
en format 212 pour WhatsApp ; les autres nécessitent un indicatif explicite.
Le numéro du partenaire provient de son profil, n'est jamais
exposé dans les annonces publiques et est masqué après clôture du trajet.
Un numéro absent ou invalide affiche une explication. La carte distingue
la prise en charge (repère passager, couleur tertiaire) de la destination
(drapeau, couleur primaire). Avant « Passager à bord », le calcul GPS vise
le rendez-vous ; ensuite, il vise la destination de la réservation.

Les boutons Demandes / Offres / Mes trajets changent explicitement de liste.
L'accueil présente une action principale Trouver un trajet, deux cartes compactes
Proposer un trajet / Mon planning, puis les prochains trajets avec Tout voir.
L'avatar ouvre le profil ; les notifications restent accessibles en haut.
Les cartes secondaires s'empilent avec un texte fortement agrandi. Le thème
clair/sombre et la préférence de réduction des animations sont respectés.
Les réservations annulées ou terminées sont exclues des prochains trajets.
Les rafraîchissements utilisent un bloc synchrone dans `setState` : retourner
directement l'affectation d'un Future provoquait une assertion en debug et
empêchait l'affichage du nouvel onglet. Les erreurs offrent un bouton Réessayer.
Les réservations actives sont remontées dans les offres (et dans les demandes
liées via `ride_request_id`), avec bordure, halo discret, statut et accès Suivre.
L'actualisation des états retire cette mise en évidence à l'annulation ou à la
fin ; les anciennes réservations restent consultables dans Mes trajets.

`themeModeProvider` applique le choix clair, sombre ou système depuis le profil.
Le choix est local au téléphone et persiste dans le stockage sécurisé sous
`appearance.themeMode`, indépendamment des jetons de session.

- Authentification par **JWT** (access token court + refresh token).
- Deux rôles seulement : `STUDENT` (inscription publique) et `ADMIN` (créé côté serveur). Toute autre valeur est refusée par la contrainte `chk_users_role`.
- Les refresh tokens sont **persistés côté serveur** (seul le hash SHA-256 est stocké) et **rotatifs** : chaque `/auth/refresh` révoque le token présenté et en émet un nouveau.
- `POST /auth/logout` révoque le refresh token présenté. La réponse est toujours `204`, même pour un jeton inconnu ou déjà révoqué, pour ne rien révéler.
- **Connexion par empreinte** : `POST /me/biometric-devices` (session requise) lie le téléphone et renvoie une clé d'appareil de 32 octets aléatoires, affichée une seule fois. La table `biometric_devices` (V24) ne garde que son hash SHA-256.
- `POST /auth/biometric/login` compare la clé en temps constant, verrouille la ligne (`PESSIMISTIC_WRITE`), remplace la clé et émet une session. Une clé déjà remplacée qui revient révoque le téléphone : la révocation est conservée malgré l'erreur (`noRollbackFor`).
- `POST /auth/biometric/revoke` délie le téléphone si la clé correspond et répond `204` dans tous les cas. L'empreinte elle-même ne quitte jamais l'appareil.
- L'inscription est limitée aux domaines étudiants, configurables via `app.security.student-email-domains`.
- Mots de passe hachés (BCrypt), jamais journalisés.
- Secrets et identifiants **hors du dépôt** : variables d'environnement ou `.env` ignoré par Git.
- Validation systématique des entrées côté API (Bean Validation) ; le mobile ne fait qu'aider l'utilisateur.
- Autorisations vérifiées côté serveur : un étudiant n'accède qu'à ses propres trajets, réservations et données.
- Données personnelles (position, emploi du temps) minimisées et non exposées dans les logs.

### Côté mobile

- Les tokens sont stockés dans `flutter_secure_storage` sous les clés
  `emsidrive.access_token` et `emsidrive.refresh_token` ; jamais en préférences
  partagées, jamais dans un fichier, jamais dans un log.
- Les erreurs de l'API sont traduites en `AppFailure` puis présentées en
  français par `AuthErrorPresenter` ; les codes serveur inconnus ne sont jamais
  affichés bruts.
- Les validateurs de formulaire reprennent les contraintes Bean Validation du
  back-end (email, mot de passe 8–72, nom 120, téléphone optionnel) ; le serveur
  reste l'autorité finale.
- Le routeur de l’application démarre sur `/session`. `SessionController` vérifie
  les jetons du stockage sécurisé avec `/me` avant d’autoriser les routes privées.
  Un refus du jeton d’accès déclenche le renouvellement partagé dans
  `AuthenticatedApi`. Un refus définitif du renouvellement efface la session et
  redirige vers `/login`. Une panne réseau conserve les jetons et propose une
  reprise explicite. La déconnexion attend la suppression du stockage sécurisé.
- `createAppRouter` accepte un contrôleur de session pour activer ces gardes.
  Le fournisseur de production l’injecte systématiquement. Les tests de navigation
  isolée peuvent construire un routeur sans garde, tandis que les tests de session
  utilisent le véritable fournisseur de l’application.
- Une rotation conserve l’identité de session. Une connexion, une déconnexion ou
  la destruction du stockage en mémoire invalide les réponses encore en vol.
  Une ancienne connexion ou un ancien renouvellement ne peut pas remplacer les
  jetons d’un autre compte.
- La déconnexion appelle `/auth/logout` avec un délai court, puis efface les jetons
  même hors ligne. Une session ouverte rouvre l’accueil sans empreinte.
- Le lien d’empreinte (`emsidrive.biometric_device_id`, `…_device_key`, `…_email`,
  `…_name`) survit à la déconnexion. La clé remplacée par le serveur est enregistrée
  **avant** la nouvelle session. Un `401` efface le lien ; une panne réseau le conserve.
- `local_auth` est appelé en mode biométrie seule ; le repli est le mot de passe de
  l’app, pas le code du téléphone. `BiometricAuth` est l’unique point d’accès au
  plugin et se remplace par un faux capteur dans les tests. Android impose
  `FlutterFragmentActivity`, la permission `USE_BIOMETRIC` et un thème de lancement
  AppCompat ; iOS impose `NSFaceIDUsageDescription`.
- La fenêtre d’empreinte est dessinée par le système : seuls ses textes sont
  personnalisés (`BiometricPromptTexts`). Les essais refusés y sont gérés par Android
  et l’app reçoit seulement « annulé ». Délier le téléphone demande une confirmation.

### Variables d'environnement de sécurité

| Variable | Défaut | Rôle |
|----------|--------|------|
| `JWT_SECRET` | secret de développement | Clé HMAC-SHA256, **32 octets minimum** ; obligatoire en production |
| `JWT_ACCESS_TOKEN_TTL` | `PT15M` | Durée de vie de l'access token |
| `JWT_REFRESH_TOKEN_TTL` | `P7D` | Durée de vie du refresh token |
| `STUDENT_EMAIL_DOMAINS` | `emsi-edu.ma` | Domaines autorisés à l'inscription, séparés par des virgules |

## Cycle de vie marketplace

La migration V23 ajoute les horodatages réels de départ et de fin aux offres.
Une réservation reste `CONFIRMED` pendant le trajet, avec un statut exposé
`ONGOING` lorsque l’offre est en cours. Le conducteur démarre et termine l’offre
pour tous ses passagers confirmés. Les réservations terminées deviennent
`COMPLETED` et les annulations deviennent `CANCELLED`.

Les mutations verrouillent les lignes dans l’ordre demande, offre, réservation.
Une annulation est idempotente et restitue les places d’une offre une seule fois.
L’unicité offre/passager s’applique aux réservations actives via un index partiel.
Une réservation annulée reste en historique et une nouvelle acceptation crée un
nouvel identifiant. Une annonce ayant déjà eu une réservation ne peut plus être
modifiée afin de conserver les itinéraires historiques. Les éditions vérifient
une révision et reprennent les coordonnées exactes uniquement pour l’auteur.

Une annulation par le conducteur remet une demande acceptée en attente. Une
annulation de la demande par son passager la ferme. L’annulation d’une annonce
ferme ses réservations actives. Les notifications de changement restent privées
aux participants. Les messages historiques restent lisibles, leur envoi et le
partage de position sont refusés après clôture. Le mobile expose les annonces
personnelles, les actions confirmées et l’historique depuis Trajets.

