from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import development_user
from app.db.session import get_db
from app.models import User
from app.schemas.api import ProfileOut, ProfileUpdateIn

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=ProfileOut)
async def get_profile(user: User = Depends(development_user)):
    return user


@router.patch("/me", response_model=ProfileOut)
async def update_profile(
    data: ProfileUpdateIn,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(development_user),
):
    user.profile = {**user.profile, **data.profile}
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
