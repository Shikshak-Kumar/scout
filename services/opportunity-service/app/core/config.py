from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", extra="ignore")

    app_env: str = "development"
    database_url: str = "postgresql+asyncpg://scout:scout@opportunity-db:5432/opportunity_service"
    elasticsearch_url: str = "http://elasticsearch:9200"
    jwt_public_key: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()
