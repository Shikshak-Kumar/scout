from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse

from app.domain.ingestion_service import IngestionDomainService
from app.domain.job_service import JobService
from app.models.job_response import JobResponse, JobsListResponse

router = APIRouter()

ingestion_service = IngestionDomainService()
job_service = JobService()

@router.post("/ingest/greenhouse")
async def ingest_greenhouse():
    results = await ingestion_service.ingest_greenhouse()

    return {
        "status": "completed",
        "results": results,
    }


@router.post("/ingest/workday")
async def ingest_workday():
    results = await ingestion_service.ingest_workday()

    return {
        "status": "completed",
        "results": results,
    }

@router.get("/jobs",response_model=JobsListResponse)
async def get_jobs(
    query: str | None = None,
    location: str | None = None,
    company: str | None = None,
    source: str | None = None,
    active: bool | None = True,
    sort_by: str = Query(
        default="newest",
        description="newest, oldest, title, company",
    ),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await job_service.get_jobs(
        query=query,
        location=location,
        company=company,
        source=source,
        sort_by=sort_by,
        active=active,
        page=page,
        limit=limit,
    )


@router.get("/jobs/{job_id}", response_model=JobResponse)
async def get_job(job_id: str):
    job = await job_service.get_job_by_id(job_id)

    if not job:
        return JSONResponse(
            status_code=404,
            content={
                "detail": "Job not found",
            },
        )

    return job

@router.get("/sources")
async def sources():
    return {
        "status": "ok",
        "items": [],
    }