from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr, Field, HttpUrl

class RegisterIn(BaseModel): email: EmailStr; password: str = Field(min_length=10, max_length=128)
class LoginIn(BaseModel): email: EmailStr; password: str
class TokenPair(BaseModel): access_token: str; refresh_token: str; token_type: str = "bearer"
class RefreshIn(BaseModel): refresh_token: str
class OpportunityOut(BaseModel):
    model_config=ConfigDict(from_attributes=True)
    id: UUID; title: str; organization: str; category: str; description: str; source_url: str; application_url: str|None; location: str|None; remote: bool|None; deadline_at: datetime|None; deadline_text: str|None; first_seen_at: datetime; last_seen_at: datetime; verification: str; quality_score: float
class FeedOut(BaseModel): items: list[OpportunityOut]; next_cursor: str|None; last_updated: datetime|None
class SavedIn(BaseModel): status: str = "saved"; notes: str|None = None
