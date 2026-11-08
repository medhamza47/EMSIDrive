# CONTEXT.md — EMSIDrive

Document de référence du projet : contexte, architecture, structure des dossiers et conventions.
À lire avant toute contribution. Toute décision structurante doit être répercutée ici.

---

## 1. Le projet

**EMSIDrive** est une plateforme de covoiturage réservée aux étudiants de l'**EMSI Marrakech**.

Elle permet à un étudiant de publier ou de demander un trajet, de trouver des conducteurs proches,
de partager les frais d'essence, d'importer son emploi du temps et de recevoir des suggestions
de trajets partagés, puis d'évaluer le trajet effectué.

### Composants

| Composant | Rôle | Technologie |
|-----------|------|-------------|
| **API** | Back-end métier, authentification, persistance, notifications | Spring Boot 3.5 (Java 17) + PostgreSQL 16 |
| **Mobile** | Application étudiante (conducteur / passager) | Flutter (Dart) |
| **Admin web** | Back-office de modération et de supervision | Application web (React + TypeScript) |

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
│       │   ├── auth/             # Inscription, connexion, refresh token
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
├── admin-web/                    # Back-office web (à venir)
│   ├── package.json
│   └── src/
│       ├── assets/
│       ├── components/           # Composants réutilisables
│       ├── features/             # users/, rides/, reports/, dashboard/
│       ├── layouts/
│       ├── router/
│       ├── services/             # Appels API
│       ├── styles/               # Thème, tokens de design
│       └── types/
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
- Les traductions sont centralisées (fichiers ARB en Flutter, fichiers i18n en admin web).
  Aucun libellé français codé en dur dans les widgets ou composants.

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

### Admin web (TypeScript / React)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Composants | `PascalCase`, un par fichier | `UserTable.tsx` |
| Hooks | préfixe `use` | `useRideFilters.ts` |
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
cd admin-web && npm test && npm run lint
```

### Règles

- Un bug corrigé s'accompagne d'un test de non-régression.
- Les tests ne dépendent pas de données de production ; les jeux de données viennent de `scripts/`.
- La CI exécute build + tests + lint sur chaque Pull Request ; une PR rouge n'est pas fusionnée.

---

## 7. Sécurité et configuration

### Emplois du temps — implémentation Groq

Le parcours d’emploi du temps utilise désormais `/api/v1/schedules` et PostgreSQL,
sans créneaux ni suggestions de démonstration. Import JPEG/PNG/PDF via Groq côté serveur,
brouillon éditable, confirmation obligatoire, période de validité et campus par cours.
La clé se configure exclusivement dans `backend/.env.local` (ignoré) ou l’environnement.
Pour les séances doubles, Groq doit fournir les en-têtes horaires et l’étendue de chaque
cellule en lecture globale. Pour les photos avec une grille détectable, le serveur mesure
directement les bordures, crée des cartes de cellules à identifiants opaques, puis utilise
Groq uniquement pour transcrire leur contenu. Il valide tous les identifiants et dérive
la fin de la dernière colonne couverte. Les photos sont normalisées en PNG pour éviter
qu’une seconde compression JPEG efface les traits fins. Il conserve les
horaires explicites et les pauses, sans durée fixe de 90 minutes. Une étendue incertaine
laisse l’heure de fin vide et exige une correction avant enregistrement.
Les suggestions filtrent les annonces marketplace existantes selon les horaires, le
campus et la durée estimée du trajet. Détails et limites dans [backend/SCHEDULE.md](backend/SCHEDULE.md).

`AuthenticatedApi` est partagé par les emplois du temps et la marketplace pour
coordonner le renouvellement des JWT. Il clone les formulaires multipart lors d’un
nouvel essai après 401 et rejette les réponses d’une session déjà déconnectée.

- Authentification par **JWT** (access token court + refresh token).
- Deux rôles seulement : `STUDENT` (inscription publique) et `ADMIN` (créé côté serveur). Toute autre valeur est refusée par la contrainte `chk_users_role`.
- Les refresh tokens sont **persistés côté serveur** (seul le hash SHA-256 est stocké) et **rotatifs** : chaque `/auth/refresh` révoque le token présenté et en émet un nouveau.
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
- La restauration de session au démarrage et la garde de redirection ne sont
  **pas encore implémentées** : l'app démarre sur `/login`.

### Variables d'environnement de sécurité

| Variable | Défaut | Rôle |
|----------|--------|------|
| `JWT_SECRET` | secret de développement | Clé HMAC-SHA256, **32 octets minimum** ; obligatoire en production |
| `JWT_ACCESS_TOKEN_TTL` | `PT15M` | Durée de vie de l'access token |
| `JWT_REFRESH_TOKEN_TTL` | `P7D` | Durée de vie du refresh token |
| `STUDENT_EMAIL_DOMAINS` | `emsi-edu.ma` | Domaines autorisés à l'inscription, séparés par des virgules |

