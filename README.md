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

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Sonde de disponibilité (public) |
| `GET /swagger-ui.html` | Documentation interactive |

## Tests

```bash
cd backend
mvn clean verify
```

Les tests tournent sur H2 (`application-test.yml`), sans Docker.

## Méthode

SCRUM, sprints de 2 semaines, code et commentaires en anglais, textes d'interface en français.
