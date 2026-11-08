# EMSIDrive

Application de covoiturage pour les étudiants de l’EMSI Marrakech. Chaque trajet relie
l’un des deux campus à un point situé dans Marrakech ou Méchouar-Kasba.

## État du projet

| Partie | Disponible |
| --- | --- |
| Comptes | Inscription avec un domaine étudiant autorisé, connexion, stockage sécurisé des jetons et déconnexion. L’API renouvelle les jetons et permet de consulter ou modifier son profil et de gérer ses véhicules. |
| Mobile | Interface Flutter avec les onglets **Accueil**, **Trajets**, **Planning** et **Profil**. Les notifications restent accessibles par la cloche. L’accueil conserve les deux actions **Trouver un trajet** et **Proposer un trajet**. |
| Profil | Consultation et modification du nom, téléphone, filière, année universitaire et préférences de campus/véhicule. Les données sont enregistrées par compte dans PostgreSQL et rechargées à la connexion. |
| Planning et IA | Import réel de photos JPEG/PNG et de PDF avec Groq, correction des cours détectés, confirmation puis enregistrement. Le planning affiche les sept jours et propose des offres compatibles avec les horaires et le campus. |
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
La restauration de session au lancement, les notifications système et le
back-office restent à réaliser.

## Modifications intégrées le 8 novembre 2026

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

Flyway applique ces migrations au démarrage du backend.

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

### Compte de test local

Un compte a été créé et sa connexion vérifiée dans la base locale utilisée pour les essais :

| Champ | Valeur |
| --- | --- |
| Email | `test@emsi-edu.ma` |
| Mot de passe | `test@emsi-edu.ma` |

Ce compte sert aux essais locaux. Il est conservé dans le volume PostgreSQL, mais n’est
pas créé automatiquement sur une base neuve : dans ce cas, le créer depuis l’inscription.
La configuration Groq utilise uniquement la clé personnelle renseignée dans
`backend/.env.local` ou `GROQ_API_KEY` ; aucune clé API réelle n’est publiée dans ce README.

### Analyser un emploi du temps

Dans `backend/`, copier `.env.example` vers `.env.local` et renseigner `GROQ_API_KEY`.
Ce fichier est ignoré par Git et chargé au démarrage de l’API ; ne jamais mettre la clé
dans Flutter. `GROQ_MODEL` sélectionne le modèle de vision (par défaut `qwen/qwen3.8-27b`).
Redémarrer l’API après un changement de configuration.

Dans **Planning → Ajouter mon emploi du temps**, sélectionner une photo JPEG/PNG ou un PDF de 1 à 3
pages (8 Mo maximum). Recadrer le tableau et indiquer le groupe s’il y en a plusieurs.
L’analyse Groq renvoie de vrais cours éditables. Vérifier les champs incertains, les
horaires, le campus, puis choisir les dates de validité et confirmer l’enregistrement.
La saisie manuelle fonctionne sans IA. Les photos ne sont pas conservées par l’API.

Les suggestions utilisent uniquement les offres publiées et disponibles des 7 prochains
jours, le campus et le premier/dernier cours de chaque journée. La durée du trajet est
une estimation fournie par l’étudiant ; vérifier le lieu de rendez-vous et l’itinéraire
dans la fiche de l’offre. Aucun conducteur, score de compatibilité ou créneau fictif
n’est ajouté. Les quotas du fournisseur peuvent interrompre l’analyse ; les erreurs
sont affichées sans remplacer l’emploi du temps déjà enregistré.

Voir le [contrat et les limites de l’analyse](./backend/SCHEDULE.md).

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
| [`mobile/lib/features/schedule/`](./mobile/lib/features/schedule) | Planning par journée, import, vérification des cours et accès aux suggestions. |
| [`backend/src/main/java/ma/emsi/emsidrive/schedule/`](./backend/src/main/java/ma/emsi/emsidrive/schedule) | Analyse Groq, lecture des documents, mesure des cellules et persistance du planning. |
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

### Dernière validation de ces modifications

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
