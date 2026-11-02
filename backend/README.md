# EMSIDrive API

REST API for **EMSIDrive**, the carpooling platform for EMSI Marrakech students.

Spring Boot 3.5 / Java 17 / PostgreSQL 16.

Project-wide conventions (naming, Git branches, commit format) are described in [../CONTEXT.md](../CONTEXT.md).

## Prerequisites

- JDK 17 or newer
- Maven 3.9+
- Docker (for the local PostgreSQL instance)

## Getting started

```bash
# 1. Start PostgreSQL
docker compose up -d

# 2. Run the API with the dev profile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

The API is then available on <http://localhost:8080>.

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Liveness probe, public |
| `GET /v3/api-docs` | OpenAPI document |
| `GET /swagger-ui.html` | Swagger UI |

## Database

Flyway migrations live in `src/main/resources/db/migration` and are applied on startup.
Hibernate runs with `ddl-auto: validate`, so every entity must match a migration.

Default local credentials (overridable through environment variables):

| Variable | Default |
|----------|---------|
| `DB_URL` | `jdbc:postgresql://localhost:5433/emsidrive` |
| `DB_USERNAME` | `emsidrive` |
| `DB_PASSWORD` | `emsidrive` |
| `SERVER_PORT` | `8080` |

## Tests

```bash
mvn clean verify
```

Tests run against an in-memory H2 database (`src/test/resources/application-test.yml`), with Flyway disabled, so no Docker daemon is required.

## Module layout

Code is organised by business module: `auth`, `user`, `vehicle`, `ride`, `booking`, `tracking`, `fuel`, `rating`, `schedule`, `matching`, `notification`, `admin`.
Each module contains `controller`, `service`, `repository`, `entity`, `dto` and `mapper` packages.
Cross-cutting code lives in `common` (web, exception) and `config`.
