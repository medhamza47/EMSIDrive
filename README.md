# EMSIDrive

Plateforme de covoiturage pour les étudiants de l'EMSI Marrakech.

Trois composants dans un monorepo :

| Composant | Rôle | Stack |
|-----------|------|-------|
| [`backend/`](./backend) | API REST métier | Spring Boot 3.5 / Java 17 / PostgreSQL 16 |
| `mobile/` | Application étudiante (à venir) | Flutter / Dart |
| `admin-web/` | Back-office de modération (à venir) | React / TypeScript |

Les conventions de nommage, l'organisation des branches Git, le format des commits et la
définition de « terminé » sont décrits dans [CONTEXT.md](./CONTEXT.md) — c'est la référence
unique du projet.

## Démarrage rapide (API)

```bash
cd backend
docker compose up -d                                         # PostgreSQL 16 sur localhost:5433
mvn spring-boot:run -Dspring-boot.run.profiles=dev           # API sur http://localhost:8080
```

Sur Windows, un script fait les deux et attend que `/health` réponde (idempotent) :

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start-backend.ps1
```

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Sonde de disponibilité (public) |
| `GET /swagger-ui.html` | Documentation interactive |
| `POST /api/v1/auth/register` | Inscription étudiante (public) |
| `POST /api/v1/auth/login` | Connexion (public) |
| `POST /api/v1/auth/refresh` | Renouvellement du jeton (public) |
| `GET /api/v1/me` | Profil de l'utilisateur connecté |
| `PUT /api/v1/me` | Mise à jour du profil (nom, filière, année, photo) |
| `GET /api/v1/me/vehicles` | Véhicules de l'utilisateur connecté |
| `POST /api/v1/me/vehicles` | Ajout d'un véhicule (MOTO ou VOITURE) |
| `PUT /api/v1/me/vehicles/{id}` | Modification d'un de ses véhicules |
| `DELETE /api/v1/me/vehicles/{id}` | Suppression d'un de ses véhicules |

Toutes les routes `/api/v1/**` (hors `/auth/**`) exigent un en-tête
`Authorization: Bearer <accessToken>`. Dans Swagger, le bouton **Authorize** accepte
directement ce jeton.

## Démarrage rapide (mobile)

```bash
cd mobile
flutter run --dart-define-from-file=.env                     # émulateur Android
```

`mobile/.env` (ignoré par Git, modèle dans `mobile/.env.example`) porte
`API_BASE_URL` : `http://10.0.2.2:8080` pour l'émulateur, l'IP LAN de la machine
pour un téléphone physique. La valeur est **compilée dans l'APK** : changer de
cible impose un rebuild.

## Tests

```bash
cd backend
mvn clean verify
```

Les tests unitaires tournent sur H2 (`application-test.yml`), sans Docker. Les tests
d'intégration (`*IntegrationTest`) démarrent un conteneur PostgreSQL 16 jetable via
Testcontainers : Docker doit être démarré.

## Méthode

SCRUM, sprints de 2 semaines, code et commentaires en anglais, textes d'interface en français.
