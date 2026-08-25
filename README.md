# Scout

Scout is a mobile-first opportunity discovery platform for students, developers, researchers, job seekers, and early-career professionals. It consists of two separate applications:

- A Flutter client for Android, iOS, and optionally the web.
- A FastAPI backend responsible for authentication, source ingestion, normalization, storage, and opportunity APIs.

Scout does not seed or display invented production opportunities. Every production record must originate from a configured, permitted source and retain a verifiable source URL.

## Current implementation status

This repository currently provides the first production-oriented vertical slice:

- Material 3 Flutter interface with light and dark themes.
- Home, Discover, Saved, Applications, and Profile navigation.
- Live opportunity feed and opportunity details backed by the API.
- FastAPI email/password registration and login endpoints.
- Short-lived JWT access tokens and rotating, hashed refresh tokens.
- PostgreSQL persistence with the pgvector extension.
- Redis and Celery background-job infrastructure.
- Auditable raw source records separated from normalized opportunities.
- GitHub official API and RSS/Atom source adapters.
- Cursor-based opportunity pagination.
- Saved opportunity and application-status persistence.
- Docker Compose services for local development.

The Flutter authentication screens, full onboarding, OAuth, Firebase Cloud Messaging, resume processing, embeddings, advanced recommendation ranking, and admin dashboard are not yet implemented. These features require further development and, in several cases, operator-owned credentials.

## Repository structure

```text
scout/
├── backend/
│   ├── app/
│   │   ├── api/                 # FastAPI routes and authentication dependencies
│   │   ├── core/                # Environment configuration and security helpers
│   │   ├── db/                  # Async SQLAlchemy session setup
│   │   ├── ingestion/           # Source adapter contract and integrations
│   │   │   └── adapters/        # GitHub and RSS/Atom adapters
│   │   ├── models/              # PostgreSQL/SQLAlchemy models
│   │   ├── schemas/             # API request and response schemas
│   │   ├── services/            # Ingestion orchestration
│   │   ├── tasks/               # Celery workers and scheduled jobs
│   │   └── main.py              # FastAPI application entry point
│   ├── tests/
│   ├── Dockerfile
│   └── pyproject.toml
├── mobile/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── core/                # Networking, routing, storage, and theme
│   │   └── features/            # Feature-first Flutter modules
│   ├── test/
│   └── pubspec.yaml
├── docker-compose.yml
├── .env.example
└── README.md
```

## Prerequisites

Install the following software before running Scout:

- Flutter stable SDK.
- Docker Desktop for macOS, Windows, or Linux Docker Engine with Compose.
- Git.
- Chrome if running the Flutter web client.
- Xcode for iOS development on macOS.
- Android Studio and an Android SDK for Android development.

Verify the main tools:

```bash
flutter doctor
docker --version
docker compose version
```

On macOS, Docker Desktop must be open and fully started. If Docker reports that it cannot connect to the daemon, run:

```bash
open -a Docker
```

Wait until Docker Desktop reports that the engine is running, then check:

```bash
docker info
```

## Environment configuration

From the repository root, create the local environment file:

```bash
cd /Users/ashmitaluthra/Documents/scout
cp .env.example .env
```

The default development configuration is:

```dotenv
SCOUT_ENVIRONMENT=development
SCOUT_DATABASE_URL=postgresql+asyncpg://scout:scout@db:5432/scout
SCOUT_REDIS_URL=redis://redis:6379/0
SCOUT_JWT_SECRET=replace-with-at-least-32-random-characters
SCOUT_GITHUB_TOKEN=
SCOUT_ALLOWED_ORIGINS=["http://localhost:3000"]
```

Replace `SCOUT_JWT_SECRET` with a strong random value. One way to generate it is:

```bash
openssl rand -hex 32
```

Do not commit `.env`. It may contain database passwords, signing secrets, API credentials, and other sensitive values.

### GitHub token

The GitHub adapter uses GitHub's official REST API. It can make unauthenticated requests, but those requests have lower rate limits. Set `SCOUT_GITHUB_TOKEN` to an appropriate GitHub token for regular ingestion.

The token must remain on the backend. Never embed it in Flutter, JavaScript, or a public build artifact.

## Start the backend stack

Run this command from the repository root:

```bash
docker compose up --build
```

This starts:

| Service | Purpose | Local access |
|---|---|---|
| `db` | PostgreSQL 16 with pgvector | Internal Docker network |
| `redis` | Cache and Celery broker | Internal Docker network |
| `api` | FastAPI application | `http://localhost:8000` |
| `worker` | Celery ingestion worker | Internal Docker network |
| `beat` | Celery scheduled-job dispatcher | Internal Docker network |

The first build can take several minutes. Keep this terminal open while using Scout.

