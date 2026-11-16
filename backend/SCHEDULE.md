# Emplois du temps

Le backend expose `/api/v1/schedules`, avec authentification JWT obligatoire.
Chaque compte possède au maximum un emploi du temps actif. Aucun identifiant d’un
autre utilisateur n’est accepté par ces routes.

| Méthode et chemin | Entrée / résultat |
| --- | --- |
| `POST /imports` | Multipart `file`, `group` facultatif et `revision`. Renvoie 202 avec un identifiant de travail sans attendre le modèle. |
| `GET /imports/latest` | Dernier travail/résultat du compte, récupérable après fermeture de l’application ; null si absent. |
| `GET /imports/{id}` | État et résultat éventuel du travail appartenant au compte ; 404 pour tout autre compte. |
| `DELETE /imports/{id}` | Annulation/abandon, suppression du document et du résultat. |
| `GET/PUT /travel-preferences` | Campus, point privé en ville, rayon, durée estimée et marge. |
| `GET /matches?commuteMinutes=30` | Offres réellement disponibles filtrées par lieu, campus, dates et horaires. |
| `POST /analyze` | Ancien import synchrone, conservé pour compatibilité ; le mobile utilise `/imports`. |
| `GET /current` | Emploi du temps confirmé ; `404 SCHEDULE_NOT_FOUND` si absent. |
| `PUT /current` | Enregistrement atomique du planning confirmé et de ses cours. |
| `DELETE /current` | Suppression des emplois du temps du compte ; 204. |
| `GET /suggestions?commuteMinutes=30&marginMinutes=10` | Ancien filtre sans proximité, conservé pour compatibilité. |

Exemple de corps de `PUT /current` (dates à adapter) :

```json
{
  "name": "Mon groupe",
  "source": "MANUAL",
  "revision": 0,
  "confirmed": true,
  "validFrom": "2026-09-01",
  "validUntil": "2027-01-31",
  "slots": [
    {
      "weekday": 1,
      "startTime": "08:30",
      "endTime": "10:00"
    }
  ]
}
```

`revision` vaut 0 à la création, puis la valeur renvoyée par le serveur. Une version
périmée est refusée avec 409 `SCHEDULE_CHANGED`. Sources : `MANUAL`, `IMAGE`, `PDF`
(l’ancien `AI_IMPORT` reste accepté). Jours ISO : lundi 1 à dimanche 7. De 1 à 80 cours,
horaires à la minute, fin après début, sans chevauchement. `label` et `campus` sont
facultatifs pour compatibilité avec les anciens clients ; une séance sans libellé est
enregistrée comme « Séance ». Le lieu n’est pas conservé lors de l’enregistrement.
Les dates sont obligatoires, ordonnées, avec une validité maximale d’un an.

## Analyse Gemini

L’OCR local et ses tests Tesseract ont été retirés. L’import utilise
`GeminiScheduleAnalyzer` et l’endpoint compatible Google :
`https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`.
Aucun appel à Groq n’est effectué par le parcours actif.

