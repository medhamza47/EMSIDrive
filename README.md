# EMSIDrive

Windows + Android team presentation: [ready-to-run package and source setup](presentation/TEAM-SETUP.md).

Application de covoiturage pour les étudiants de l’EMSI Marrakech. Chaque trajet relie
l’un des deux campus à un point situé dans Marrakech ou Méchouar-Kasba.

## Dernières modifications intégrées (23 novembre 2026)

Cette version unifie l’ensemble des travaux de l’équipe (**Hamza, Nabil, Youssef, Ali**) :

1. **Analyse d’emploi du temps sur le téléphone (PaddleOCR v6 ONNX) & En ligne (OpenRouter / PaddleOCR-VL)** :
   - **Mode « Sur ce téléphone »** : lecture 100 % hors-ligne des images (JPEG/PNG) et PDF (1 à 3 pages) directement sur Android grâce au moteur `mobile/android/paddleocr-sdk/` et à la détection géométrique des grilles et cellules fusionnées (`LocalTimetableGridDetector`), sans aucune clé API requise.
   - **Mode « En ligne »** : import asynchrone en arrière-plan (`ScheduleImportJobs`, table SQL `schedule_import_jobs`) avec support multi-fournisseurs (`OpenRouterScheduleAnalyzer`, `PaddleScheduleAnalyzer` sous Docker dans `deploy/paddleocr-vl/`).
2. **Suivi GPS en direct, cycle de vie étendu & contact rapide** :
   - Partage de position GPS conducteur en arrière-plan (`driver_tracking_provider.dart`), calcul dynamique de l’ETA routier (OSRM), étapes guidées (*Confirmé → En route → Au rendez-vous → En cours → Terminé*), barre de trajet actif permanente (`active_ride_bar.dart`), chat privé et boutons d’appel téléphonique / **WhatsApp** direct.
3. **Fusion complète avec les fonctionnalités de `develop`** :
   - **Back-office Web Angular 21 (`admin-web/`)** : tableau de bord, gestion des comptes, supervision des trajets, traitement des signalements et journal d’audit (proxy configuré sur le port `8081`).
   - **Gestion des véhicules (`vehicles_screen.dart`)**, **Bilan de fin de trajet, évaluations & partage des frais d’essence (`trip_summary_screen.dart`)** et **Notifications Push Android (Firebase)**.
   - **Migrations Flyway harmonisées (`V1` à `V30`)** dans `backend/src/main/resources/db/migration/` pour éviter tout conflit de version en base PostgreSQL.
4. **Présentation officielle du projet (`presentation/`)** :
   - Diaporama PowerPoint 15 slides (`presentation/EMSIDrive_Presentation.pptx` et version interactive `presentation/EMSIDrive_Presentation.html`) accompagné des captures d’écran réelles dans `presentation/screenshots/`.

### Configuration rapide de l’IA en ligne pour l’équipe

Le mode **« Sur ce téléphone »** fonctionne immédiatement sans configuration. Pour activer en plus le mode **« En ligne » (OpenRouter)** sur votre machine locale, créez le fichier `backend/.env.local` (ignoré par Git pour la sécurité) à partir de `backend/.env.example` :

```env
OPENROUTER_API_KEY=<cle_openrouter_partagee_en_equipe>
OPENROUTER_MODEL=particle-ai/particle-1:free
OPENROUTER_TIMEOUT_SECONDS=120
```

Après modification, redémarrez le backend pour charger ces paramètres. Sur ce
poste, l’API utilisée par l’émulateur écoute sur `8081`. Si elle est déjà démarrée,
arrêtez son processus avant de relancer `scripts/start-backend.ps1 -Port 8081`.
Une réponse `SCHEDULE_AI_RATE_LIMIT` indique une limitation du fournisseur
OpenRouter. Réessayez ultérieurement ou utilisez le mode « Sur ce téléphone ».

## État du projet

### Mise à jour du 23 novembre 2026

Les changements de `feature/full-integration-ocr-presentation` sont intégrés dans
`develop`. Ils comprennent l’OCR local Android pour les photos et PDF d’emplois du
temps, les imports asynchrones, les préférences de recherche, le suivi GPS avec états
de déplacement, le retour au trajet actif et le choix du thème. Les présentations
de l’équipe sont disponibles dans `presentation/`.

L’intégration conserve les migrations V1 à V27 déjà publiées et ajoute V28 à V30.
La base locale est sauvegardée avant sa mise à jour. L’avancement fonctionnel estimé
reste à **87 %**, dans l’attente des validations à deux téléphones et du déploiement.

Validation de cette intégration avec **156 tests backend**, **254 tests Flutter**
et **11 tests Angular** réussis. L’analyse Flutter et la compilation Angular passent.

