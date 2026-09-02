import httpx

from app.core.config import get_settings


class OpportunityClient:
    def __init__(self):
        settings = get_settings()
        self.base_url = settings.gateway_opportunity_service_url

    async def get_opportunities(
        self,
        page: int = 1,
        limit: int = 20,
        search: str | None = None,
        location: str | None = None,
        source: str | None = None,
    ):
        params = {
            "page": page,
            "limit": limit,
        }

        if search:
            params["search"] = search

        if location:
            params["location"] = location

        if source:
            params["source"] = source

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{self.base_url}/opportunities",
                params=params,
            )

            response.raise_for_status()

            return response.json()

    async def get_opportunity_by_id(
        self,
        opportunity_id: str,
    ):
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{self.base_url}/opportunities/{opportunity_id}"
            )

            response.raise_for_status()

            return response.json()