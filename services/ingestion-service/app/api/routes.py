from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.domain.ingestion_service import IngestionDomainService
from app.domain.discovery_service import DiscoveryService


router = APIRouter()

ingestion_service = IngestionDomainService()
discovery_service = DiscoveryService()


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

class DiscoverRequest(BaseModel):
    query: str = Field(..., min_length=2)
    location: str = "India"
    source: str | None = None
    num: int = Field(default=10, ge=1, le=10)


@router.post("/discover")
async def discover(payload: DiscoverRequest):
    jobs = await discovery_service.discover(
        query=payload.query,
        location=payload.location,
        source=payload.source,
        num=payload.num,
    )

    return {
        "status": "completed",
        "count": len(jobs),
        "jobs": [
            job.model_dump()
            for job in jobs
        ],
    }

@router.get("/sources")
async def sources():
    return {
        "status": "ok",
        "items": [
            "greenhouse",
            "workday",
            "linkedin",
            "indeed",
            "web",
        ],
    }