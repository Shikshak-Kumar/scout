from app.infra.opportunity_repository import OpportunityRepository


class JobService:
    def __init__(self):
        self.opportunity_repository = OpportunityRepository()

    async def get_jobs(
        self,
        query: str | None = None,
        location: str | None = None,
        company: str | None = None,
        source: str | None = None,
        active: bool | None = True,
        page: int = 1,
        limit: int = 20,
        sort_by: str = "newest",
    ):
        skip = (page - 1) * limit

        sort_mapping = {
            "newest": ("last_seen_at", -1),
            "oldest": ("first_seen_at", 1),
            "title": ("title", 1),
            "company": ("company", 1),
        }

        db_sort_field, db_sort_order = sort_mapping.get(
            sort_by,
            ("last_seen_at", -1),
        )

        jobs = await self.opportunity_repository.get_jobs(
            query=query,
            location=location,
            company=company,
            source=source,
            skip=skip,
            active=active,
            limit=limit,
            sort_by=db_sort_field,
            sort_order=db_sort_order,
        )

        total = await self.opportunity_repository.count_jobs(
            query=query,
            location=location,
            company=company,
            source=source,
            active=active,
        )

        for job in jobs:
            job["id"] = str(job.pop("_id"))

        return {
            "items": jobs,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total,
                "total_pages": (
                    (total + limit - 1) // limit
                    if total > 0
                    else 0
                ),
            },
        }

    async def get_job_by_id(self, job_id: str):
        job = await self.opportunity_repository.get_job_by_id(job_id)

        if not job:
            return None

        job["id"] = str(job.pop("_id"))

        return job