| Partie | Disponible |
| --- | --- |
| Comptes | Inscription avec un domaine étudiant autorisé et **adresse confirmée par un code reçu par e-mail**, connexion, stockage sécurisé des jetons et déconnexion révoquée côté serveur. Après une première connexion par mot de passe, le téléphone peut être lié pour se reconnecter **par empreinte**. Un mot de passe oublié se réinitialise avec un **code reçu par e-mail**. L’API renouvelle les jetons et permet de consulter ou modifier son profil et de gérer ses véhicules. |
| Mobile | Interface Flutter avec les onglets **Accueil**, **Trajets**, **Planning** et **Profil**. Les notifications restent accessibles par la cloche. L’accueil conserve les deux actions **Trouver un trajet** et **Proposer un trajet**. |
| Profil | Consultation et modification du nom, téléphone, filière, année universitaire et préférences de campus/véhicule. Les données sont enregistrées par compte dans PostgreSQL et rechargées à la connexion. |
| Véhicules | **Profil → Mes véhicules** permet de consulter, ajouter, modifier et supprimer ses véhicules avec confirmation. Type, marque, modèle, couleur facultative et places passagers sont enregistrés par compte via l’API existante. |
| Planning et lecture sur téléphone | Sur Android 8+, lecture JPEG/PNG/PDF sur l’appareil avec PP-OCRv6 Small embarqué, sans clé ni appel IA externe. Le mode **En ligne** conserve l’import en arrière-plan avec reprise depuis Planning ou Profil. Les deux modes demandent de vérifier les horaires avant l’enregistrement. |
| Carte de Marrakech | Choix du sens **Vers l’EMSI** ou **Depuis l’EMSI**, puis du campus **Targa** ou **Centre**. Pour l’autre extrémité, l’étudiant place un repère sur la carte ou utilise **Ma position**. L’aperçu routier affiche le tracé, la distance et la durée estimée. |
| Annonces | **Trajets** sépare les **Demandes**, les **Offres** et **Mes trajets**. La publication et l’acceptation passent par l’API. La fiche d’une annonce affiche le tracé avant l’acceptation. |
| Acceptation | L’API réserve la place et crée, dans la même transaction, une notification pour l’auteur de l’annonce. Les deux participants retrouvent le trajet dans **Mes trajets** et peuvent s’écrire dans un chat privé. |
| Suivi | Depuis un trajet accepté, le conducteur peut activer **Partager ma position**. Le passager voit le repère s’actualiser sur sa carte toutes les quelques secondes. |
| Bilan et évaluations | Un trajet terminé propose **Voir le bilan et évaluer**. Le bilan privé affiche l’itinéraire, la durée réelle disponible et les participants. Chacun peut noter son partenaire de 1 à 5 avec un commentaire facultatif. La moyenne et le nombre d’avis apparaissent sur le profil et sur les annonces. |
| Frais | Après la fin du trajet, le conducteur peut confirmer un total en MAD. Le serveur conserve une répartition par place occupée, conducteur compris, avec un arrondi exact au centime. |
| Administration Angular | Connexion administrateur, indicateurs réels, recherche et consultation des comptes, suspension/réactivation motivée, supervision des trajets filtrés et historique des décisions. |
| Signalements | Envoi depuis une annonce ou un trajet accepté, suivi dans **Profil → Mes signalements**, examen et décision dans le back-office. |

Le point en ville est arrondi dans l’annonce publique. Les coordonnées exactes, le chat
et la position du conducteur sont accessibles aux participants via le trajet accepté.
Le partage s’arrête lorsque le conducteur quitte le trajet ou met l’application en
arrière-plan. Le serveur masque une position datant de plus de 30 secondes. Les
notifications d’acceptation apparaissent dans l’application, avec un indicateur de non-lu.

L’accueil affiche le nom du compte et ses prochains trajets confirmés depuis l’API.
Certains anciens écrans de recherche de conducteurs issus des maquettes utilisent
encore des interactions simulées. Les accès aux frais et aux évaluations ouvrent
désormais l’historique des trajets réels.
Les notifications système Android disposent d’une intégration Firebase configurée localement.
Le back-office Angular est relié à la même API et à la même base PostgreSQL.

### Suivi de l’avancement

Estimation fonctionnelle établie le 22 novembre 2026, sur le périmètre global
mobile, API, administration et mise en ligne. Chaque ligne représente une part
du projet, appréciée selon les fonctions réalisées et les validations restantes.
Les pondérations sont une estimation de travail et pourront être révisées si le
périmètre change. Après chaque tâche terminée, mettre cette grille à jour et
communiquer le pourcentage au demandeur.

