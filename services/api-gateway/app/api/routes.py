from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def gateway_health() -> dict[str, str]:
    return {"status": "ok", "service": "api-gateway"}


@router.get("/auth/health")
async def auth_health() -> dict[str, str]:
    return {"status": "ok", "service": "api-gateway"}
