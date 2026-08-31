from fastapi import APIRouter

from app.domain.ingestion_service import IngestionDomainService


router = APIRouter()

ingestion_service = IngestionDomainService()


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


@router.get("/sources")
async def sources():
    return {"status": "ok", "items": []}