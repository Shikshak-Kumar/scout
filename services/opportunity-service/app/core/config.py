from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


# Resolve the service root directory portably:
#   config.py  ->  app/core/config.py
#   parents[0] ->  app/core/
#   parents[1] ->  app/
#   parents[2] ->  opportunity-service/  <-- service root (same on local & Docker)
_SERVICE_ROOT = Path(__file__).resolve().parents[2]

# Load .env from the service root when present (local dev).
# In Docker the file won't exist and env vars come from docker-compose instead.
ENV_FILE = _SERVICE_ROOT / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE) if ENV_FILE.exists() else None,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # MongoDB connection string
    opportunity_database_url: str = ""

    # Infrastructure
    elasticsearch_url: str = ""
    redis_url: str = ""
    app_env: str = "development"


@lru_cache
def get_settings() -> Settings:
    return Settings()