Verify the API from another terminal:

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{"status":"ok"}
```

FastAPI's interactive development documentation is available at:

- `http://localhost:8000/docs`
- `http://localhost:8000/redoc`

Stop the services with `Ctrl+C`. To stop detached services, run:

```bash
docker compose down
```

The database uses a named Docker volume, so ordinary `docker compose down` does not erase stored records.

## Configure opportunity sources

Scout deliberately does not create fake source records or sample opportunities. At least one real source must be registered before the ingestion worker can collect anything.

Open a PostgreSQL shell inside the database container:

```bash
docker compose exec db psql -U scout -d scout
```

### Register GitHub

Run the following SQL in `psql`:

```sql
INSERT INTO sources (
  id,
  name,
  adapter,
  base_url,
  enabled,
  authoritative,
  cursor,
  health,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'GitHub Opportunities',
  'github',
  'https://api.github.com',
  true,
  false,
  '{}'::json,
  'not_connected',
  now(),
  now()
)
ON CONFLICT (name) DO NOTHING;
```

The adapter searches GitHub issues using the official API and applies classification rules so unrelated issues are not automatically treated as opportunities.

### Register an RSS or Atom feed

Only register a feed that is publicly available and whose terms permit its use:

```sql
INSERT INTO sources (
  id,
  name,
  adapter,
  base_url,
  enabled,
  authoritative,
  cursor,
  health,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'Official Organization Feed',
  'rss',
  'https://organization.example/opportunities.xml',
  true,
  true,
  '{}'::json,
  'not_connected',
  now(),
  now()
)
ON CONFLICT (name) DO NOTHING;
```

Replace the example URL with an actual permitted RSS or Atom endpoint. Mark `authoritative` as `true` only when the feed is controlled by the organization publishing the opportunities.

Exit `psql` with:

```text
\q
```

Celery Beat schedules source synchronization every 15 minutes. To trigger the registered sources immediately during development:

```bash
docker compose exec worker celery -A app.tasks.celery_app.celery call app.tasks.ingestion.sync_all_sources
```

Inspect service logs with:

```bash
docker compose logs -f api worker beat
```

## Authentication and API usage

The opportunity API requires a valid access token.

Register a development user:

```bash
curl -X POST http://localhost:8000/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","password":"use-a-strong-password"}'
```

The response contains an access token and refresh token. Access tokens are short-lived. Refresh tokens are stored as hashes in PostgreSQL and rotated whenever they are used.

Fetch opportunities using the returned access token:

```bash
curl http://localhost:8000/v1/opportunities \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
```

Refresh a session:

```bash
curl -X POST http://localhost:8000/v1/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'
```

The current Flutter client does not yet include registration and login screens. Consequently, launching the client without first placing a valid token in secure storage results in an authentication error on the feed. Completing the Flutter authentication flow is required for a normal end-user sign-in experience.

## Run Flutter on Chrome

The initial mobile project may not contain the Flutter web runner. Add it once from the mobile directory:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter create --platforms=web .
```

Then launch Chrome:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/v1
```

Flutter prints the local web URL in the terminal. Hot reload is available while the process remains running.

If the browser origin is rejected by CORS, add the exact Flutter web origin to `SCOUT_ALLOWED_ORIGINS` in `.env`, then restart the API:

```bash
docker compose restart api
```

For a predictable web port, use:

```bash
flutter run -d chrome \
  --web-port=3000 \
  --dart-define=API_BASE_URL=http://localhost:8000/v1
```

The default `.env.example` already permits `http://localhost:3000`.

## Run Flutter on Android

Start an Android emulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1
```

Android emulators use `10.0.2.2` to access services running on the host computer. A physical device must use the Mac's local network address instead, and both devices must be reachable on the same network.

## Run Flutter on iOS

Start an iOS Simulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000/v1
```

For a physical iPhone, use the Mac's local network address and configure the required iOS networking permissions for development. Production builds must communicate with an HTTPS endpoint.

## API overview

The current API is versioned under `/v1`.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Service health check |
| `POST` | `/v1/auth/register` | Create an email/password account |
| `POST` | `/v1/auth/login` | Authenticate an existing account |
| `POST` | `/v1/auth/refresh` | Rotate a refresh token and issue a new token pair |
| `GET` | `/v1/opportunities` | Return an authenticated cursor-paginated feed |
| `GET` | `/v1/opportunities/{id}` | Return an opportunity detail record |
| `PUT` | `/v1/opportunities/{id}/saved` | Save an opportunity or update its application status |

Opportunity feed responses only contain records stored by the ingestion pipeline. A record must have a source URL before it can pass adapter validation.

## Ingestion lifecycle

Each configured source uses the following high-level process:

