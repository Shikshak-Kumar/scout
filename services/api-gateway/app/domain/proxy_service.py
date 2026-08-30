class ProxyService:
    """Gateway logic for routing requests to downstream services."""

    async def route(self, path: str) -> dict:
        return {"path": path, "status": "proxied"}
