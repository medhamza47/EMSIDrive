# EMSIDrive

Application de covoiturage pour les étudiants de l’EMSI Marrakech. Chaque trajet relie
l’un des deux campus à un point situé dans Marrakech ou Méchouar-Kasba.

## État du projet

| Partie | Disponible |
| --- | --- |
| Comptes | Inscription avec un domaine étudiant autorisé, connexion, stockage sécurisé des jetons et déconnexion. L’API renouvelle les jetons et permet de consulter ou modifier son profil et de gérer ses véhicules. |
| Mobile | Les 13 maquettes du [fichier HTML](./EMSIDrive_maquettes_mobile.html) ont été intégrées à Flutter. L’interface comporte les onglets **Accueil**, **Trajets**, **Notifications** et **Profil**. |
| Carte de Marrakech | Choix du sens **Vers l’EMSI** ou **Depuis l’EMSI**, puis du campus **Targa** ou **Centre**. Pour l’autre extrémité, l’étudiant place un repère sur la carte ou utilise **Ma position**. L’aperçu routier affiche le tracé, la distance et la durée estimée. |
| Annonces | **Trajets** sépare les **Demandes**, les **Offres** et **Mes trajets**. La publication et l’acceptation passent par l’API. La fiche d’une annonce affiche le tracé avant l’acceptation. |
| Acceptation | L’API réserve la place et crée, dans la même transaction, une notification pour l’auteur de l’annonce. Les deux participants retrouvent le trajet dans **Mes trajets** et peuvent s’écrire dans un chat privé. |
| Suivi | Depuis un trajet accepté, le conducteur peut activer **Partager ma position**. Le passager voit le repère s’actualiser sur sa carte toutes les quelques secondes. |

Le point en ville est arrondi dans l’annonce publique. Les coordonnées exactes, le chat
et la position du conducteur sont accessibles aux participants via le trajet accepté.
Le partage s’arrête lorsque le conducteur quitte le trajet ou met l’application en
arrière-plan. Le serveur masque une position datant de plus de 30 secondes. Les
notifications d’acceptation apparaissent dans l’application, avec un indicateur de non-lu.

Les prochains trajets de l’Accueil, certains écrans
issus des maquettes, le partage des frais, les évaluations et l’analyse de l’emploi du temps
avec suggestions utilisent encore des données locales ou des interactions simulées. Les
API de profil et de véhicules existent, tandis que le Profil mobile sert principalement à la
déconnexion. La restauration de session au lancement, les notifications système et le
back-office restent à réaliser.

## Lancer le projet

Prévoir un JDK 17 ou supérieur, Maven 3.9+, Docker, Flutter avec une version de Dart
compatible avec [pubspec.yaml](./mobile/pubspec.yaml), et un émulateur Android.

Le parcours décrit ici est disponible sur la branche par défaut
[`develop`](https://github.com/medhamza47/EMSIDrive/tree/develop).

```bash
git fetch origin
git switch develop
git pull --ff-only origin develop
```

Depuis `backend/`, démarrer PostgreSQL 16 et l’API. Flyway applique les migrations au
démarrage, dont la migration V20 pour les annonces et le chat.

```bash
docker compose up -d
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

PostgreSQL écoute sur le port 5433 de la machine et l’API sur le port 8080.
[`/health`](http://localhost:8080/health) permet de vérifier l’API et
[Swagger](http://localhost:8080/swagger-ui.html) présente les routes. Sous Windows,
[`scripts/start-backend.ps1`](./scripts/start-backend.ps1) peut démarrer les deux services
avec le JDK Android Studio et les dépendances Maven déjà en cache.

Lancer Flutter depuis `mobile/` une fois l’émulateur démarré.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Sur un téléphone physique, utiliser l’adresse de la machine sur le réseau local, ou suivre
les exemples de [`mobile/.env.example`](./mobile/.env.example). L’URL est intégrée lors de
la compilation. La carte et l’aperçu routier utilisent OpenStreetMap et OSRM en
développement. Leur configuration est décrite dans le [guide mobile](./mobile/README.md#marrakech-ride-map).

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
| [`mobile/assets/maps/marrakech.geojson`](./mobile/assets/maps/marrakech.geojson) | Périmètre utilisé pour valider les points dans l’app et dans l’API. |

Créer une branche de travail depuis `develop`, faire des commits ciblés et ouvrir une
pull request vers `develop`. Suivre les conventions de
[`CONTEXT.md`](./CONTEXT.md). Le code, les commentaires et les commits sont en anglais.
Les textes d’interface sont en français et passent par les fichiers de localisation Flutter.

| Vérification | Commande et dossier |
| --- | --- |
| Serveur | `mvn clean verify` depuis `backend/`, avec Docker pour les tests d’intégration PostgreSQL. |
| Parcours à deux comptes | `mvn -Dtest=RideMarketplaceIntegrationTest test` depuis `backend/`. Le test couvre les deux types d’annonce, les accès privés, les notifications, le chat et la position. |
| Mobile | `flutter analyze` puis `flutter test` depuis `mobile/`. La dernière vérification du parcours a passé les 147 tests Flutter et un essai sur le Pixel 5. |

Les détails techniques se trouvent dans les guides [API](./backend/README.md) et
[mobile](./mobile/README.md).
