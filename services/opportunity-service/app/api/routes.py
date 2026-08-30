from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.infra.repositories import OpportunityRepository

router = APIRouter()
repository = OpportunityRepository()


@router.get("/opportunities")
async def list_opportunities() -> dict[str, object]:
    items = await repository.list()
    return {"status": "ok", "items": items}


@router.get("/opportunities/{opportunity_id}")
async def get_opportunity(opportunity_id: str) -> dict[str, object]:
    item = await repository.get_by_id(opportunity_id)
    if item is None:
        raise HTTPException(status_code=404, detail="opportunity not found")
    return {"status": "ok", "id": item["id"], "item": item}


@router.post("/bookmarks/{opportunity_id}")
async def add_bookmark(opportunity_id: str) -> dict[str, object]:
    item = await repository.add_bookmark(opportunity_id)
    if item is None:
        raise HTTPException(status_code=404, detail="opportunity not found")
    return {"status": "ok", "opportunity_id": opportunity_id, "bookmark": item}


@router.delete("/bookmarks/{opportunity_id}")
async def delete_bookmark(opportunity_id: str) -> dict[str, object]:
    removed = await repository.remove_bookmark(opportunity_id)
    return {"status": "ok", "opportunity_id": opportunity_id, "removed": removed}


@router.get("/bookmarks")
async def list_bookmarks() -> dict[str, object]:
    items = await repository.list_bookmarks()
    return {"status": "ok", "items": items}