| Domaine | Points réalisés | Poids |
| --- | --- | --- |
| Comptes et profil | 15 | 15 |
| Demandes, offres et cycle du trajet | 20 | 20 |
| Cartes et suivi GPS | 8 | 10 |
| Chat privé | 8 | 10 |
| Notifications | 8 | 10 |
| Planning, import et suggestions | 9 | 10 |
| Gestion des véhicules | 5 | 5 |
| Évaluations et partage des frais | 5 | 5 |
| Back-office | 5 | 5 |
| Qualité, validation sur appareils et déploiement | 4 | 10 |
| **Total** | **87** | **100** |

La gestion mobile des véhicules a fait passer l’estimation de **70 % à 74 %**.
Le parcours véhicule, bilan, évaluations, frais et livraison FCM de fin de trajet
porte ensuite l’estimation à **82 %**. L’administration Angular et la modération
portent l’estimation à **87 %**. Les validations à deux téléphones physiques et
le déploiement font partie du travail restant.

### Administration Angular et modération

Angular **21 LTS**, avec TypeScript et composants standalone, est choisi pour sa
compatibilité avec Node **22.17** installé sur le poste. Le serveur de développement
Angular relaie `/api` vers `http://127.0.0.1:8081`.

Depuis la racine, lancer le backend puis ouvrir un second PowerShell pour Angular.

```powershell
.\scripts\start-backend.ps1 -Port 8081
```

```powershell
cd admin-web
npm ci
npm start
```

