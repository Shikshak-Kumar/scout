import uuid, jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.core.config import get_settings
from app.models import User
bearer=HTTPBearer(auto_error=False)
async def current_user(credentials:HTTPAuthorizationCredentials|None=Depends(bearer), db:AsyncSession=Depends(get_db))->User:
    if not credentials: raise HTTPException(401,"Authentication required")
    try:
        payload=jwt.decode(credentials.credentials,get_settings().jwt_secret,algorithms=["HS256"])
        if payload.get("type")!="access": raise ValueError()
        user=(await db.execute(select(User).where(User.id==uuid.UUID(payload["sub"]),User.is_active))).scalar_one_or_none()
    except Exception: raise HTTPException(401,"Session expired")
    if not user: raise HTTPException(401,"Session expired")
    return user

