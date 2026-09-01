from pydantic import BaseModel, Field


class JobOpportunity(BaseModel):
    source: str

    external_id: str | None = None

    title: str
    company: str | None = None
    location: str | None = None

    description: str | None = None
    salary: str | None = None

    external_url: str

    metadata: dict = Field(default_factory=dict)