Ouvrir [l’administration locale](http://127.0.0.1:4200). Si npm 10.9.2 échoue avec
`edgesOut`, utiliser `npx --yes npm@11 ci`, puis `npm start`.

Le compte doit posséder le rôle `ADMIN` dans PostgreSQL. Pour préparer un compte
sur une nouvelle installation, l’inscrire dans l’application puis exécuter depuis
la racine du dépôt la commande suivante avec son adresse réelle.

```powershell
.\scripts\grant-admin.ps1 -Email administrateur@emsi-edu.ma
```

Cette procédure cible le conteneur local `emsidrive-postgres` et enregistre l’octroi
dans l’historique. L’inscription publique crée toujours un compte étudiant.
Sur le poste de développement actuel, un compte dédié `admin.local@emsi-edu.ma`
est prêt. Son mot de passe aléatoire est conservé dans
`%LOCALAPPDATA%\EMSIDrive\admin-login.txt`, à l’extérieur du dépôt.

Les rubriques **Vue d’ensemble**, **Utilisateurs**, **Trajets**, **Signalements** et
**Historique** utilisent les données réelles. Les listes sont paginées par 20.
Les trajets se filtrent par type, campus, état et date à Marrakech. Les indicateurs
sont cumulés et les trajets terminés comptent les offres terminées.

Dans le mobile, ouvrir une annonce d’un autre étudiant puis **Signaler un problème**,
ou utiliser le drapeau en haut d’un trajet accepté. Choisir le motif et décrire
les faits. **Profil → Mes signalements** affiche les 100 derniers dossiers envoyés.
Le serveur déduit la personne concernée et vérifie la participation au trajet.
Un identifiant d’envoi stable permet de réessayer après une coupure réseau.

Un administrateur peut passer un dossier en examen, le résoudre, le classer ou
le rouvrir avec une note. Les décisions et changements d’accès sont historisés
dans la même transaction. Une révision empêche l’écrasement d’une décision concurrente.
Les comptes administrateur sont protégés contre la suspension dans cette interface.
Un administrateur impliqué dans un dossier doit en confier l’examen à un autre.

La suspension invalide les jetons d’accès existants et révoque les sessions,
les liens biométriques et les appareils de notification. Les annonces de ce compte
sortent des listes publiques et leur acceptation est bloquée côté serveur.
Après réactivation, une nouvelle connexion est nécessaire.

Le back-office s’exécute localement. La validation visuelle automatisée a été
interrompue par l’outil de contrôle de Chrome. Le contrôle manuel du rendu et le
déploiement HTTPS restent à effectuer.

### Gérer ses véhicules

Ouvrir **Profil → Mes véhicules → Ajouter un véhicule**. Choisir voiture ou moto,
renseigner la marque, le modèle, la couleur facultative et de 1 à 8 places
passagers, puis enregistrer. Chaque carte propose la modification et la
suppression avec confirmation. En cas d’échec d’enregistrement, les champs
restent remplis pour permettre un nouvel essai. Un changement de compte recharge
la liste et bloque l’enregistrement d’un formulaire ouvert sur l’ancien compte.

La publication d’une offre propose les véhicules du compte. Le serveur vérifie
leur propriétaire, leur état actif, le type et la capacité. Les annonces et les
trajets conservent la marque, le modèle et la couleur enregistrés lors de la
publication, même si le véhicule est ensuite modifié ou supprimé. Les anciennes
offres et les clients qui omettent `vehicleId` restent compatibles.

### Terminer, évaluer et partager les frais

Depuis **Mes trajets**, le conducteur démarre puis termine le trajet. Dans
**Historique**, ouvrir le trajet puis **Voir le bilan et évaluer**. Le bilan
regroupe le conducteur et les réservations terminées de la même offre. La durée
provient des heures serveur de début et de fin et reste absente si un ancien
trajet ne dispose pas de ces heures.

Chaque auteur peut publier une seule évaluation définitive par réservation.
Le serveur déduit le destinataire à partir des participants et refuse les avis
avant la fin du trajet. Un nouvel envoi identique est accepté sans créer de
doublon. Un avis différent après publication est refusé.

Seul le conducteur renseigne les frais après la fin du trajet. Le montant est
compris entre 0 et 99 999,99 MAD, avec deux décimales maximum. La répartition est
définitive après confirmation. Chaque place occupée porte le même poids, avec
une place pour le conducteur. Une réservation de trois places prend en charge
trois parts. Les centimes restants sont affectés d’abord au conducteur puis aux
passagers, dans un ordre stable. La somme des contributions égale le total.
L’application conserve un récapitulatif de contributions à régler entre
participants. Le règlement effectif reste à organiser entre eux.

V26 ajoute les informations historiques du véhicule et une contrainte unique
pour les nouvelles évaluations marketplace. Les tables `ratings`, `fuel_splits`
et `fuel_shares` existantes sont réutilisées. Les mutations verrouillent le
trajet dans le même ordre que son cycle de vie, pour sérialiser les doubles
soumissions et conserver le partage des frais dans une seule transaction.

Les nouvelles routes authentifiées sont `GET /api/v1/marketplace/trips/{id}/summary`,
`PUT /api/v1/marketplace/trips/{id}/review` et
`PUT /api/v1/marketplace/trips/{id}/costs`. Le bilan est réservé aux participants
d’une réservation terminée. Les accès historiques `/rides/fuel` et `/rides/review`
redirigent vers l’historique pour choisir le trajet concerné.

## Notifications système Android

L’intégration FCM couvre les acceptations, les nouveaux messages et le démarrage,
la fin ou l’annulation d’un trajet. **Profil → Notifications du téléphone** permet
d’autoriser ou de désactiver les alertes. Un appui ouvre le trajet du compte
destinataire après vérification de la session. Au premier plan, une bannière
propose d’ouvrir le trajet.

Le projet Firebase **EMSIDrive** (`emsidrive-a62d1`) est configuré localement avec
l’application Android et Cloud Messaging HTTP v1 activé. Le fichier Android est
ignoré par Git et la clé privée du serveur reste hors du dépôt.

Au démarrage, Android essaie de charger sa configuration Firebase. Une version
sans fichier Firebase affiche la configuration manquante dans le profil et garde
les notifications dans l’application. `--dart-define=PUSH_ENABLED=false` désactive
explicitement cette intégration pour une compilation.

### Activation

1. Créer un projet Firebase et ajouter l’application Android
   `ma.emsi.emsidrive.emsidrive_mobile`.
2. Placer le fichier téléchargé dans `mobile/android/app/google-services.json`.
   Gradle active le plugin Google Services lorsque ce fichier existe.
3. Activer l’API Firebase Cloud Messaging HTTP v1. Dans les réglages du projet,
   ouvrir **Comptes de service** et générer une clé pour le backend. Conserver
   cette clé hors du dépôt et de l’application Android.
4. Définir les variables dans le PowerShell qui démarre le backend, en adaptant
   le chemin de la clé. Redémarrer le backend s’il fonctionne déjà.

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\secrets\firebase-service-account.json'
$env:PUSH_ENABLED = 'true'
.\scripts\start-backend.ps1 -Port 8081
```

5. Compiler ou lancer Android avec Firebase activé.

```powershell
cd mobile
flutter run -d emulator-5554 --dart-define=PUSH_ENABLED=true --dart-define=API_BASE_URL=http://10.0.2.2:8081
```

6. Se connecter, ouvrir **Profil**, activer les notifications et accepter
   l’autorisation Android. Sur téléphone physique, remplacer `10.0.2.2` par
   l’adresse réseau du PC ou celle du backend hébergé.

Sur le PC configuré, la clé serveur est conservée dans
`%LOCALAPPDATA%\EMSIDrive\firebase-service-account.json`. Le script
`start-backend.ps1` la détecte et active l’envoi. Le paramètre
`-FirebaseCredentials 'chemin-du-fichier.json'` permet d’utiliser un autre fichier.
Le backend doit être redémarré après un changement de configuration. Les collègues
doivent installer leur configuration locale avant de tester Firebase.

### Livraison et tests

V25 ajoute les appareils et une file PostgreSQL, alimentée dans la transaction
de chaque événement. Les anciennes alertes ne sont pas envoyées à un nouvel
appareil. Le serveur traite la file toutes les cinq secondes, réessaie les échecs
au maximum cinq fois et expire les envois après une heure. Les alertes lues sont
écartées. Le tag Android reprend l’identifiant de notification pour remplacer
les doublons dans le volet système. Une interruption après un envoi peut provoquer
un réessai.

Le mobile utilise les identifiants d’installation renvoyés par `register()` et
le SDK Admin utilise `setFid()`. Les alertes affichent un texte générique. Le chat
et le GPS restent dans l’API authentifiée. L’inscription dépend d’un jeton de
renouvellement actif, conservé lors de sa rotation. La déconnexion serveur bloque
les envois suivants. Le mobile retire aussi son inscription et un changement de
compte invalide les anciens envois en attente.

Le manifeste Android active `firebase_messaging_installation_id_enabled`, requis
par le SDK pour `register()` et `onRegistered`. Après un changement du manifeste,
recompiler et réinstaller l’application. Un rechargement Flutter ne suffit pas.

Les tests automatisés utilisent un expéditeur simulé. Le 22 novembre 2026,
l’activation a inscrit l’émulateur Pixel 5 dans `push_devices`. Un envoi direct
par le SDK Admin et les credentials locaux a affiché « Test des notifications
réussi. » dans Android, application en arrière-plan. Un second essai avec le
conducteur via l’API et le passager dans l’émulateur a validé les événements de
chat, démarrage et fin via la file PostgreSQL et le worker FCM. La notification
« Trajet terminé » a été affichée en arrière-plan et a rouvert le trajet. Les
essais sur deux téléphones physiques et après fermeture normale restent à
effectuer. Android suspend les messages après un
arrêt forcé jusqu’à la réouverture manuelle. Le push iOS nécessite sa configuration
Firebase/APNs et une validation sur appareil.

Les étapes s’appuient sur les guides officiels de
[réception Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
et de [configuration Admin](https://firebase.google.com/docs/admin/setup).

## Analyse avancee avec PaddleOCR-VL

Le service Docker et les commandes de telechargement sont dans
[deploy/paddleocr-vl/README.md](deploy/paddleocr-vl/README.md).
Le modele complet PaddleOCR-VL-1.6 fonctionne sur le PC; le telephone utilise
le mode **En ligne**. Definir `PADDLE_OCR_URL=http://localhost:8090/layout-parsing`
avant de demarrer le backend pour selectionner ce service.
Les resultats conservent uniquement les jours et les horaires et doivent etre verifies.

## Lecture locale sur Android

Dans **Planning → Importer**, le mode **Sur ce téléphone** utilise les modèles
PP-OCRv6 Small inclus dans l’APK (environ 31 Mo de modèles, hors moteur et
bibliothèques natives). Les photos et les PDF d’une à trois pages sont traités
sur le CPU du téléphone. Les coordonnées OCR et les bordures physiques servent
à associer les jours, les colonnes horaires et les cellules fusionnées. Les
horaires explicitement imprimés dans un cours restent prioritaires. Si une
bordure est incertaine, l’heure de fin reste à compléter plutôt que d’inventer
la durée du cours. Une vérification et une confirmation sont toujours requises.

La lecture locale n’envoie pas le document au serveur et peut fonctionner sans
accès à une API IA. L’enregistrement du planning dans le compte et les recherches
de trajets nécessitent toujours la connexion à l’API EMSIDrive. Garder l’écran
d’import ouvert pendant la lecture ; l’annulation ignore le résultat et libère
le moteur à la fin de l’opération native en cours. Le mode **En ligne** reste
sélectionnable explicitement et n’est jamais lancé automatiquement après un
échec de lecture locale.

Les sources, licences, versions et empreintes des modèles sont documentées dans
[`mobile/android/paddleocr-sdk/README.md`](mobile/android/paddleocr-sdk/README.md).

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
| [`V23__marketplace_ride_lifecycle.sql`](./backend/src/main/resources/db/migration/V23__marketplace_ride_lifecycle.sql) | Horodatages des trajets et historique des réservations annulées, avec unicité limitée aux réservations actives. |
| [`V24__create_biometric_devices_table.sql`](./backend/src/main/resources/db/migration/V24__create_biometric_devices_table.sql) | Téléphones liés pour la connexion par empreinte : seul le hash SHA-256 de la clé d’appareil est stocké, avec date de dernière utilisation et de révocation. |
| [`V28__schedule_import_jobs_and_travel.sql`](./backend/src/main/resources/db/migration/V28__schedule_import_jobs_and_travel.sql) | File d’import des emplois du temps et préférences de déplacement. |
| [`V29__booking_tracking_lifecycle.sql`](./backend/src/main/resources/db/migration/V29__booking_tracking_lifecycle.sql) | États détaillés du trajet et informations de précision GPS. |
| [`V30__tracking_push_events.sql`](./backend/src/main/resources/db/migration/V30__tracking_push_events.sql) | Livraison Firebase des nouveaux événements de réservation et de suivi. |

Flyway applique ces migrations au démarrage du backend.
Les migrations V1 à V27 conservent les noms et contenus publiés sur `develop`.
Les ajouts OCR et GPS de la branche d’intégration deviennent V28 et V29.
La mise à jour d’une base existante de `develop` applique ces trois migrations.
Une base expérimentale ayant déjà utilisé les numéros réattribués de la branche
`feature/full-integration-ocr-presentation` nécessite une réconciliation contrôlée
de son historique Flyway, précédée d’une sauvegarde.

## Lancer le projet

Prévoir un JDK 17 ou supérieur, Maven 3.9+, Docker, Flutter avec une version de Dart
compatible avec [pubspec.yaml](./mobile/pubspec.yaml), et un téléphone Android ou un émulateur.

Pour une copie clonée du dépôt, les commandes suivantes permettent de récupérer la
branche [`develop`](https://github.com/medhamza47/EMSIDrive/tree/develop).

Les fonctionnalités développées jusqu’au 22 novembre 2026, dont les notifications,
les véhicules, les bilans et l’administration Angular, sont intégrées dans
`develop`. Cette branche sert de référence commune pour les contributions.

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

### Confirmation de l’adresse à l’inscription

Une adresse au bon format peut ne correspondre à aucune boîte réelle. L’inscription
se fait donc en deux étapes, et **aucun compte n’est créé tant que l’adresse n’est
pas confirmée** :

1. **Inscription** : le serveur vérifie tout le formulaire (domaine EMSI, adresse
   déjà utilisée, mot de passe…) puis envoie un code à 6 chiffres à l’adresse.
2. **Vérifiez votre e-mail** : l’étudiant saisit le code. Le compte est créé, la
   session ouverte et l’accueil s’affiche, comme avant.

Le code est valable 15 minutes, utilisable une seule fois et lié à l’adresse qui l’a
reçu. Il est bloqué après cinq essais erronés. **Renvoyer le code** redevient
disponible après 60 secondes, et le nouveau code remplace le précédent ; au-delà de
cinq codes par heure pour une adresse, le serveur répond 429. **Modifier l’adresse
e-mail** revient au formulaire, toujours rempli. Les comptes existants ne sont pas
concernés : la connexion ne change pas.

| Action API | Route |
| --- | --- |
| Vérifier le formulaire et envoyer le code | `POST /api/v1/auth/register/code` (202, ou les erreurs habituelles du formulaire, 429 `VERIFICATION_CODE_LIMIT`) |
| Créer le compte | `POST /api/v1/auth/register` avec `verificationCode` (201, ou 400 `INVALID_VERIFICATION_CODE` / `EMAIL_VERIFICATION_REQUIRED`) |

En local avec Mailpit, n’importe quelle adresse `@emsi-edu.ma` reçoit le code dans
[la boîte Mailpit](http://localhost:8025) : des comptes d’essai fictifs restent
possibles. Avec un vrai SMTP (Brevo), seule une adresse réelle reçoit le code.
La migration **V32** crée `email_verification_codes`. Les tests d’intégration
désactivent l’exigence par `src/test/resources/config/application.properties`,
sauf `EmailVerificationIntegrationTest` qui couvre le vrai parcours.

### Mot de passe oublié

Sur l’écran de connexion, **Mot de passe oublié ?** ouvre un formulaire prérempli
avec l’adresse saisie. Le serveur envoie par e-mail un code à **6 chiffres**, valable
**15 minutes** et utilisable une seule fois. L’écran suivant demande le code, le
nouveau mot de passe (8 caractères minimum) et sa confirmation. **Renvoyer le code**
redevient disponible après 60 secondes ; le nouveau code remplace le précédent.

La réponse est identique qu’un compte existe ou non, et un compte suspendu ne reçoit
rien. Le serveur conserve seulement une empreinte HMAC du code, bloque le code après
cinq essais erronés et limite les envois à un par minute et cinq par heure. Une
réinitialisation réussie ferme toutes les sessions du compte : jetons d’accès et de
renouvellement, liens d’empreinte et appareils de notification. L’étudiant se
reconnecte ensuite avec le nouveau mot de passe.

| Action API | Route |
| --- | --- |
| Demander un code | `POST /api/v1/auth/password/forgot` (toujours 202) |
| Changer le mot de passe | `POST /api/v1/auth/password/reset` (204, ou 400 `INVALID_RESET_CODE`) |

L’e-mail reprend les couleurs de l’application : bandeau et pied de page vert
`#015629`, logo EMSIDrive intégré au message, code en grands chiffres dans un cadre
vert clair bordé de `#7ECC18`, puis un rappel « vous n’avez pas demandé… ? ». Une
version texte accompagne le HTML pour les messageries qui ne l’affichent pas. Le
code n’apparaît jamais dans l’objet, visible sur l’écran verrouillé. Le modèle se
trouve dans `backend/src/main/resources/mail/code.html` avec `logo.jpg` ; il sert aussi
à la confirmation d’adresse de l’inscription, avec un titre et un texte adaptés.
La migration **V31** crée la table `password_reset_codes`.

#### Lire les e-mails en local avec Mailpit

Sans configuration, `docker compose up -d` (lancé aussi par
`scripts\start-backend.ps1`) démarre **Mailpit** à côté de PostgreSQL. Le profil
`dev` lui envoie les e-mails : ouvrir [la boîte Mailpit](http://localhost:8025)
pour lire le code. Aucun e-mail ne quitte le poste. Sur l’émulateur Android, l’API
reste `http://10.0.2.2:8081`.

#### Envoyer de vrais e-mails avec votre propre SMTP (Brevo)

Chaque développeur utilise **son propre compte** ; la clé SMTP ne doit jamais être
partagée ni committée. Brevo offre 300 e-mails par jour gratuitement.

1. Créer un compte sur [Brevo](https://www.brevo.com).
2. Ouvrir [Clés SMTP](https://app.brevo.com/settings/keys/smtp) (menu du compte,
   **SMTP & API → SMTP**). Noter le **Login** affiché (forme `xxxx@smtp-brevo.com`,
   différent de l’adresse du compte), puis **Générer une nouvelle clé SMTP**. La clé
   n’est affichée qu’une fois.
3. Vérifier l’adresse d’expédition dans [Expéditeurs](https://app.brevo.com/senders)
   (**Senders, Domains & Dedicated IPs → Senders**) : **Add sender**, puis cliquer le
   lien de confirmation reçu. Brevo refuse tout expéditeur non vérifié.
4. Autoriser l’IP du poste dans
   [IP autorisées](https://app.brevo.com/security/authorised_ips) (voir le dépannage).
5. Créer `backend/.env.local` (ignoré par Git, chargé au démarrage du backend) :

```properties
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_FROM=EMSIDrive <adresse-verifiee@example.com>
spring.mail.username=votre-login@smtp-brevo.com
spring.mail.password=votre-cle-smtp
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

6. Redémarrer le backend (arrêter le processus Java du port 8081, puis
   `.\scripts\start-backend.ps1 -Port 8081`). Ces valeurs remplacent Mailpit.

Tout fournisseur SMTP fonctionne de la même façon (Gmail avec un mot de passe
d’application, Mailjet…) : seuls l’hôte, le port et les identifiants changent.
En production, utiliser les variables d’environnement `SPRING_MAIL_HOST`,
`SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `MAIL_FROM` et
`SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH=true`,
`SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE=true`. Sans hôte SMTP, les
demandes sont acceptées mais aucun e-mail n’est envoyé, et un avertissement
apparaît dans les journaux.

#### Dépannage des e-mails

L’envoi a lieu en arrière-plan : l’API répond 202 même si l’e-mail échoue. Chercher
la cause dans le journal du backend :

```powershell
Select-String -Path "$env:TEMP\emsidrive-api.log" -Pattern "could not be sent|Caused by" | Select-Object -Last 5
```

| Message ou symptôme | Cause | Solution |
| --- | --- | --- |
| `525 5.7.1 Unauthorized IP address` | Brevo bloque les connexions SMTP depuis une IP inconnue. | Brevo envoie un e-mail « connexion bloquée » au propriétaire du compte : cliquer **Autoriser**. Sinon, ouvrir [IP autorisées](https://app.brevo.com/security/authorised_ips) (menu du compte → **Sécurité**), **Ajouter une IP** et saisir l’IP publique du poste, obtenue avec `curl https://api.ipify.org`. Le même écran permet de désactiver le blocage par IP. |
| L’erreur 525 revient après quelques jours | L’IP publique d’une connexion domestique change au redémarrage du routeur. | Autoriser la nouvelle IP, ou désactiver le blocage par IP pour un compte de développement. |
| `535 Authentication failed` | Login ou clé SMTP incorrects. | Utiliser le **Login** de la page SMTP (pas l’adresse du compte) et une clé SMTP (`xsmtpsib-…`), pas une clé API (`xkeysib-…`). |
| `Sender ... is not valid` ou e-mail refusé | `MAIL_FROM` n’est pas un expéditeur vérifié. | Vérifier l’adresse dans [Expéditeurs](https://app.brevo.com/senders), puis redémarrer. |
| `spring.mail.host is not set` au démarrage | Aucun SMTP configuré hors profil `dev`. | Définir les variables ci-dessus. |
| Aucune erreur mais rien dans la boîte | Filtre anti-spam, ou adresse sans compte actif (le serveur ne répond rien dans ce cas, volontairement). | Regarder les **Spam**, vérifier que le compte existe et n’est pas suspendu, et respecter le délai de 60 secondes entre deux codes. |
| Rien dans Mailpit | `.env.local` redirige vers Brevo, ou le conteneur est arrêté. | Retirer `MAIL_HOST` de `.env.local` ou lancer `docker compose up -d` dans `backend/`. |

### Logo en thème clair et sombre

Les écrans de connexion, d’inscription et de code affichent le logo adapté au
thème du téléphone : `assets/images/logo.png` (fond transparent) en thème clair et
`assets/images/logo_dark.png` en thème sombre, avec « Drive » et le slogan en blanc
et un vert plus lumineux. Le choix passe par `AppAssets.logoFor(theme.brightness)`.
Ne pas réutiliser l’ancien logo sur fond blanc : il apparaît comme un rectangle
blanc en mode sombre.

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
| Administration | `npm run build` puis `npm test -- --watch=false` depuis `admin-web/`. |

### Validation du 23 novembre 2026

- `mvn test` : **175 tests sur 177** passent, dont 7 parcours PostgreSQL de
  réinitialisation du mot de passe, 7 de confirmation d’adresse à l’inscription et
  les tests de l’e-mail HTML. Les 2 échecs viennent du fuseau horaire du JDK
  (voir ci-dessous), pas du code.
- `flutter test` : **269 tests** passent (écrans mot de passe oublié, code
  d’inscription, renvoi du code, logo clair et sombre) et `flutter analyze` ne
  signale aucun problème.
- Essais réels : code de réinitialisation et code d’inscription reçus par e-mail
  via Brevo, mot de passe changé depuis l’émulateur, ancien mot de passe refusé.

#### Deux tests de planning échouent sur certains postes

Si `ScheduleIntegrationTest.matchesOnlyNearbyOffersAtTheChosenCampusAndCompatibleTimes`
et `threeDevelopmentOffersMatchThePlanAndStayBookableWithoutResettingReservations`
échouent (« expected: 2 but was: 1 », « expected: 3 but was: 0 »), comparer le
décalage de `Africa/Casablanca` côté Java et côté PostgreSQL :

```powershell
'System.out.println(java.time.ZoneId.of("Africa/Casablanca").getRules().getOffset(java.time.Instant.now()))' | jshell -q
docker exec emsidrive-postgres psql -U emsidrive -At -c "SELECT now() AT TIME ZONE 'Africa/Casablanca' - now() AT TIME ZONE 'UTC';"
```

Des résultats différents (par exemple `+01:00` contre `00:00:00`) signifient que
les données de fuseau du JDK sont anciennes : les horaires du planning sont alors
décalés d’une heure, dans les tests comme dans l’application lancée sur ce poste.
Mettre à jour le JDK, ou ses données de fuseau avec l’outil TZUpdater d’Oracle,
sans oublier le JBR d’Android Studio utilisé par `scripts\start-backend.ps1`.

### Validation du 22 novembre 2026

- `mvn test` passe avec **128 tests backend**, dont cinq parcours PostgreSQL de
  modération, de contrôle des rôles, de suspension et de confidentialité. Les tests
  couvrent aussi la file push, le bilan, les frais, les avis, les véhicules des
  offres et les soumissions concurrentes.
- `flutter test` passe avec **220 tests Flutter**, dont trois tests de signalements,
  huit tests de notifications et trois tests de gestion des véhicules, couvrant le parcours
  HTTP, la confirmation de suppression, la reprise après erreur et le changement
  de compte.
- Trois tests supplémentaires couvrent le bilan réel via HTTP, l’évaluation,
  la confirmation des frais, la reprise après erreur et la compatibilité des
  anciennes données.
- Les **20 tests ciblés** `VehicleServiceTest` et `ProfileVehicleIntegrationTest`
  passent, avec contrôle des propriétaires et persistance PostgreSQL.
- `flutter analyze` ne signale aucun problème.
- `npm run build` réussit et **11 tests Angular** passent, dont l’authentification,
  les renouvellements concurrents, les indicateurs et les formulaires de modération.
- Le projet Firebase et les paramètres locaux sont installés. L’inscription de
  l’émulateur et la réception d’un envoi FCM direct en arrière-plan sont validées.
- Un trajet de démonstration du 22 novembre est conservé dans l’historique local
  pour présenter le bilan et la répartition de 10,01 MAD. Le conducteur de test
  utilise l’API, le passager utilise l’émulateur. La position GPS de ce parcours
  est une coordonnée de test envoyée à l’API. Les capteurs de deux téléphones
  physiques restent à vérifier ensemble.

### Validation précédente de la connexion par empreinte

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
