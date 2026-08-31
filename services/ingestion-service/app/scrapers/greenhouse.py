import httpx


class GreenhouseScraper:
    BASE_URL = "https://boards-api.greenhouse.io/v1/boards"

    def __init__(self, board_token: str):
        self.board_token = board_token

    async def fetch_jobs(self) -> list[dict]:
        url = f"{self.BASE_URL}/{self.board_token}/jobs"

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()

        return data.get("jobs", [])