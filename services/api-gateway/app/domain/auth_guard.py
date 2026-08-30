from __future__ import annotations

from jose import JWTError, jwt

from app.core.config import get_settings


class AuthGuard:
    async def verify(self, token: str) -> dict:
        settings = get_settings()
        public_key = settings.public_key
        if not public_key:
            raise ValueError("JWT public key not configured")

        try:
            payload = jwt.decode(token, public_key, algorithms=["RS256"])
            return payload
        except JWTError as exc:
            raise ValueError("invalid token") from exc
