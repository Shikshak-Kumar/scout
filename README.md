# Scout

Scout is a mobile-first opportunity discovery platform for students, developers, researchers, job seekers, and early-career professionals. 

The backend is architected as **independently deployable microservices** instead of a monolith:

- **API Gateway**: Public entrypoint with rate limiting, JWT validation, routing, and CORS
- **Auth Service**: User identity, JWT issuance, token refresh rotation
- **Opportunity Service**: Opportunity search, bookmark reads/writes (Postgres + Elasticsearch)
- **Ingestion Service**: Source adapters, scraper orchestration, deduplication
- **Notification Service**: Event consumption and notification matching

Each service owns its own PostgreSQL database, has a health endpoint, and runs independently in Docker. Redis and RabbitMQ provide shared caching and event pub/sub.

Scout does not seed or display invented production opportunities. Every production record must originate from a configured, permitted source and retain a verifiable source URL.

## Current implementation status

This repository currently provides the first production-oriented vertical slice:

- Material 3 Flutter interface with light and dark themes (mobile app)
- Home, Discover, Saved, Applications, and Profile navigation
- Live opportunity feed and opportunity details
- Email/password registration and JWT-based authentication
- Short-lived JWT access tokens and rotating, hashed refresh tokens
- Per-service PostgreSQL persistence (SQLAlchemy + Alembic migrations)
- Redis and RabbitMQ infrastructure for caching and event pub/sub
- GitHub official API adapter for source ingestion
- Cursor-based opportunity pagination
- Saved opportunity and bookmark persistence
- Docker Compose services for local development and testing
- Simple email/password authentication with JWT tokens

Full onboarding, Firebase Cloud Messaging, OAuth/OIDC integration, resume processing, embeddings, advanced recommendation ranking, and admin dashboard are not yet implemented.

## Repository structure

```text
scout/
├── services/
│   ├── api-gateway/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── router.py          # Public routes, auth validation, routing
│   │   │   ├── core/
│   │   │   │   └── config.py          # Gateway configuration
│   │   │   └── main.py                # FastAPI application
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   ├── auth-service/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── routes.py          # Signup, login, token refresh, verification
│   │   │   ├── infra/
│   │   │   │   ├── auth.py            # JWT token issuance and validation
│   │   │   │   └── persistence.py     # User repository and password hashing
│   │   │   ├── core/
│   │   │   │   └── config.py          # Auth service configuration
│   │   │   └── main.py
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   ├── opportunity-service/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── routes.py          # Opportunity list, detail, bookmarks
│   │   │   ├── infra/
│   │   │   │   └── repositories.py    # Opportunity and bookmark persistence
│   │   │   ├── core/
│   │   │   │   └── config.py
│   │   │   └── main.py
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   ├── ingestion-service/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── routes.py          # Ingestion endpoint
│   │   │   ├── infra/
│   │   │   │   └── broker.py          # RabbitMQ event publishing
│   │   │   ├── core/
│   │   │   │   └── config.py
│   │   │   └── main.py
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   └── notification-service/
│       ├── app/
│       │   ├── api/
│       │   │   └── routes.py          # Notification listing and preferences
│       │   ├── infra/
│       │   │   └── broker.py          # RabbitMQ event consumption
│       │   ├── core/
│       │   │   └── config.py
│       │   └── main.py
│       ├── tests/
│       ├── Dockerfile
│       └── pyproject.toml
├── mobile/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── core/                # Networking, routing, storage, theme
│   │   └── features/            # Feature-first Flutter modules
│   ├── test/
│   └── pubspec.yaml
├── init-scripts/                 # Database initialization scripts
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
cp .env.example .env
```

The default development configuration includes individual service ports and database URLs. Each microservice has its own dedicated PostgreSQL database:

```dotenv
# API Gateway (public entrypoint)
GATEWAY_PORT=8000
GATEWAY_AUTH_SERVICE_URL=http://auth-service:8001
GATEWAY_OPPORTUNITY_SERVICE_URL=http://opportunity-service:8002
GATEWAY_INGESTION_SERVICE_URL=http://ingestion-service:8003
GATEWAY_NOTIFICATION_SERVICE_URL=http://notification-service:8004

# Auth Service
APP_DATABASE_URL=postgresql+asyncpg://scout:scout@auth-db:5432/auth_service

# Opportunity Service
APP_DATABASE_URL=postgresql+asyncpg://scout:scout@opportunity-db:5432/opportunity_service
ELASTICSEARCH_URL=http://elasticsearch:9200

# Ingestion Service
APP_DATABASE_URL=postgresql+asyncpg://scout:scout@ingestion-db:5432/ingestion_service
BROKER_URL=amqp://guest:guest@rabbitmq:5672/
GITHUB_TOKEN=

# Notification Service
APP_DATABASE_URL=postgresql+asyncpg://scout:scout@notification-db:5432/notification_service
BROKER_URL=amqp://guest:guest@rabbitmq:5672/

# Shared Infrastructure
REDIS_URL=redis://redis:6379/0
LOG_LEVEL=INFO
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
```

Do not commit `.env`. It may contain database passwords, API credentials, and other sensitive values.

## Start the backend stack

Run this command from the repository root:

```bash
docker compose up --build
```

This starts all services and infrastructure:

| Service | Purpose | Local access |
|---|---|---|
| `auth-service` | User authentication and JWT issuance | Internal |
| `opportunity-service` | Opportunity search and bookmarks | Internal |
| `ingestion-service` | Source adapters and ingestion | Internal |
| `notification-service` | Notification matching and delivery | Internal |
| `api-gateway` | Public API entrypoint | `http://localhost:8000` |
| `auth-db` | Auth service PostgreSQL | Internal |
| `opportunity-db` | Opportunity service PostgreSQL | Internal |
| `ingestion-db` | Ingestion service PostgreSQL | Internal |
| `notification-db` | Notification service PostgreSQL | Internal |
| `redis` | Shared cache and session store | Internal |
| `rabbitmq` | Event message broker | `http://localhost:15672` |
| `elasticsearch` | Full-text search (optional) | `http://localhost:9200` |

