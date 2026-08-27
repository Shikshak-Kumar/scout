from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models import User

DEV_USER_EMAIL = "dev@scout.local"
DEV_USER_ID = "local-development-user"


async def development_user(
    db: AsyncSession = Depends(get_db),
) -> User:
    user = (
        await db.execute(select(User).where(User.keycloak_id == DEV_USER_ID))
    ).scalar_one_or_none()

    if user:
        return user

    user = User(
        email=DEV_USER_EMAIL,
        keycloak_id=DEV_USER_ID,
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
