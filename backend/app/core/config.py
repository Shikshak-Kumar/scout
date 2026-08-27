from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_prefix="SCOUT_", extra="ignore"
    )
    environment: str = "development"
    database_url: str = "postgresql+asyncpg://scout:scout@db:5432/scout"
    redis_url: str = "redis://redis:6379/0"
    github_token: str | None = None
    allowed_origins: list[str] = ["http://localhost:3000"]
    rss_feeds: list[str] = []


@lru_cache
def get_settings() -> Settings:
    return Settings()
