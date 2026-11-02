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
| `POST /api/v1/auth/register` | Create a student account, returns a token pair (201) |
| `POST /api/v1/auth/login` | Authenticate with email and password |
| `POST /api/v1/auth/refresh` | Exchange a refresh token for a new token pair |

## Authentication

Every successful call on `/api/v1/auth/*` returns an access token and a refresh token:

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "user": {
    "id": "3f1c8a1e-0000-4000-8000-000000000000",
    "email": "sara.elidrissi@emsi-edu.ma",
    "fullName": "Sara El Idrissi",
    "phoneNumber": "+212612345678",
    "role": "STUDENT",
    "enabled": true
  }
}
```

- Access tokens are short lived (`PT15M` by default) and sent in the `Authorization` header as a
  bearer credential.
- Refresh tokens are persisted server side (only their SHA-256 hash is stored) and rotated on every
  `/auth/refresh`; the presented token is revoked immediately, so it cannot be replayed.
- Only two roles exist: `STUDENT` (public registration) and `ADMIN` (provisioned server side).
- Registration is restricted to the configured student domains.

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | development placeholder | HMAC-SHA256 key, at least 32 bytes; required in production |
| `JWT_ACCESS_TOKEN_TTL` | `PT15M` | Access token lifetime |
| `JWT_REFRESH_TOKEN_TTL` | `P7D` | Refresh token lifetime |
| `STUDENT_EMAIL_DOMAINS` | `emsi-edu.ma` | Comma separated allowed registration domains |

Error payloads follow the `ApiError` contract: `timestamp`, `status`, `code`, `message` and, for
field validation failures, a `details` array. Authentication codes are `INVALID_CREDENTIALS`,
`ACCOUNT_DISABLED`, `INVALID_REFRESH_TOKEN`, `EMAIL_ALREADY_USED` and `EMAIL_DOMAIN_NOT_ALLOWED`.

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

Unit and slice tests (`*Test`) run against an in-memory H2 database
(`src/test/resources/application-test.yml`), with Flyway disabled, so no Docker daemon is required.

`AuthIntegrationTest` runs against a real PostgreSQL 16 container (`postgres:16-alpine`) through
Testcontainers, with the full Flyway migration chain and `ddl-auto: validate`, so it needs a running
Docker daemon. The whole suite is 48 tests.

## Module layout

Code is organised by business module: `auth`, `user`, `vehicle`, `ride`, `booking`, `tracking`, `fuel`, `rating`, `schedule`, `matching`, `notification`, `admin`.
Each module contains `controller`, `service`, `repository`, `entity`, `dto` and `mapper` packages.
Cross-cutting code lives in `common` (web, exception) and `config`.
