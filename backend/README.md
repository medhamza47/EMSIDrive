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
| `GET /api/v1/me` | Read the authenticated user's profile |
| `PUT /api/v1/me` | Update name, phone, filière, academic year and photo |
| `GET /api/v1/me/vehicles` | List the authenticated user's vehicles |
| `POST /api/v1/me/vehicles` | Add a vehicle (201) |
| `PUT /api/v1/me/vehicles/{id}` | Update one of the caller's vehicles |
| `DELETE /api/v1/me/vehicles/{id}` | Delete one of the caller's vehicles (204) |

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
field validation failures, a `details` array of `{ "field", "message" }` entries.

| Code | HTTP | Meaning |
|------|------|---------|
| `VALIDATION_ERROR` | 400 | Bean Validation rejected the payload |
| `MALFORMED_REQUEST_BODY` | 400 | Body is unreadable or a field has the wrong type |
| `INVALID_PARAMETER` | 400 | A path or query parameter is malformed (e.g. not a UUID) |
| `EMAIL_DOMAIN_NOT_ALLOWED` | 400 | Registration domain is not an allowed student domain |
| `INVALID_CREDENTIALS` | 401 | Wrong email or password |
| `INVALID_REFRESH_TOKEN` | 401 | Refresh token unknown, expired or already rotated |
| `UNAUTHORIZED` | 401 | Missing or invalid bearer token on a protected route |
| `ACCOUNT_DISABLED` | 403 | Account has been disabled |
| `USER_NOT_FOUND` | 404 | The authenticated user no longer exists |
| `VEHICLE_NOT_FOUND` | 404 | Vehicle missing, or owned by somebody else |
| `EMAIL_ALREADY_USED` | 409 | Email already registered |

## Profile and vehicles

All `/api/v1/me/**` routes require a bearer token and only ever act on the caller's own data.

- `GET /api/v1/me` returns `id`, `email`, `fullName`, `phoneNumber`, `filiere`, `academicYear`,
  `photoUrl`, `role`, `enabled`, `createdAt`, `updatedAt`.
- `PUT /api/v1/me` accepts `fullName` (required, ≤ 120), `phoneNumber` (optional,
  `^\+?[0-9]{9,20}$`), `filiere` (≤ 60), `academicYear` (≤ 20) and `photoUrl` (optional, http(s)
  URL, ≤ 500). Blank strings are stored as `null`.
- `POST /api/v1/me/vehicles` accepts `type` (`MOTO` or `VOITURE`), `brand`, `model`, `color` and
  `seats` (1–8). The list is always scoped to the caller.
- Targeting a vehicle that belongs to another user answers `404 VEHICLE_NOT_FOUND` rather than
  `403`, so the API never reveals that the resource exists.

Swagger UI exposes an `Authorize` button backed by the `bearerAuth` scheme: paste the `accessToken`
returned by `/api/v1/auth/login`.

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

`AuthIntegrationTest` and `ProfileVehicleIntegrationTest` run against a real PostgreSQL 16 container
(`postgres:16-alpine`) through Testcontainers, with the full Flyway migration chain and
`ddl-auto: validate`, so they need a running Docker daemon. The whole suite is 70 tests.

## Module layout

Code is organised by business module: `auth`, `user`, `vehicle`, `ride`, `booking`, `tracking`, `fuel`, `rating`, `schedule`, `matching`, `notification`, `admin`.
Each module contains `controller`, `service`, `repository`, `entity`, `dto` and `mapper` packages.
Cross-cutting code lives in `common` (web, exception) and `config`.
