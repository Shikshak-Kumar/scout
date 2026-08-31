from datetime import datetime, timezone

from app.infra.database import db


class OpportunityRepository:
    def __init__(self):
        self.collection = db["opportunities"]

    async def upsert(self, opportunity: dict):
        opportunity["ingested_at"] = datetime.now(timezone.utc)

        await self.collection.update_one(
            {
                "external_id": opportunity["external_id"]
            },
            {
                "$set": opportunity
            },
            upsert=True,
        )