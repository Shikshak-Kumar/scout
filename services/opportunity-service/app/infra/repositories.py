from app.infra.database import db


class OpportunityRepository:
    def __init__(self):
        self.collection = db["opportunities"]

    async def list(self):
        opportunities = []

        cursor = self.collection.find({})

        async for opportunity in cursor:
            opportunity["id"] = str(opportunity["_id"])
            del opportunity["_id"]
            opportunities.append(opportunity)

        return opportunities

    async def get_by_id(self, opportunity_id: str):
        from bson import ObjectId

        try:
            opportunity = await self.collection.find_one(
                {"_id": ObjectId(opportunity_id)}
            )

            if opportunity:
                opportunity["id"] = str(opportunity["_id"])
                del opportunity["_id"]

            return opportunity

        except Exception:
            return None