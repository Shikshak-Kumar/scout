from __future__ import annotations

from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException

from app.infra.broker import BrokerClient

router = APIRouter()
broker = BrokerClient()


class IngestRequest(BaseModel):
    source: str = Field(..., min_length=1)
    title: str = Field(..., min_length=1)
    company: str | None = None
    location: str | None = None
    salary: str | None = None
    external_url: str | None = None


@router.post("/ingest")
async def ingest(payload: IngestRequest) -> dict[str, object]:
    event_payload = {
        "opportunity_id": f"opportunity-{payload.source.lower().replace(' ', '-')}-{abs(hash(payload.title))}",
        "source": payload.source,
        "title": payload.title,
        "company": payload.company,
        "location": payload.location,
        "salary": payload.salary,
        "external_url": payload.external_url,
    }

    published = broker.publish("opportunity.created", event_payload)
    if not published:
        raise HTTPException(status_code=503, detail="broker unavailable")

    return {
        "status": "queued",
        "service": "ingestion-service",
        "broker_published": True,
        "opportunity_id": event_payload["opportunity_id"],
    }


@router.get("/sources")
async def sources() -> dict[str, list]:
    return {"status": "ok", "items": []}