Créer une clé sur [Google AI Studio](https://aistudio.google.com/api-keys), puis
ajouter les variables suivantes dans `backend/.env.local` (ignoré) ou l’environnement :

```properties
GEMINI_API_KEY=votre_cle
GEMINI_MODEL=gemini-3.8-flash
GEMINI_FALLBACK_MODELS=gemini-3.5-flash-lite,gemini-3.1-flash-lite
GEMINI_ATTEMPT_SECONDS=20
```

Ne jamais placer la clé dans Flutter ou dans Git. Redémarrer le backend après
configuration. Sans clé : `SCHEDULE_AI_NOT_CONFIGURED`, sans appel réseau.
L’accès gratuit dépend du compte, du modèle et des quotas Google. Une réponse 429
donne `SCHEDULE_AI_RATE_LIMIT` ; les erreurs et réponses tronquées ne sont pas enregistrées.

Le serveur vérifie le contenu réel : JPEG/PNG jusqu’à 25 mégapixels, PDF non chiffré
de 1 à 3 pages, fichier de 8 Mo maximum. Les photos sont normalisées en PNG afin de
préserver les bordures. Les pages PDF sont rendues en images. Pour une grille détectable,
le code mesure les cellules et utilise Gemini pour leur lecture. Sinon Gemini lit le
tableau complet et fournit les en-têtes et colonnes couvertes. Les cellules doubles
prennent la fin de leur dernière colonne, pauses comprises ; les horaires explicites
ont priorité. La validation stricte refuse les identifiants inventés, clés dupliquées,
réponses tronquées et groupes ambigus. Un jour ou horaire manquant impose une correction.
Les séances complètes marquées à vérifier peuvent être confirmées globalement par
l’étudiant, sans ouvrir chaque séance. Le mobile propose les sept prochains jours
comme période explicite et modifiable pour un import sans dates ; les chevauchements
et dates invalides restent bloquants, avec un message précis.

Pour réduire la latence, Gemini reçoit toutes les cartes mesurées dans un seul appel
(au lieu d’un appel séquentiel par lot de trois jours) et utilise
`reasoning_effort=low`. Les cartes, identifiants et contrôles de durées sont conservés.
Quota, réponse indisponible, délai de 20 secondes ou JSON invalide déclenchent le modèle
de secours suivant, sans attendre la temporisation fournisseur. Trois modèles maximum,
avec Groq en deuxième position si `GROQ_API_KEY` est configurée, puis un modèle Gemini de secours.
Le modèle Groq par défaut est `qwen/qwen3.8-27b` (`GROQ_MODEL`), avec trois images maximum
par requête, raisonnement désactivé et le même budget total par tentative. Les erreurs
de fichier/groupe ambigu ne sont pas réessayées aveuglément. La durée réelle dépend de
du fournisseur et de la file d’attente ; aucun délai instantané ni zéro erreur de lecture n’est garanti.

Seuls les jours et horaires sont renvoyés, triés puis confirmés avant enregistrement.
Matières, salles, personnes et campus ne sont pas conservés dans le brouillon.
Les documents sont transmis à Google ou à Groq en secours, ce qui est annoncé dans le mobile. Le document
normalisé est conservé temporairement en PostgreSQL pendant l’attente/le traitement,
puis supprimé à la réussite, à l’échec ou à l’annulation. Les imports et résultats non
consommés sont purgés après 24 heures par nettoyage périodique. Ni le contenu du document
ni la clé ne sont journalisés. Le modèle reste
hebdomadaire : vacances, exceptions datées et semaines A/B ne sont pas modélisées.

V23 ajoute une file durable : une analyse active par compte, deux workers par instance,
50 travaux actifs maximum dans la file commune. Les baux PostgreSQL sont renouvelés
par les workers ; un bail expiré est repris après panne. Les résultats tardifs doivent
présenter le bon jeton de bail. L’annulation purge le contenu et interrompt le worker
local. Un résultat identique est réutilisé pendant 24 h uniquement pour le même compte,
groupe et révision. La sauvegarde avec `analysisJobId` consomme le résultat dans la
transaction du planning. Les quotas Google restent indépendants de cette file.

Le mobile interroge l’état toutes les trois secondes pendant le travail et récupère
le dernier import à son retour. Planning et Profil affichent le résultat prêt à confirmer.
Le système ne dépend pas d’une connexion HTTP longue et n’envoie pas de notification
système hors application. La lecture d’un résultat ne l’enregistre jamais automatiquement.

## Suggestions

Fuseau de calcul : `Africa/Casablanca`. Fenêtre : les 7 prochains jours, à l’intérieur
de la période confirmée. `/matches` exige des préférences de trajet complètes : campus,
point personnel dans le périmètre Marrakech, rayon de 100 à 10 000 m, durée de 5 à 180 min
et marge de 0 à 60 min. Le point n’est accessible qu’au propriétaire du compte.
Les offres doivent rejoindre/quitter exactement ce campus et leur point en ville doit
être à l’intérieur du rayon (haversine, distance à vol d’oiseau, pas un détour routier).
La requête SQL filtre avant de limiter à 50 résultats, ordonnés par date, distance et heure.
La réponse contient seulement la fiche publique du trajet et la distance, pas les
coordonnées privées précises du conducteur. Le mobile ouvre
ces offres après « Enregistrer et réserver un trajet ». La réservation reste une action
explicite sur une offre disponible. Le planning est consultable et gérable depuis le profil.

Seuls les premiers et derniers cours servent au trajet aller
et retour. Pour l’aller, le départ précède le premier cours de `commuteMinutes +
marginMinutes` à cette durée + 60 minutes. Pour le retour, il suit le dernier cours de
0 à 60 minutes. Le mobile calcule désormais un itinéraire OSRM depuis le point choisi
vers le campus et sauvegarde sa durée estimée dans ces préférences. En cas d’échec
OSRM, la durée manuelle est affichée et modifiable. Le matching reste un calcul
géographique et temporel, sans garantie d’arrivée ni données de circulation.
Le lieu de rendez-vous doit être vérifié dans l’offre avant réservation.

Les offres complètes, expirées, du compte lui-même, de comptes désactivés et déjà
réservées par l’étudiant sont exclues. Réservation et chat utilisent les routes
marketplace existantes avec leur contrôle de disponibilité transactionnel. Les
suggestions n’inventent ni scores de compatibilité ni conducteurs.

### Offres de développement

`POST /api/v1/schedules/demo-rides`, authentifié et présent uniquement avec le profil
`dev`, ajoute trois offres de test pour le compte demandeur après confirmation du
planning et choix du campus/point. Elles sont proches du point et alignées sur le
prochain jour de présence dans les sept jours. Les conducteurs portent TEST et des
comptes sans mot de passe connu. Les identifiants sont stables par compte ; les offres
déjà réservées ne sont ni déplacées ni réapprovisionnées. Aucun endpoint de fixture
n’est enregistré dans les autres profils. Le bouton mobile n’apparaît qu’en debug.

Les réponses d’analyse peuvent inclure les en-têtes particuliers d’un jour :
`dayColumns` en format compact global ou `rowColumns` en transcription des cartes.
Ces en-têtes priment sur les en-têtes communs sans modifier l’étendue mesurée des
cellules. Une séance du vendredi commençant entre 12 h et 15 h reçoit un avertissement
et demande vérification ; le serveur ne déplace pas les horaires par règle nationale.

## Validation

`mvn test` avec Docker couvre l’authentification, l’isolation des comptes,
l’enregistrement, les révisions, la suppression et les suggestions PostgreSQL.
`GeminiScheduleAnalyzerTest` simule localement l’API Google : image, autorisation,
jours/horaires uniquement, cellules doubles, clé absente et quota atteint.
Les tests de grille et de parsing conservent leurs fixtures de régression.
Aucun test automatisé n’envoie de document à Google ; un essai réel nécessite une clé.

Les tests d’intégration couvrent aussi la réponse 202 avant fin d’analyse, la déduplication,
l’isolation des résultats entre comptes, la purge du document, la consommation après
sauvegarde, l’annulation et la reprise d’un bail expiré. Les tests de matching excluent
les offres lointaines, le mauvais campus, les horaires incompatibles et les places déjà
réservées. Les tests mobiles vérifient le résumé arrivée/départ, la reprise depuis Planning
et l’obligation de sélectionner un point avant une recherche géographique.

V21 désactive les anciens imports sans dates/campus confirmés. Elle conserve ces
lignes mais empêche leur utilisation dans les suggestions. Le planning importé doit
être confirmé via le nouveau parcours.
