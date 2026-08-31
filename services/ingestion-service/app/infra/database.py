import certifi

from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import get_settings


settings = get_settings()

client = AsyncIOMotorClient(
    settings.ingestion_database_url,
    tls=True,
    tlsCAFile=certifi.where(),
)

db = client["scout"]