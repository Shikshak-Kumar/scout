import httpx
from bs4 import BeautifulSoup


class IndeedScraper:
    BASE_URL = "https://www.indeed.com"

    def __init__(
        self,
        query: str,
        location: str = "",
    ):
        self.query = query
        self.location = location

    async def fetch_jobs(self) -> list[dict]:
        params = {
            "q": self.query,
            "l": self.location,
        }

        headers = {
            "User-Agent": (
                "Mozilla/5.0 "
                "(Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 "
                "(KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            )
        }

        async with httpx.AsyncClient(
            timeout=30.0,
            follow_redirects=True,
        ) as client:

            response = await client.get(
                f"{self.BASE_URL}/jobs",
                params=params,
                headers=headers,
            )

            response.raise_for_status()

        return self.parse_jobs(response.text)

    def parse_jobs(self, html: str) -> list[dict]:
        soup = BeautifulSoup(html, "lxml")

        jobs = []

        # Selectors should be treated as source-specific
        job_cards = soup.select("[data-testid='slider_item']")

        for card in job_cards:
            title_element = card.select_one("h2")

            if not title_element:
                continue

            jobs.append({
                "title": title_element.get_text(
                    strip=True
                ),
            })

        return jobs