from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models import User
from app.schemas.api import ProfileOut, ProfileUpdateIn
from app.api.deps import current_user
from app.core.config import get_settings

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=ProfileOut)
async def get_profile(user: User = Depends(current_user)):
    return user


@router.patch("/me", response_model=ProfileOut)
async def update_profile(
    data: ProfileUpdateIn,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(current_user),
):
    user.profile = {**user.profile, **data.profile}
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
