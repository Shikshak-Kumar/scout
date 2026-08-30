from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", extra="ignore")

    app_env: str = "development"
    database_url: str = "postgresql+asyncpg://scout:scout@notification-db:5432/notification_service"
    rabbitmq_url: str = "amqp://guest:guest@rabbitmq:5672/"


@lru_cache
def get_settings() -> Settings:
    return Settings()
