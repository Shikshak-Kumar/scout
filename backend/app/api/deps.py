from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models import User

DEV_USER_EMAIL = "dev@scout.com"
LEGACY_DEV_USER_EMAILS = ["dev@scout.local", DEV_USER_EMAIL]


async def development_user(
    db: AsyncSession = Depends(get_db),
) -> User:
    user = (
        await db.execute(select(User).where(User.email.in_(LEGACY_DEV_USER_EMAILS)))
    ).scalar_one_or_none()

    if user:
        if user.email != DEV_USER_EMAIL:
            user.email = DEV_USER_EMAIL
            await db.commit()
        return user

    user = User(
        email=DEV_USER_EMAIL,
        password_hash="dev-user-password",
        keycloak_id=None,
        is_active=True,
        is_admin=False,
        profile={"name": "Local Developer", "role": "developer"},
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_current_user(
    db: AsyncSession = Depends(get_db),
) -> User:
    return await development_user(db)
