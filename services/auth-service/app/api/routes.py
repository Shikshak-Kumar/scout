from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel

from app.infra.auth import AuthService
from app.infra.persistence import UserRepository

router = APIRouter()
auth_service = AuthService()
user_repo = UserRepository()


class SignupRequest(BaseModel):
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "auth-service"}


@router.get("/verify-token")
async def verify_token(authorization: str | None = Header(default=None, alias="Authorization")) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")

    token = authorization.split(" ", 1)[1]
    try:
        payload = auth_service.verify_token(token)
        return {"valid": True, "email": payload.get("email"), "token_type": payload.get("token_type")}
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc


@router.post("/signup")
async def signup(payload: SignupRequest) -> dict[str, str]:
    if not payload.email or not payload.password:
        raise HTTPException(status_code=400, detail="email and password required")

    user = await user_repo.get_by_email(payload.email)
    if user is not None:
        raise HTTPException(status_code=409, detail="user already exists")

    await user_repo.create_user(payload.email, payload.password)
    return {"status": "ok", "service": "auth-service", "action": "signup", "email": payload.email}


@router.post("/login")
async def login(payload: LoginRequest) -> dict[str, str]:
    if not payload.email or not payload.password:
        raise HTTPException(status_code=400, detail="email and password required")

    user = await user_repo.get_by_email(payload.email)
    if user is None or not user_repo.verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="invalid credentials")

    access_token = auth_service.issue_token(payload.email)
    refresh_token = auth_service.issue_refresh_token(payload.email)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


@router.post("/refresh")
async def refresh(payload: RefreshRequest) -> dict[str, str]:
    try:
        access_token, refresh_token = auth_service.rotate_refresh_token(payload.refresh_token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc

    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}
