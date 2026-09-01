import httpx

from app.core.config import get_settings


class SerperClient:

    BASE_URL = "https://google.serper.dev/search"

    def __init__(self):
        self.api_key = get_settings().serper_api_key

    async def search(
        self,
        query: str,
        num: int = 10,
    ) -> list[dict]:

        headers = {
            "X-API-KEY": self.api_key,
            "Content-Type": "application/json",
        }

        payload = {
            "q": query,
            "num": min(num, 10),
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                self.BASE_URL,
                headers=headers,
                json=payload,
            )

            response.raise_for_status()

            data = response.json()

        return data.get("organic", [])