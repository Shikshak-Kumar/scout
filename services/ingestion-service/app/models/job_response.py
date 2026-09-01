from datetime import datetime

from pydantic import BaseModel


class JobResponse(BaseModel):
    id: str
    source: str
    external_id: str | None = None
    title: str
    company: str | None = None
    location: str | None = None
    description: str | None = None
    salary: str | None = None
    external_url: str
    metadata: dict = {}
    active: bool = True
    first_seen_at: datetime | None = None
    last_seen_at: datetime | None = None


class PaginationResponse(BaseModel):
    page: int
    limit: int
    total: int
    total_pages: int


class JobsListResponse(BaseModel):
    items: list[JobResponse]
    pagination: PaginationResponse