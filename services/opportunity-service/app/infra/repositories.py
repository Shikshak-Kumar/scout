class OpportunityRepository:
    def __init__(self) -> None:
        self._items = [
            {
                "id": "demo-opportunity-1",
                "title": "Senior Python Engineer",
                "company": "Northstar Labs",
                "location": "Remote",
                "salary": "$140k - $180k",
            },
            {
                "id": "demo-opportunity-2",
                "title": "Data Engineer",
                "company": "Signal Forge",
                "location": "Austin, TX",
                "salary": "$120k - $155k",
            },
        ]
        self._bookmarks: dict[str, dict] = {}

    async def list(self):
        return self._items

    async def get_by_id(self, opportunity_id: str):
        for item in self._items:
            if item["id"] == opportunity_id:
                return item
        return None

    async def list_bookmarks(self):
        return list(self._bookmarks.values())

    async def add_bookmark(self, opportunity_id: str):
        item = await self.get_by_id(opportunity_id)
        if item is None:
            return None
        self._bookmarks[opportunity_id] = {"opportunity_id": opportunity_id, **item}
        return self._bookmarks[opportunity_id]

    async def remove_bookmark(self, opportunity_id: str):
        if opportunity_id in self._bookmarks:
            del self._bookmarks[opportunity_id]
            return True
        return False
