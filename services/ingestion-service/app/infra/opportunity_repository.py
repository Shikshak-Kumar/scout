from datetime import datetime, timezone

from bson import ObjectId

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

    async def upsert(self, opportunity: dict,ingestion_started_at: datetime):
        now = datetime.now(timezone.utc)

        unique_filter = self._get_unique_filter(opportunity)

        opportunity["last_seen_at"] = now
        opportunity["active"] = True

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

    async def mark_stale_jobs_inactive( self, source: str, company: str, ingestion_started_at: datetime ):
        result = await self.collection.update_many(
            {
                "source": source,
                "company": company,
                "active": True,
                "last_seen_at": {
                    "$lt": ingestion_started_at,
                },
            },
            {
                "$set": {
                    "active": False,
                }
            },
        )

        return result.modified_count

    def _build_filters(
        self,
        query: str | None = None,
        location: str | None = None,
        company: str | None = None,
        source: str | None = None,
        active: bool | None = True,
    ) -> dict:
        filters = {}

        if query:
            filters["$or"] = [
                {"title": {"$regex": query, "$options": "i"}},
                {"company": {"$regex": query, "$options": "i"}},
            ]

        if location:
            filters["location"] = {
                "$regex": location,
                "$options": "i",
            }

        if company:
            filters["company"] = {
                "$regex": company,
                "$options": "i",
            }

        if source:
            filters["source"] = source

        if active is not None:
            filters["active"] = active

        return filters

    async def get_jobs(
        self,
        query: str | None = None,
        location: str | None = None,
        company: str | None = None,
        source: str | None = None,
        active: bool | None = True,
        skip: int = 0,
        limit: int = 20,
        sort_by: str = "last_seen_at",
        sort_order: int = -1,
    ):
        filters = self._build_filters(
            query=query,
            location=location,
            company=company,
            source=source,
            active=active,
        )

        cursor = (
            self.collection
            .find(filters)
            .sort(sort_by, sort_order)
            .skip(skip)
            .limit(limit)
        )

        return await cursor.to_list(length=limit)

    async def count_jobs(
        self,
        query: str | None = None,
        location: str | None = None,
        company: str | None = None,
        source: str | None = None,
    ):
        filters = self._build_filters(
            query=query,
            location=location,
            company=company,
            source=source,
        )

        return await self.collection.count_documents(filters)

    async def get_job_by_id(self, job_id: str):
        if not ObjectId.is_valid(job_id):
            return None

        return await self.collection.find_one(
            {"_id": ObjectId(job_id)}
        )