The first build can take several minutes. Keep this terminal open while using Scout.

Verify each service's health from another terminal:

```bash
curl http://localhost:8000/health              # API Gateway
curl http://auth-service:8001/health           # Auth Service (internal)
curl http://opportunity-service:8002/health    # Opportunity Service (internal)
```

The Gateway health check is the public entrypoint:

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{"status":"ok","service":"api-gateway"}
```

FastAPI's interactive development documentation is available at:

- `http://localhost:8000/docs`
- `http://localhost:8000/redoc`

Stop the services with `Ctrl+C`. To stop detached services, run:

```bash
docker compose down
```

Each service uses named Docker volumes, so ordinary `docker compose down` does not erase stored records in the databases.

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
  --dart-define=API_BASE_URL=http://localhost:8000
```

Flutter prints the local web URL in the terminal. Hot reload is available while the process remains running.

If the browser origin is rejected by CORS, add the exact Flutter web origin to `CORS_ORIGINS` in `.env`, then restart the API gateway.

For a predictable web port, use:

```bash
flutter run -d chrome \
  --web-port=3000 \
  --dart-define=API_BASE_URL=http://localhost:8000
```

The default `.env.example` already permits `http://localhost:3000`.

## Run Flutter on Android

Start an Android emulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android emulators use `10.0.2.2` to access services running on the host computer. A physical device must use the Mac's local network address instead, and both devices must be reachable on the same network.

## Run Flutter on iOS

Start an iOS Simulator, then run:

```bash
cd /Users/ashmitaluthra/Documents/scout/mobile
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000
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

Stop the conflicting process, or change the gateway port mapping in `docker-compose.yml` and update your API base URL accordingly.

### Service fails to start or crashes immediately

Check the logs for all services:

```bash
docker compose logs <service-name>
```

Common issues:
- Database is not running or credentials are wrong
- RabbitMQ or Redis connectivity issues
- Missing environment variables in `.env`
- Port conflicts with other containers

### Tests fail with import errors

Ensure PYTHONPATH includes all service directories:

```bash
cd /Users/shikshakkumar/Downloads/development/scout
source .venv/bin/activate
export PYTHONPATH=services/auth-service:services/opportunity-service:services/ingestion-service:services/notification-service
pytest services/*/tests -q
```

## Security

- Passwords are hashed using PBKDF2 with 200,000 iterations and random salt.
- Access tokens are short-lived JWTs signed with RSA 2048.
- Refresh tokens are random, hashed server-side, and rotated on use.
- Mobile credentials are stored in secure storage provided by the OS.
- Backend secrets are loaded from environment variables.
- Service-to-service communication is internal only in development; production requires mTLS or private networking.
- Each service owns its database and does not access other services' data directly.
- Events flow through a message broker (RabbitMQ) for loose coupling.

## Production deployment

The Docker Compose setup is for local development. Before production:

### Infrastructure
- Use managed PostgreSQL databases or properly backed-up self-hosted instances per service.
- Use managed Redis or properly secured self-hosted Redis with authentication.
- Use managed RabbitMQ or properly configured self-hosted broker with TLS.
- Run Elasticsearch on dedicated hardware or managed service.
- Use a load balancer in front of the API Gateway.
- Put all services behind a private network or VPN.

### Deployment
- Deploy each service independently (Kubernetes, Cloud Run, ECS, etc.).
- Use container orchestration for scaling, health checks, and rolling updates.
- Implement distributed tracing and logging aggregation.
- Set up monitoring, alerting, and uptime checks for all services.
- Use TLS/HTTPS for all external communication.

### Configuration
- Load secrets from a dedicated secrets manager (AWS Secrets Manager, Vault, etc.).
- Use strong, randomly generated JWT secrets unique to the environment.
- Restrict CORS to known application origins only.
- Configure strict rate limiting on the API Gateway.
- Implement request authentication and authorization consistently.
- Set up structured logging with correlation IDs.

### Application
- Run database migrations before deploying services.
- Implement graceful shutdown and connection draining.
- Use connection pooling for database access.
- Monitor service health endpoints continuously.
- Implement circuit breakers for inter-service calls.
- Use exponential backoff for retries.

### Mobile
- Use distinct development, staging, and production API endpoints.
- Implement certificate pinning for production HTTPS connections.
- Add Android and iOS app signing certificates.
- Use Firebase Cloud Messaging for production notifications.
- Implement in-app update mechanisms.

## Adding new services

To add a new microservice to the architecture:

1. Create a new directory under `services/`:
   ```bash
   mkdir -p services/my-service/app/{api,core,infra}
   ```

2. Add `pyproject.toml` with dependencies and `app/main.py` for the FastAPI app.

3. Create the service config in `app/core/config.py` using Pydantic Settings.

4. Add routes in `app/api/` with health checks.

5. Create infrastructure (database, broker, etc.) in `app/infra/`.

6. Add tests in a `tests/` directory.

7. Create a `Dockerfile` following the pattern of existing services.

8. Add the service to `docker-compose.yml` with:
   - Environment variables
   - Port mapping
   - Database if needed
   - Health check

9. Update the API Gateway to route to the new service.

10. Update this README with the new service's purpose and port.

## License

No license has been selected yet. Add an explicit license before distributing or accepting external contributions.
