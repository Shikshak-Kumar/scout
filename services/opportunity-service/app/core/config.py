from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


# opportunity-service/app/core/config.py
# Go up three levels:
# app/core -> app -> opportunity-service -> services -> scout
ROOT_DIR = Path(__file__).resolve().parents[4]

ENV_FILE = ROOT_DIR / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        extra="ignore",
    )

    opportunity_database_url: str


@lru_cache
def get_settings() -> Settings:
    return Settings()