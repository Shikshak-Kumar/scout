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

The Flutter client uses Keycloak for OAuth/OIDC authentication, with Google configured as a Keycloak identity provider. Full onboarding, Firebase Cloud Messaging, resume processing, embeddings, advanced recommendation ranking, and admin dashboard are not yet implemented. These features require further development and, in several cases, operator-owned credentials.

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
SCOUT_KEYCLOAK_ISSUER=http://localhost:8080/realms/scout
SCOUT_KEYCLOAK_JWKS_URL=http://keycloak:8080/realms/scout/protocol/openid-connect/certs
```

Replace `SCOUT_JWT_SECRET` with a strong random value. One way to generate it is:

```bash
openssl rand -hex 32
```

Do not commit `.env`. It may contain database passwords, signing secrets, API credentials, and other sensitive values.

### Google sign-in through Keycloak

The mobile app starts from Scout's own login screen. When the user taps Google, the app sends an OIDC login request to Keycloak with `kc_idp_hint=google`, so Keycloak immediately forwards the user to Google instead of showing Keycloak's own username/password page. Keycloak still remains the auth manager: it brokers Google login, issues the app tokens, and FastAPI verifies those Keycloak tokens.

On mobile, this secure OIDC flow opens a system browser, Chrome Custom Tab, or Safari auth session. That is expected for a Keycloak-brokered login. Apps that show a more native Google account popup are usually using Google's mobile SDK directly, without Keycloak as the broker.

In Keycloak admin, configure:

- Realm: `scout`
- Public client: `scout-mobile`
- Client redirect URI: `scout://oauthredirect`
- Web redirect URI, if using Flutter web: your local web app origin
- Identity provider: Google, alias `google`

Run Flutter with URLs that the device can actually reach:

```bash
cd mobile
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/v1 \
  --dart-define=KEYCLOAK_ISSUER=http://YOUR_COMPUTER_LAN_IP:8080/realms/scout
```

For a physical phone, do not use `localhost` in `KEYCLOAK_ISSUER` or `API_BASE_URL`. On a phone, `localhost` points to the phone itself, not your development machine. Use your computer's LAN IP for local testing, or use a real HTTPS domain in production. Set `SCOUT_KEYCLOAK_ISSUER` in the backend `.env` to the same issuer URL that the app uses.

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
| `keycloak` | OAuth/OIDC identity broker and auth manager | `http://localhost:8080` |
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

## Data accuracy and sources

Scout's data quality depends entirely on the sources you configure. Each opportunity stored in Scout retains a `source_url` (where it was found) and an optional `application_url` (where to actually apply). 

**Common data issues:**

- **404 on "Apply on official site"**: This happens when the RSS feed or source does not provide a direct link to the opportunity's application page. In this case, click "View source link" to see the original announcement and locate the real application URL manually.
- **404 on "View source link"**: The feed URL itself is broken or no longer accessible. Check that the source URL in the database is correct and the feed is still being updated.
- **Missing application URLs**: RSS and general web sources often only provide announcement links, not direct application links. GitHub sources are better because they link directly to the issue/discussion where you can apply.

**To add more sources:** 

Open a PostgreSQL shell and insert additional sources:

```bash
docker compose exec db psql -U scout -d scout
```

Example: Add Google Summer of Code:

```sql
INSERT INTO sources (
  id, name, adapter, base_url, enabled, authoritative, cursor, health, created_at, updated_at
) VALUES (
  gen_random_uuid(),
  'Google Summer of Code',
  'rss',
  'https://summerofcode.withgoogle.com/feed',
  true,
  true,
  '{}'::json,
  'not_connected',
  now(),
  now()
)
ON CONFLICT (name) DO NOTHING;
```

**Recommended official sources:**
- GitHub Issues with opportunity keywords (already configured)
- Google Summer of Code RSS
- MLH (Major League Hacking) feeds
- University career office RSS feeds
- Professional organization opportunity feeds (IEEE, ACM, etc.)

For the best data quality, prioritize **authoritative sources** (set `authoritative=true`) that publish opportunities directly, rather than aggregators that repost from others.

## No-auth local API usage

Authentication is disabled for local development. The backend automatically creates or reuses a local dev user and all endpoints work without any Authorization header or token.

### Quick health check

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{"status":"ok"}
```

### Auth endpoints

```bash
curl http://localhost:8000/v1/auth/me
curl -X PATCH http://localhost:8000/v1/auth/me \
  -H 'Content-Type: application/json' \
  -d '{"profile":{"name":"Local Developer","role":"tester"}}'
```

### Opportunities feed

```bash
curl 'http://localhost:8000/v1/opportunities?limit=5'
curl 'http://localhost:8000/v1/opportunities?limit=5&q=internship'
curl 'http://localhost:8000/v1/opportunities?limit=5&category=internship'
curl 'http://localhost:8000/v1/opportunities?limit=5&cursor=' 
```

### Opportunity detail

```bash
curl 'http://localhost:8000/v1/opportunities/00000000-0000-0000-0000-000000000000'
```

If you already have a valid opportunity UUID, replace the placeholder above with it.

### Saved opportunities

```bash
curl http://localhost:8000/v1/opportunities/saved
curl http://localhost:8000/v1/opportunities/applications
```

### Save or update a saved item

```bash
curl -X PUT http://localhost:8000/v1/opportunities/<opportunity_id>/saved \
  -H 'Content-Type: application/json' \
  -d '{
    "status": "saved",
    "notes": "Interested in this role",
    "application_date": null,
    "interview_date": null
  }'
```

### Update an application status

```bash
curl -X PUT http://localhost:8000/v1/opportunities/<opportunity_id>/saved \
  -H 'Content-Type: application/json' \
  -d '{
    "status": "applied",
    "notes": "Submitted application",
    "application_date": "2026-08-30T12:00:00Z",
    "interview_date": null
  }'
```

The backend uses the local dev user automatically, so you do not need a token or Authorization header for these requests.

## Run Flutter on Chrome

The initial mobile project may not contain the Flutter web runner. Add it once from the mobile directory:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter create --platforms=web .
```

Then launch Chrome:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/v1 \
  --dart-define=KEYCLOAK_ISSUER=http://localhost:8080/realms/scout
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
  --dart-define=API_BASE_URL=http://localhost:8000/v1 \
  --dart-define=KEYCLOAK_ISSUER=http://localhost:8080/realms/scout
```

The default `.env.example` already permits `http://localhost:3000`.

## Run Flutter on Android

Start an Android emulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1 \
  --dart-define=KEYCLOAK_ISSUER=http://10.0.2.2:8080/realms/scout
```

Android emulators use `10.0.2.2` to access services running on the host computer. A physical device must use the Mac's local network address instead, and both devices must be reachable on the same network. When you change `KEYCLOAK_ISSUER`, set backend `SCOUT_KEYCLOAK_ISSUER` to the same issuer value before restarting the API.

## Run Flutter on iOS

Start an iOS Simulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000/v1 \
  --dart-define=KEYCLOAK_ISSUER=http://localhost:8080/realms/scout
```

For a physical iPhone, use the Mac's local network address and configure the required iOS networking permissions for development. Production builds must communicate with an HTTPS endpoint.

## API overview

The current API is versioned under `/v1`.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Service health check |
| `GET` | `/v1/auth/me` | Return the local dev profile used for testing |
| `PATCH` | `/v1/auth/me` | Update the current dev profile |
| `GET` | `/v1/opportunities` | Return a cursor-paginated opportunity feed |
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
