# EMSIDrive Administration

Back-office Angular 21 LTS, TypeScript et composants standalone. Interface française
responsive, données issues du backend Spring Boot.

## Démarrage

Node 22.12 ou supérieur dans la branche 22, ou une version compatible Angular 21.
Le poste de validation utilise Node 22.17. Démarrer l’API sur 8081.

```powershell
npm ci
npm start
```

Ouvrir http://127.0.0.1:4200. Le proxy de développement relaie `/api` vers
`http://127.0.0.1:8081`. Si npm 10.9.2 échoue avec `edgesOut`, utiliser
`npx --yes npm@11 ci`.

## Accès

Le compte doit avoir le rôle ADMIN. Depuis la racine du dépôt, après inscription
du compte dans l’application, exécuter la commande suivante avec son adresse.

```powershell
.\scripts\grant-admin.ps1 -Email administrateur@emsi-edu.ma
```

Le script utilise la base de développement Docker et historise la promotion.
Sur le poste actuel, les identifiants dédiés sont dans
`%LOCALAPPDATA%\EMSIDrive\admin-login.txt`.

La session du navigateur utilise sessionStorage. Les autorisations sont vérifiées
sur le serveur à chaque requête. Les appels HTTP partagent le renouvellement des
jetons et rejettent les réponses reçues après un changement de compte.

## Rubriques

- Vue d’ensemble avec indicateurs cumulés réels.
- Utilisateurs avec recherche, fiche et suspension/réactivation motivée.
- Trajets avec filtres type, campus, date à Marrakech et état.
- Signalements avec description, références, décision et note de modération.
- Historique des actions administrateur.

Les listes sont paginées par 20. Les décisions incluent la révision lue pour
refuser une écriture obsolète. Le mobile fournit le formulaire de signalement
et son suivi dans le profil.

## Vérification

```powershell
npm run build
npm test -- --watch=false
```

Les tests couvrent les sessions étudiantes refusées, le renouvellement concurrent,
les erreurs réseau, la déconnexion et les métriques reliées à l’API. Les droits et
transactions de modération sont testés avec PostgreSQL dans `backend/`.

Le build produit `dist/admin-web/browser`. Pour déployer, servir les routes Angular
avec repli vers `index.html`, configurer le relais `/api` vers le backend et HTTPS.
Le proxy Angular décrit ici sert au développement local.

La vérification visuelle automatisée a été interrompue par l’outil Chrome. Le rendu
reste à parcourir manuellement, notamment sur écran étroit.
