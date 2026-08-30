class OpportunityDomainService:
    """Domain boundary for opportunity query and bookmark workflows."""

    def __init__(self) -> None:
        self.name = "opportunity-service"

    async def search(self, query: str | None = None) -> dict:
        return {"service": self.name, "query": query or "", "results": []}
