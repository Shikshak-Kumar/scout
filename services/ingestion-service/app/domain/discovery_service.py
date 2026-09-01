from app.discovery.serper import SerperClient
from app.discovery.source_router import SourceRouter
from app.normalizers.serper import normalize_serper_job
from app.infra.opportunity_repository import OpportunityRepository   


class DiscoveryService:

    def __init__(self):
        self.serper = SerperClient()
        self.router = SourceRouter()
        self.opportunity_repository = OpportunityRepository()

    async def discover(
        self,
        query: str,
        location: str,
        source: str | None = None,
        num: int = 10,
    ) -> list:

        if source:
            strategy = self.router.get_strategy(source)

            if strategy == "serper":
                return await self._discover_with_serper(
                    query=query,
                    location=location,
                    source=source,
                    num=num,
                )

        return await self._discover_with_serper(
            query=query,
            location=location,
            source=source,
            num=num,
        )

    async def _discover_with_serper(
        self,
        query: str,
        location: str,
        source: str | None,
        num: int,
    ) -> list:

        search_query = f"{query} jobs {location}"

        site_map = {
            "linkedin": "linkedin.com/jobs/view",
            "indeed": "indeed.com",
            "greenhouse": "job-boards.greenhouse.io",
            "lever": "jobs.lever.co",
            "ashby": "jobs.ashbyhq.com",
        }

        if source and source.lower() in site_map:
            search_query += f" site:{site_map[source.lower()]}"

        results = await self.serper.search(
            query=search_query,
            num=num,
        )

        jobs = []

        for item in results:
            job = normalize_serper_job(
                {
                    "title": item.get("title"),
                    "external_url": item.get("link"),
                    "snippet": item.get("snippet"),
                    "location": location,
                    "source": self._detect_source(
                        item.get("link", "")
                    ),
                }
            )

            await self.opportunity_repository.upsert(
                job.model_dump()
            )

            jobs.append(job)

        return jobs

    @staticmethod
    def _detect_source(url: str) -> str:

        url = url.lower()

        if "linkedin.com" in url:
            return "linkedin"

        if "indeed.com" in url:
            return "indeed"

        if "greenhouse.io" in url:
            return "greenhouse"

        if "lever.co" in url:
            return "lever"

        if "ashbyhq.com" in url:
            return "ashby"

        return "web"