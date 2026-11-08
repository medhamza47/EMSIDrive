# Emplois du temps

Le backend expose `/api/v1/schedules`, avec authentification JWT obligatoire.
Chaque compte possède au maximum un emploi du temps actif. Aucun identifiant d’un
autre utilisateur n’est accepté par ces routes.

| Méthode et chemin | Entrée / résultat |
| --- | --- |
| `POST /analyze` | Multipart `file` + `group` facultatif (120 caractères). Renvoie un brouillon de cours et des avertissements, sans enregistrement automatique. |
| `GET /current` | Emploi du temps confirmé ; `404 SCHEDULE_NOT_FOUND` si absent. |
| `PUT /current` | Enregistrement atomique du planning confirmé et de ses cours. |
| `DELETE /current` | Suppression des emplois du temps du compte ; 204. |
| `GET /suggestions?commuteMinutes=30&marginMinutes=10` | Offres réellement publiées, disponibles et compatibles avec le planning. |

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
      "label": "ERP",
      "location": "LI8",
      "weekday": 1,
      "startTime": "08:30",
      "endTime": "10:00",
      "campus": "CENTRE"
    }
  ]
}
```

`revision` vaut 0 à la création, puis la valeur renvoyée par le serveur. Une version
périmée est refusée avec 409 `SCHEDULE_CHANGED`. Sources : `MANUAL`, `IMAGE`, `PDF`
(l’ancien `AI_IMPORT` reste accepté). Jours ISO : lundi 1 à dimanche 7. De 1 à 80 cours,
campus `CENTRE` ou `TARGA`, horaires à la minute, fin après début, sans chevauchement.
Les dates sont obligatoires, ordonnées, avec une validité maximale d’un an.

## Analyse Groq

Copier `.env.example` vers `.env.local`, renseigner la clé puis démarrer depuis
`backend/`. Une variable d’environnement `GROQ_API_KEY` est aussi acceptée et prioritaire.
Le modèle de vision est configurable avec `GROQ_MODEL` ; valeur testée : `qwen/qwen3.8-27b`.
Le secret ne sort jamais vers Flutter et n’est pas ajouté aux messages d’erreur.

Le serveur contrôle le contenu réel du fichier, pas seulement son extension. Limites :
8 Mo, JPEG/PNG jusqu’à 25 mégapixels, PDF non chiffré de 1 à 3 pages. PDFBox rend les pages,
les images sont redimensionnées à 2000 pixels maximum sur le grand côté. Les photos
sont réencodées en PNG sans perte supplémentaire, pour conserver les traits fins et
supprimer les métadonnées ; les pages PDF sont rendues en JPEG. Délai global pour la
lecture des cellules : 75 secondes. Un seul nouvel essai après 429 est permis lorsque
`Retry-After` indique au maximum 20 secondes et que le délai global le permet. Les images restent
temporaires ; seuls les cours confirmés sont conservés en base.

Pour une photo contenant une grille exploitable, le serveur détecte d’abord les
bordures horizontales et verticales dans les pixels, corrige l’inclinaison des lignes
et découpe chaque cellule physique en une carte agrandie avec un identifiant opaque.
Il regroupe au maximum trois journées par appel Groq. Le modèle transcrit les textes,
les jours et les en-têtes ; les étendues des cellules viennent de la géométrie mesurée,
et non des durées proposées par le modèle. Les identifiants manquants ou inventés,
les clés JSON dupliquées et les en-têtes incohérents entre lots sont refusés.

Pour les documents sans grille détectable ou plusieurs pages, la lecture globale reste
disponible avec confirmation des incertitudes. Le modèle extrait les en-têtes horaires et les indices de première/dernière colonne
couverts par chaque cellule (`timeColumns`, `timeEvidence`). Le serveur recalcule les
bornes complètes d’une cellule fusionnée : début de sa première colonne, fin de sa
dernière colonne, avec conservation des pauses. Il ne présume pas une durée fixe de
90 ou 180 minutes. Les horaires explicitement inscrits dans un cours restent
prioritaires. Une limite de cellule incertaine laisse la fin vide et impose une
correction, plutôt que de tronquer une séance de trois heures à sa première moitié.
Deux cellules réellement séparées ne sont pas fusionnées sur la seule base du titre.
Les
valeurs inconnues restent nulles ; `needsReview` impose une correction dans Flutter.
Plusieurs groupes non identifiables produisent `SCHEDULE_AMBIGUOUS`. Une réponse JSON
invalide ou tronquée est refusée. Aucune IA ne garantit une extraction parfaite : une
photo floue, recadrée trop court, ou un planning alterné nécessite une vérification
humaine. Le modèle stocke un planning hebdomadaire ; il ne modélise pas les vacances,
exceptions datées ou semaines A/B. Choisir une période appropriée et modifier les cours
si nécessaire.

Protection locale : une analyse simultanée par compte, deux pour l’instance, trois
tentatives/minute et trente/jour/compte. Ces compteurs sont en mémoire et remis à zéro
au redémarrage. Pour plusieurs instances, utiliser un limiteur partagé. Les quotas
Groq restent indépendants et peuvent retourner 429 même sous ces limites.

## Suggestions

Fuseau de calcul : `Africa/Casablanca`. Fenêtre : les 7 prochains jours, à l’intérieur
de la période confirmée. Seuls les premiers et derniers cours servent au trajet aller
et retour. Pour l’aller, le départ précède le premier cours de `commuteMinutes +
marginMinutes` à cette durée + 60 minutes. Pour le retour, il suit le dernier cours de
0 à 60 minutes. L’estimation ne constitue pas un calcul d’itinéraire ou une garantie
d’arrivée. Le lieu de rendez-vous doit être vérifié dans l’offre avant réservation.

Les offres complètes, expirées, du compte lui-même, de comptes désactivés et déjà
réservées par l’étudiant sont exclues. Réservation et chat utilisent les routes
marketplace existantes avec leur contrôle de disponibilité transactionnel. Les
suggestions n’inventent ni scores de compatibilité ni conducteurs.

## Validation

`mvn test` avec Docker couvre parsing fournisseur, contrôle des fichiers, validation
des cours, JWT, isolation des comptes, révisions, enregistrement, suppression et
sélection de vraies offres. Aucun test automatisé ne contacte Groq : le fournisseur
est simulé. `ScheduleDocumentReaderTest` produit `target/timetable-smoke.pdf`, un
document de contrôle utilisable pour un essai manuel réel dans l’app.

V21 désactive les anciens imports sans dates/campus confirmés. Elle conserve ces
lignes mais empêche leur utilisation dans les suggestions. Le planning importé doit
être confirmé via le nouveau parcours.
