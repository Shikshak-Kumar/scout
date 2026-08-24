# Scout

Scout is a mobile-first opportunity discovery platform. This repository contains a Flutter client and a separate FastAPI ingestion/API backend. Production paths contain no sample opportunities: records enter through configured, permitted source adapters and retain their source URL.

## Run locally

1. Copy `.env.example` to `.env` and replace `SCOUT_JWT_SECRET`. A GitHub token is optional but strongly recommended for higher API limits.
2. Start PostgreSQL/pgvector, Redis, the API, Celery worker, and scheduler:
   `docker compose up --build`
3. Register sources in the `sources` table. Use adapter `github` with `https://api.github.com`, or adapter `rss` with the exact permitted RSS/Atom URL. Missing credentials are represented by source health; Scout never substitutes fixtures.
4. Start Flutter with an environment-specific backend:
   `cd mobile && flutter run --dart-define=API_BASE_URL=http://localhost:8000/v1`

For Android emulator use `http://10.0.2.2:8000/v1`. Staging and production release commands must provide their HTTPS API URL; production must never use localhost.

## Architecture

- `backend/app/ingestion`: audited adapter contract and GitHub/RSS implementations
- `backend/app/services`: raw-record persistence and normalized upsert pipeline
- `backend/app/tasks`: isolated scheduled workers with retry/backoff
- `backend/app/api`: versioned authenticated cursor APIs
- `mobile/lib/core`: routing, network/token handling, storage, and theming
- `mobile/lib/features`: feature-first presentation modules

The current vertical slice is deployable infrastructure plus authenticated opportunity feed, detail, and save APIs. OAuth, FCM credentials, object storage, embedding provider, admin UI, full onboarding, and advanced ranking require operator-owned external configuration and are intentionally not faked.

## Security and source policy

Passwords use Argon2. Access tokens are short-lived; refresh tokens are hashed, rotated, and revocable. Mobile tokens use secure storage. Secrets stay in environment variables. GitHub uses its official API and RSS uses publisher feeds; adapters do not bypass authentication, CAPTCHA, robots restrictions, or access controls.

## Tests

`cd backend && python -m pytest`

`cd mobile && flutter test`

