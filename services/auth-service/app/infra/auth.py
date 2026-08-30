from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt

from app.core.config import get_settings


class AuthService:
    def __init__(self) -> None:
        self.settings = get_settings()
        self._refresh_tokens: dict[str, str] = {}

    def _issue(self, email: str, ttl_minutes: int, token_type: str) -> str:
        private_key = self.settings.private_key
        if not private_key:
            raise ValueError("JWT private key not configured")

        now = datetime.now(timezone.utc)
        payload = {
            "sub": email,
            "email": email,
            "token_type": token_type,
            "iat": int(now.timestamp()),
            "exp": int((now + timedelta(minutes=ttl_minutes)).timestamp()),
        }
        return jwt.encode(payload, private_key, algorithm="RS256")

    def issue_token(self, email: str) -> str:
        return self._issue(email, 30, "access")

    def issue_refresh_token(self, email: str) -> str:
        refresh = self._issue(email, 60 * 24 * 7, "refresh")
        token_hash = hashlib.sha256(refresh.encode("utf-8")).hexdigest()
        self._refresh_tokens[token_hash] = email
        return refresh

    def verify_token(self, token: str) -> dict:
        public_key = self.settings.public_key
        if not public_key:
            raise ValueError("JWT public key not configured")
        try:
            return jwt.decode(token, public_key, algorithms=["RS256"])
        except JWTError as exc:
            raise ValueError("invalid token") from exc

    def rotate_refresh_token(self, refresh_token: str) -> tuple[str, str]:
        payload = self.verify_token(refresh_token)
        if payload.get("token_type") != "refresh":
            raise ValueError("invalid refresh token")

        email = payload["email"]
        token_hash = hashlib.sha256(refresh_token.encode("utf-8")).hexdigest()
        if token_hash not in self._refresh_tokens:
            raise ValueError("refresh token reused or revoked")

        del self._refresh_tokens[token_hash]
        new_access = self.issue_token(email)
        new_refresh = self.issue_refresh_token(email)
        return new_access, new_refresh
