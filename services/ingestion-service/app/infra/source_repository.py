from app.infra.database import db


class SourceRepository:
    def __init__(self):
        self.collection = db["source_configs"]

    async def get_enabled_sources(self, source_type: str):
        cursor = self.collection.find({
            "source_type": source_type,
            "enabled": True,
        })

        return await cursor.to_list(length=None)