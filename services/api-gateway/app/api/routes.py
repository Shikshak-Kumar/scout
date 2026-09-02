import httpx

from fastapi import APIRouter, HTTPException, Query

from app.clients.opportunity_client import OpportunityClient


router = APIRouter(
    prefix="/opportunities",
    tags=["Opportunities"],
)

opportunity_client = OpportunityClient()


@router.get("")
async def get_opportunities(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = None,
    location: str | None = None,
    source: str | None = None,
):
    try:
        return await opportunity_client.get_opportunities(
            page=page,
            limit=limit,
            search=search,
            location=location,
            source=source,
        )

    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=e.response.status_code,
            detail="Opportunity Service returned an error",
        )

    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Opportunity Service is unavailable",
        )


@router.get("/{opportunity_id}")
async def get_opportunity_by_id(opportunity_id: str):
    try:
        return await opportunity_client.get_opportunity_by_id(
            opportunity_id
        )

    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            raise HTTPException(
                status_code=404,
                detail="Opportunity not found",
            )

        raise HTTPException(
            status_code=e.response.status_code,
            detail="Opportunity Service returned an error",
        )

    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Opportunity Service is unavailable",
        )