import httpx

from app.scrapers.base import BaseScraper


class WorkdayScraper(BaseScraper):
    def __init__(
        self,
        host: str,
        tenant: str,
        site: str,
    ):
        self.host = host
        self.tenant = tenant
        self.site = site

    @property
    def jobs_url(self) -> str:
        return (
            f"https://{self.host}"
            f"/wday/cxs/{self.tenant}/{self.site}/jobs"
        )

    async def fetch_jobs(self) -> list[dict]:
        all_jobs = []
        offset = 0
        limit = 20

        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(
            timeout=30.0,
            headers=headers,
        ) as client:
            while True:
                payload = {
                    "appliedFacets": {},
                    "limit": limit,
                    "offset": offset,
                    "searchText": "",
                }

                response = await client.post(
                    self.jobs_url,
                    json=payload,
                )

                response.raise_for_status()

                data = response.json()
                jobs = data.get("jobPostings", [])

                if not jobs:
                    break

                all_jobs.extend(jobs)

                total = data.get("total", 0)
                offset += limit

                if offset >= total:
                    break

        return all_jobs