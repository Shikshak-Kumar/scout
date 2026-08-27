from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr, HttpUrl


class OpportunityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    title: str
    organization: str
    category: str
    description: str
    source_url: str
    application_url: str | None
    location: str | None
    remote: bool | None
    deadline_at: datetime | None
    deadline_text: str | None
    first_seen_at: datetime
    last_seen_at: datetime
    verification: str
    quality_score: float


class FeedOut(BaseModel):
    items: list[OpportunityOut]
    next_cursor: str | None
    last_updated: datetime | None


class SavedIn(BaseModel):
    status: str = "saved"
    notes: str | None = None
    application_date: datetime | None = None
    interview_date: datetime | None = None


class SavedOpportunityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    opportunity_id: UUID
    status: str
    notes: str | None
    application_date: datetime | None
    interview_date: datetime | None
    opportunity: OpportunityOut


class ProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    email: EmailStr
    profile: dict


class ProfileUpdateIn(BaseModel):
    profile: dict
