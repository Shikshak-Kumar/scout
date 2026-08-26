from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import Source, RawRecord, Opportunity
from app.ingestion.base import SourceAdapter


async def sync_source(db: AsyncSession, source: Source, adapter: SourceAdapter) -> dict:
    created = updated = ignored = 0
    try:
        records, cursor = await adapter.fetch(source.cursor or {})
        for record in records:
            raw = (
                await db.execute(
                    select(RawRecord).where(
                        RawRecord.source_id == source.id,
                        RawRecord.external_id == record.external_id,
                    )
                )
            ).scalar_one_or_none()
            if not raw:
                raw = RawRecord(
                    source_id=source.id,
                    external_id=record.external_id,
                    fetched_at=record.fetched_at,
                    source_url=record.source_url,
                    payload=record.payload,
                )
                db.add(raw)
            normalized = adapter.parse(record)
            if not normalized or not adapter.validate(normalized):
                raw.processing_state = "ignored"
                ignored += 1
                continue
            existing = (
                await db.execute(
                    select(Opportunity).where(
                        Opportunity.source_url == normalized.source_url
                    )
                )
            ).scalar_one_or_none()
            if existing:
                existing.last_seen_at = record.fetched_at
                existing.description = normalized.description
                existing.structured = normalized.structured or {}
                updated += 1
            else:
                db.add(
                    Opportunity(
                        title=normalized.title,
                        organization=normalized.organization,
                        category=normalized.category,
                        description=normalized.description,
                        source_url=normalized.source_url,
                        application_url=normalized.application_url,
                        source_published_at=normalized.source_published_at,
                        deadline_text=normalized.deadline_text,
                        first_seen_at=record.fetched_at,
                        last_seen_at=record.fetched_at,
                        verification=(
                            "official" if source.authoritative else "public_source"
                        ),
                        structured=normalized.structured or {},
                    )
                )
                created += 1
            raw.processing_state = "processed"
        source.cursor = cursor
        source.health = "healthy"
        source.error = None
        source.last_success_at = datetime.now(timezone.utc)
        await db.commit()
        return {
            "fetched": len(records),
            "created": created,
            "updated": updated,
            "ignored": ignored,
        }
    except Exception as exc:
        await db.rollback()
        source.health = "error"
        source.error = str(exc)[:2000]
        await db.commit()
        raise
