from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


# Resolve the service root directory portably:
#   config.py  ->  app/core/config.py
#   parents[0] ->  app/core/
#   parents[1] ->  app/
#   parents[2] ->  ingestion-service/   <-- service root (same on local & Docker)
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
    ingestion_database_url: str = ""

    # Misc service config
    ingestion_port: int = 8003
    ingestion_host: str = "0.0.0.0"
    app_env: str = "development"

    # External API keys (empty defaults so the app starts even without them)
    github_token: str = ""
    serper_api_key: str = ""

    # Downstream services
    opportunity_service_url: str = "http://localhost:8002"

    # Infrastructure
    redis_url: str = ""
    rabbitmq_url: str = ""


@lru_cache
def get_settings() -> Settings:
    return Settings()