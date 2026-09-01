from datetime import datetime, timezone

from app.infra.database import db


class OpportunityRepository:
    def __init__(self):
        self.collection = db["opportunities"]

    def _get_unique_filter(self, opportunity: dict) -> dict:
        source = opportunity.get("source")
        external_id = opportunity.get("external_id")
        external_url = opportunity.get("external_url")

        if source and external_id:
            return {
                "source": source,
                "external_id": external_id,
            }

        if external_url:
            return {
                "external_url": external_url,
            }

        return {
            "source": source,
            "title": opportunity.get("title"),
            "company": opportunity.get("company"),
            "location": opportunity.get("location"),
        }

    async def upsert(self, opportunity: dict):
        now = datetime.now(timezone.utc)

        unique_filter = self._get_unique_filter(opportunity)

        opportunity["last_seen_at"] = now

        await self.collection.update_one(
            unique_filter,
            {
                "$set": opportunity,
                "$setOnInsert": {
                    "first_seen_at": now,
                },
            },
            upsert=True,
        )