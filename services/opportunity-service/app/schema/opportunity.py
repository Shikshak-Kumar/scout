from datetime import datetime

from pydantic import BaseModel, Field


class OpportunityBase(BaseModel):
    title: str
    company: str
    description: str | None = None
    location: str | None = None

    job_type: str | None = None
    workplace_type: str | None = None

    skills: list[str] = Field(default_factory=list)

    salary: str | None = None

    source: str | None = None
    source_url: str | None = None


class OpportunityCreate(OpportunityBase):
    pass


class OpportunityResponse(OpportunityBase):
    id: str

    posted_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None