from __future__ import annotations

import hashlib
import hmac
import os
from datetime import datetime

from sqlalchemy import String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

from app.core.config import get_settings


class Base(DeclarativeBase):
    pass


class UserRecord(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, nullable=False)


class UserRepository:
    def __init__(self) -> None:
        settings = get_settings()
        database_url = settings.database_url
        if settings.app_env.lower() != "production" and database_url.startswith("postgresql"):
            database_url = "sqlite:///./auth_service_dev.db"
        self.engine = create_engine(database_url, future=True)
        Base.metadata.create_all(self.engine)

    def verify_password(self, raw_password: str, password_hash: str) -> bool:
        if not password_hash.startswith("pbkdf2_sha256$"):
            return False
        _, iterations_str, salt_hex, digest_hex = password_hash.split("$")
        iterations = int(iterations_str)
        salt = bytes.fromhex(salt_hex)
        expected = bytes.fromhex(digest_hex)
        actual = hashlib.pbkdf2_hmac("sha256", raw_password.encode("utf-8"), salt, iterations)
        return hmac.compare_digest(actual, expected)

    def hash_password(self, password: str) -> str:
        salt = os.urandom(16)
        iterations = 200_000
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations)
        return f"pbkdf2_sha256${iterations}${salt.hex()}${digest.hex()}"

    def _session(self) -> Session:
        return Session(self.engine)

    async def create_user(self, email: str, password: str) -> dict:
        with self._session() as session:
            user = UserRecord(email=email, password_hash=self.hash_password(password))
            session.add(user)
            session.commit()
            session.refresh(user)
            return {"id": user.id, "email": user.email, "password_hash": user.password_hash}

    async def get_by_email(self, email: str) -> dict | None:
        with self._session() as session:
            record = session.execute(select(UserRecord).where(UserRecord.email == email)).scalar_one_or_none()
            if record is None:
                return None
            return {"id": record.id, "email": record.email, "password_hash": record.password_hash}
