from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


ROOT_DIR = Path(__file__).resolve().parents[4]

ENV_FILE = ROOT_DIR / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        extra="ignore",
    )

    ingestion_port: int
    ingestion_host: str
    ingestion_database_url: str
    github_token: str
    app_env: str
    ingestion_database_url: str
    serper_api_key: str


@lru_cache
def get_settings() -> Settings:
    return Settings()