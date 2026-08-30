from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request

from app.core.config import get_settings
from app.domain.auth_guard import AuthGuard
from app.infra.http_client import ServiceClient
from app.infra.rate_limiter import RateLimiter

router = APIRouter()
settings = get_settings()


def get_auth_guard() -> AuthGuard:
    return AuthGuard()


def get_rate_limiter() -> RateLimiter:
    return RateLimiter()


def get_clients() -> dict[str, ServiceClient]:
    return {
        "auth": ServiceClient(settings.auth_service_url),
        "opportunity": ServiceClient(settings.opportunity_service_url),
        "ingestion": ServiceClient(settings.ingestion_service_url),
        "notification": ServiceClient(settings.notification_service_url),
    }


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "api-gateway"}


# Auth endpoints
@router.post("/auth/signup")
async def signup(request: Request, rate_limiter: RateLimiter = Depends(get_rate_limiter)):
    """Forward signup request to auth service with rate limiting."""
    user_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.allow(f"ip:{user_ip}"):
        raise HTTPException(status_code=429, detail="rate limit exceeded")

    body = await request.json()
    client = ServiceClient(settings.auth_service_url)
    return await client.post("/signup", json=body)


@router.post("/auth/login")
async def login(request: Request, rate_limiter: RateLimiter = Depends(get_rate_limiter)):
    """Forward login request to auth service with rate limiting."""
    user_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.allow(f"ip:{user_ip}"):
        raise HTTPException(status_code=429, detail="rate limit exceeded")

    body = await request.json()
    client = ServiceClient(settings.auth_service_url)
    return await client.post("/login", json=body)


@router.post("/auth/refresh")
async def refresh(request: Request):
    """Forward refresh token request to auth service."""
    body = await request.json()
    client = ServiceClient(settings.auth_service_url)
    return await client.post("/refresh", json=body)


@router.get("/auth/me")
async def get_auth_me(request: Request, auth_guard: AuthGuard = Depends(get_auth_guard)):
    """Get current authenticated user profile."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    payload = await auth_guard.verify(token)
    return {"email": payload.get("email"), "profile": {}}


@router.patch("/auth/me")
async def update_auth_me(request: Request, auth_guard: AuthGuard = Depends(get_auth_guard)):
    """Update current authenticated user profile."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    payload = await auth_guard.verify(token)
    body = await request.json()
    return {"email": payload.get("email"), "profile": body.get("profile", {})}


# Opportunities endpoints
@router.get("/opportunities")
async def list_opportunities(
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
    rate_limiter: RateLimiter = Depends(get_rate_limiter),
):
    """List opportunities with auth and rate limiting."""
    user_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.allow(f"ip:{user_ip}"):
        raise HTTPException(status_code=429, detail="rate limit exceeded")

    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    await auth_guard.verify(token)
    
    # Forward to opportunity service with query params
    query_params = dict(request.query_params)
    client = ServiceClient(settings.opportunity_service_url)
    result = await client.get("/opportunities", params=query_params)
    return {"items": result if isinstance(result, list) else result.get("items", [])}


@router.get("/opportunities/{opportunity_id}")
async def get_opportunity(
    opportunity_id: str,
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
):
    """Get single opportunity detail."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    await auth_guard.verify(token)
    client = ServiceClient(settings.opportunity_service_url)
    return await client.get(f"/opportunities/{opportunity_id}")


@router.get("/opportunities/saved")
async def get_saved_opportunities(
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
):
    """Get user's saved opportunities."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    await auth_guard.verify(token)
    client = ServiceClient(settings.opportunity_service_url)
    result = await client.get("/bookmarks")
    return result if isinstance(result, list) else result.get("items", [])


@router.get("/opportunities/applications")
async def get_applications(
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
):
    """Get user's applications."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    await auth_guard.verify(token)
    # Currently returns same as saved, can be extended later
    client = ServiceClient(settings.opportunity_service_url)
    result = await client.get("/bookmarks")
    return result if isinstance(result, list) else result.get("items", [])


@router.put("/opportunities/{opportunity_id}/saved")
async def save_opportunity(
    opportunity_id: str,
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
):
    """Save or update an opportunity."""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    token = auth_header.split(" ", 1)[1]
    await auth_guard.verify(token)
    body = await request.json()
    client = ServiceClient(settings.opportunity_service_url)
    return await client.put(f"/bookmarks/{opportunity_id}", json=body)


# Bookmarks endpoint (same as saved)
@router.get("/bookmarks")
async def list_bookmarks(
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
    rate_limiter: RateLimiter = Depends(get_rate_limiter),
):
    """List user's bookmarks."""
    user_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.allow(f"ip:{user_ip}"):
        raise HTTPException(status_code=429, detail="rate limit exceeded")

    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    await auth_guard.verify(auth_header.split(" ", 1)[1])
    client = ServiceClient(settings.opportunity_service_url)
    result = await client.get("/bookmarks")
    return result if isinstance(result, list) else result.get("items", [])



@router.get("/notifications")
async def list_notifications(
    request: Request,
    auth_guard: AuthGuard = Depends(get_auth_guard),
    rate_limiter: RateLimiter = Depends(get_rate_limiter),
):
    user_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.allow(f"ip:{user_ip}"):
        raise HTTPException(status_code=429, detail="rate limit exceeded")

    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")

    await auth_guard.verify(auth_header.split(" ", 1)[1])
    return await get_clients()["notification"].get("/notifications")
