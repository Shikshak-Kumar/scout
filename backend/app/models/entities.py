import enum, uuid
from datetime import datetime
from sqlalchemy import (
    String,
    Text,
    DateTime,
    Boolean,
    Float,
    ForeignKey,
    UniqueConstraint,
    Index,
    JSON,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from app.models.base import Base, IdMixin, TimestampMixin


class Verification(str, enum.Enum):
    official = "official"
    verified_source = "verified_source"
    public_source = "public_source"
    unverified = "unverified"


class ApplicationStatus(str, enum.Enum):
    saved = "saved"
    planning = "planning"
    applying = "applying"
    applied = "applied"
    interview = "interview"
    accepted = "accepted"
    rejected = "rejected"
    not_interested = "not_interested"
    expired = "expired"


class User(Base, IdMixin, TimestampMixin):
    __tablename__ = "users"
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    keycloak_id: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    profile: Mapped[dict] = mapped_column(JSON, default=dict)


class Source(Base, IdMixin, TimestampMixin):
    __tablename__ = "sources"
    name: Mapped[str] = mapped_column(String(200), unique=True)
    adapter: Mapped[str] = mapped_column(String(80))
    base_url: Mapped[str] = mapped_column(Text)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    authoritative: Mapped[bool] = mapped_column(Boolean, default=False)
    cursor: Mapped[dict] = mapped_column(JSON, default=dict)
    health: Mapped[str] = mapped_column(String(30), default="not_connected")
    last_success_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    error: Mapped[str | None] = mapped_column(Text)


class RawRecord(Base, IdMixin):
    __tablename__ = "raw_records"
    __table_args__ = (UniqueConstraint("source_id", "external_id"),)
    source_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("sources.id", ondelete="CASCADE"), index=True
    )
    external_id: Mapped[str] = mapped_column(String(500))
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    source_url: Mapped[str] = mapped_column(Text)
    payload: Mapped[dict] = mapped_column(JSON)
    processing_state: Mapped[str] = mapped_column(String(30), default="pending")


class Opportunity(Base, IdMixin, TimestampMixin):
    __tablename__ = "opportunities"
    title: Mapped[str] = mapped_column(String(500), index=True)
    organization: Mapped[str] = mapped_column(String(300), index=True)
    category: Mapped[str] = mapped_column(String(80), index=True)
    description: Mapped[str] = mapped_column(Text)
    source_url: Mapped[str] = mapped_column(Text, unique=True)
    application_url: Mapped[str | None] = mapped_column(Text)
    location: Mapped[str | None] = mapped_column(String(300))
    remote: Mapped[bool | None] = mapped_column(Boolean)
    deadline_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), index=True
    )
    deadline_text: Mapped[str | None] = mapped_column(String(300))
    source_published_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), index=True
    )
    first_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    verification: Mapped[str] = mapped_column(
        String(30), default=Verification.public_source.value
    )
    is_expired: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    structured: Mapped[dict] = mapped_column(JSON, default=dict)
    quality_score: Mapped[float] = mapped_column(Float, default=0)
    embedding: Mapped[list[float] | None] = mapped_column(Vector(1536))
    __table_args__ = (Index("ix_opportunity_feed", "is_expired", "first_seen_at"),)


class SavedOpportunity(Base, IdMixin, TimestampMixin):
    __tablename__ = "saved_opportunities"
    __table_args__ = (UniqueConstraint("user_id", "opportunity_id"),)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    opportunity_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("opportunities.id", ondelete="CASCADE"), index=True
    )
    status: Mapped[str] = mapped_column(
        String(30), default=ApplicationStatus.saved.value, index=True
    )
    notes: Mapped[str | None] = mapped_column(Text)
    application_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    interview_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reminders: Mapped[list] = mapped_column(JSON, default=list)
    opportunity: Mapped["Opportunity"] = relationship()
