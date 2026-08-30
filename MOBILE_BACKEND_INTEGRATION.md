# Mobile-Backend Integration Guide

## Overview
The Scout Flutter mobile app is now correctly configured to connect to the new microservice backend.

## API Base URL Configuration

### Default (Localhost)
```bash
# Mobile app default:
http://localhost:8000
```

### Running the Mobile App

**Chrome/Web:**
```bash
cd mobile
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000
```

**Android Emulator:**
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**iOS Simulator:**
```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000
```

**Physical Android Device (replace `YOUR_IP` with your computer's LAN IP):**
```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000
```

**Physical iPhone (replace `YOUR_IP` with your computer's LAN IP):**
```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000
```

## API Endpoints

All endpoints are accessible via the **API Gateway** on port **8000**:

### Authentication
- `POST /auth/signup` - Register with email/password
- `POST /auth/login` - Login with email/password
- `POST /auth/refresh` - Refresh access token
- `GET /auth/me` - Get current user profile
- `PATCH /auth/me` - Update user profile

### Opportunities
- `GET /opportunities` - List all opportunities (with query params: `q`, `category`)
- `GET /opportunities/{id}` - Get single opportunity detail
- `GET /opportunities/saved` - Get user's saved opportunities
- `GET /opportunities/applications` - Get user's applications
- `PUT /opportunities/{id}/saved` - Save/update opportunity status

### Bookmarks
- `GET /bookmarks` - List user's bookmarks

## Example API Calls

### Signup (Register)
```bash
curl -X POST http://localhost:8000/auth/signup \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "user@example.com",
    "password": "secret123"
  }'
```

**Response:**
```json
{
  "status": "ok",
  "service": "auth-service",
  "action": "signup",
  "email": "user@example.com"
}
```

### Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "user@example.com",
    "password": "secret123"
  }'
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer"
}
```

### Get Opportunities (Requires Token)
```bash
curl -H "Authorization: Bearer <ACCESS_TOKEN>" \
  http://localhost:8000/opportunities
```

**Response:**
```json
{
  "items": [
    {
      "id": "...",
      "title": "...",
      "organization": "...",
      ...
    }
  ]
}
```

### Get User Profile (Requires Token)
```bash
curl -H "Authorization: Bearer <ACCESS_TOKEN>" \
  http://localhost:8000/auth/me
```

**Response:**
```json
{
  "email": "user@example.com",
  "profile": {}
}
```

## Gateway Features

The API Gateway provides:

1. **Rate Limiting** - Prevents abuse (per IP address)
2. **Authentication** - JWT token validation on protected endpoints
3. **Request Routing** - Forwards requests to appropriate microservices
4. **CORS** - Enabled for web clients
5. **Request Body Forwarding** - Properly passes JSON payloads to backend services

## Service Architecture

```
Mobile App (Flutter)
    ↓
API Gateway (Port 8000)
    ├→ Auth Service (Port 8001) - User authentication & JWT issuance
    ├→ Opportunity Service (Port 8002) - Opportunities & bookmarks
    ├→ Ingestion Service (Port 8003) - Data ingestion
    └→ Notification Service (Port 8004) - Notifications

Each service has its own PostgreSQL database
```

## Troubleshooting

### Cannot Connect to Backend
1. Verify Docker services are running: `docker compose ps`
2. Check API Gateway is responsive: `curl http://localhost:8000/health`
3. Verify network connectivity from mobile device to server
4. Check firewall rules allowing port 8000

### Authentication Fails
1. Ensure you've signed up first with `/auth/signup`
2. Verify credentials are correct in `/auth/login`
3. Check token expiration (access tokens expire in 30 minutes)
4. Use `/auth/refresh` with refresh token to get new access token

### Opportunities Not Loading
1. Verify user is authenticated with valid token
2. Check opportunity service logs: `docker compose logs opportunity-service`
3. Ensure data has been ingested into the system

## Next Steps

1. Start the Docker Compose stack: `docker compose up --build`
2. Create test account: See "Signup" example above
3. Run Flutter app with correct `API_BASE_URL`
4. App should authenticate and load opportunities
