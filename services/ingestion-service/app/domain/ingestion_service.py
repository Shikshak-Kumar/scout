from datetime import datetime, timezone

from app.infra.source_repository import SourceRepository
from app.infra.opportunity_repository import OpportunityRepository

from app.scrapers.greenhouse import GreenhouseScraper
from app.scrapers.workday import WorkdayScraper

from app.normalizers.greenhouse import normalize_greenhouse_job
from app.normalizers.workday import normalize_workday_job


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
            ingestion_started_at = datetime.now(timezone.utc)

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
                        opportunity.model_dump(),
                        ingestion_started_at,
                    )

                    saved_count += 1

                inactive_count = (
                    await self.opportunity_repository.mark_stale_jobs_inactive(
                        source="greenhouse",
                        company=source["company"],
                        ingestion_started_at=ingestion_started_at,
                    )
                )

                results.append({
                    "company": source["company"],
                    "jobs_found": len(jobs),
                    "jobs_saved": saved_count,
                    "jobs_marked_inactive": inactive_count,
                    "status": "success",
                })

            except Exception as e:
                results.append({
                    "company": source["company"],
                    "status": "failed",
                    "error": str(e),
                })

        return results

    async def ingest_workday(self):
        sources = await self.source_repository.get_enabled_sources(
            "workday"
        )

        results = []

        for source in sources:
            ingestion_started_at = datetime.now(timezone.utc)

            scraper = WorkdayScraper(
                host=source["host"],
                tenant=source["tenant"],
                site=source["site"],
            )

            try:
                jobs = await scraper.fetch_jobs()

                saved_count = 0

                for job in jobs:
                    opportunity = normalize_workday_job(
                        job,
                        source,
                    )

                    await self.opportunity_repository.upsert(
                        opportunity.model_dump(),
                        ingestion_started_at,
                    )

                    saved_count += 1

                inactive_count = (
                    await self.opportunity_repository.mark_stale_jobs_inactive(
                        source="workday",
                        company=source["company"],
                        ingestion_started_at=ingestion_started_at,
                    )
                )

                results.append({
                    "company": source["company"],
                    "jobs_found": len(jobs),
                    "jobs_saved": saved_count,
                    "jobs_marked_inactive": inactive_count,
                    "status": "success",
                })

            except Exception as e:
                results.append({
                    "company": source["company"],
                    "status": "failed",
                    "error": str(e),
                })

        return results