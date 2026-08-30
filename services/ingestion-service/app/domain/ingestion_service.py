class IngestionDomainService:
    """Domain boundary for scrapers and ingestion workflows."""

    def __init__(self) -> None:
        self.name = "ingestion-service"

    async def ingest(self, source: str) -> dict:
        return {"service": self.name, "source": source, "status": "queued"}