1. The scheduler dispatches a source synchronization job.
2. An adapter retrieves records using a permitted API or feed.
3. Original responses are stored in `raw_records` for auditing and reprocessing.
4. The adapter classifies and normalizes candidate opportunities.
5. Validation rejects records without a meaningful title, organization, or HTTPS source URL.
6. New normalized opportunities are inserted into `opportunities`.
7. Existing records are updated and their `last_seen_at` freshness timestamp advances.
8. Expiration jobs mark records whose normalized deadline has passed.

The current deduplication path uses the exact source URL. More advanced canonical URL, organization, and semantic duplicate detection remains future work.

## Run tests

### Flutter

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter analyze
flutter test
```

### Backend in a local virtual environment

```bash
cd /Users/ashmitaluthra/Documents/scout/backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e '.[test]'
python -m pytest
```

Backend adapter tests use isolated fixtures and do not populate the production database.

Alternatively, run tests in the built API container:

```bash
docker compose run --rm api sh -c "pip install '.[test]' && python -m pytest"
```

## Common problems

### `zsh: command not found: docker`

Docker is not installed or its command-line tools are unavailable. Install Docker Desktop system-wide; it is not installed inside the Scout directory.

### `Cannot connect to the Docker daemon`

Docker is installed but its engine is not running. Open Docker Desktop and wait for startup:

```bash
open -a Docker
docker info
```

### Port 8000 is already in use

Find the process or container using the port:

```bash
lsof -i :8000
docker ps
```

Stop the conflicting process, or change the API port mapping in `docker-compose.yml` and update `API_BASE_URL` accordingly.

### Flutter shows a retry button instead of opportunities

Check all of the following:

- The API health endpoint responds.
- The browser is using the correct `API_BASE_URL`.
- CORS permits the browser's exact origin.
- A valid access token exists in Flutter Secure Storage.
- At least one source is enabled and has synchronized successfully.
- The source actually returned records that passed opportunity classification.

Use these logs for backend diagnosis:

```bash
docker compose logs -f api worker beat
```

### The feed is empty

An empty feed is valid when no real opportunities have been ingested. Scout does not substitute fake cards. Inspect registered sources and recent records:

```bash
docker compose exec db psql -U scout -d scout \
  -c "SELECT name, adapter, health, last_success_at, error FROM sources;"

docker compose exec db psql -U scout -d scout \
  -c "SELECT title, organization, source_url, first_seen_at FROM opportunities ORDER BY first_seen_at DESC LIMIT 20;"
```

## Security and source policy

- Passwords are hashed using Argon2 through `pwdlib`.
- Access tokens are short-lived JWTs.
- Refresh tokens are random, hashed server-side, rotated on use, and revocable.
- Mobile credentials are stored using Flutter Secure Storage.
- Backend secrets are loaded from environment variables.
- Raw and normalized source records remain separate for auditability.
- GitHub ingestion uses GitHub's official API.
- RSS ingestion uses explicitly configured public feeds.
- Scout must not bypass authentication, CAPTCHAs, rate limits, robots restrictions, or source access controls.
- A source should only be marked authoritative when it belongs to the publishing organization.
- Production deployments must use HTTPS, a strong JWT secret, restricted CORS origins, private infrastructure, and separately managed credentials.

## Production considerations

The Compose setup is intended for local development. Before production deployment:

- Use a managed or properly backed-up PostgreSQL/pgvector database.
- Use durable Redis infrastructure with authentication and network restrictions.
- Run database migrations instead of development-time `create_all` behavior.
- Deploy API, workers, scheduler, and notification workers independently.
- Put the API behind TLS and a reverse proxy or managed load balancer.
- Restrict CORS to known application origins.
- Store secrets in a dedicated secrets manager.
- Configure structured logs, metrics, traces, uptime checks, and alerting.
- Apply per-source rate limits and monitor source health.
- Configure Firebase, email, object storage, and embedding providers separately.
- Add Android and iOS release signing and distinct development, staging, and production environments.

Production Flutter builds must never use `localhost` as their API base URL.

## Adding another source adapter

New integrations implement the `SourceAdapter` contract in `backend/app/ingestion/base.py`:

- `fetch()` retrieves permitted source records incrementally.
- `parse()` converts a raw source item into a normalized candidate or rejects it.
- `validate()` verifies required fields and safe source URLs.
- `identify()` returns the stable source identifier used for incremental ingestion.

Add the adapter implementation under `backend/app/ingestion/adapters/`, register it in `adapter_for()` in `backend/app/tasks/ingestion.py`, and add isolated mocked tests. Never add static JSON as a production source or silently replace unavailable integrations with invented records.

## License

No license has been selected yet. Add an explicit license before distributing or accepting external contributions.
