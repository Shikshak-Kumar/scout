from app.infra.source_repository import SourceRepository
from app.infra.opportunity_repository import OpportunityRepository
from app.scrapers.greenhouse import GreenhouseScraper
from app.scrapers.normalizer import normalize_greenhouse_job


class IngestionDomainService:
    def __init__(self):
        self.source_repository = SourceRepository()
        self.opportunity_repository = OpportunityRepository()

    async def ingest_greenhouse(self):
        sources = await self.source_repository.get_enabled_sources(
            "greenhouse"
        )

        results = []

        for source in sources:
            scraper = GreenhouseScraper(
                source["board_token"]
            )

            try:
                jobs = await scraper.fetch_jobs()

                saved_count = 0

                for job in jobs:
                    opportunity = normalize_greenhouse_job(
                        job,
                        source,
                    )

                    await self.opportunity_repository.upsert(
                        opportunity
                    )

                    saved_count += 1

                results.append({
                    "company": source["company"],
                    "jobs_found": len(jobs),
                    "jobs_saved": saved_count,
                    "status": "success",
                })

            except Exception as e:
                results.append({
                    "company": source["company"],
                    "status": "failed",
                    "error": str(e),
                })

        return results