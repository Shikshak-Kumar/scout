import os
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict

DEV_PUBLIC_KEY = """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtPxP6pkLWjmG0GKxA+Ls
7XNEr6TecUQ6JeeqWNqguSQv6C10mq3Baz94UA/TQFqPlV6uLFrPlA/gC503CE+9
1vMWosvYUn844TWqGqsoCHvyLlhusJCgt9UWf0C42n5SLtqezV/Ej+LtbgOmU3/C
mokVmFrlpsMH0c07U2dCST998rG8UqQ8id1Zuq5mkTSa5xLGcH2/wMPJhpU2v+MJ
/7wmm/6DaU5T/qm4n2BjfOWZZ4Wzh3TOmkSTUPU0XXT8PzVEOF4l57srSgn9FjFq
5RtqIXPNH4KVhb6FL2w0TXjAdQ3YWAzvgB9fqZEe3EFsV/Yoic6qZfZRI89L7XMS
awIDAQAB
-----END PUBLIC KEY-----"""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", extra="ignore")

    app_env: str = "development"
    auth_service_url: str = "http://127.0.0.1:8001"
    opportunity_service_url: str = "http://127.0.0.1:8002"
    ingestion_service_url: str = "http://127.0.0.1:8003"
    notification_service_url: str = "http://127.0.0.1:8004"
    redis_url: str = "redis://localhost:6379/0"
    jwt_public_key: str | None = None
    jwt_public_key_path: str | None = None
    allowed_origins: list[str] = ["http://localhost:3000", "http://localhost:8000"]

    @property
    def public_key(self) -> str | None:
        if self.jwt_public_key:
            return self.jwt_public_key
        if self.jwt_public_key_path and os.path.exists(self.jwt_public_key_path):
            with open(self.jwt_public_key_path, "r", encoding="utf-8") as fh:
                return fh.read()
        return DEV_PUBLIC_KEY


@lru_cache
def get_settings() -> Settings:
    return Settings()
