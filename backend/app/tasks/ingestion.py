import asyncio
from datetime import datetime, timezone
from sqlalchemy import select, update
from app.tasks.celery_app import celery
from app.db.session import SessionLocal
from app.models import Source, Opportunity
from app.core.config import get_settings
from app.ingestion.adapters.github import GitHubAdapter
from app.ingestion.adapters.rss import RSSAdapter
from app.services.ingestion import sync_source


def adapter_for(source):
    if source.adapter == "github":
        query = (source.cursor or {}).get("query")
        return (
            GitHubAdapter(get_settings().github_token, query)
            if query
            else GitHubAdapter(get_settings().github_token)
        )
    if source.adapter == "rss":
        return RSSAdapter(source.base_url, source.name)
    raise ValueError(f"Unsupported adapter: {source.adapter}")


async def _sync_all():
    async with SessionLocal() as db:
        sources = (
            (await db.execute(select(Source).where(Source.enabled))).scalars().all()
        )
        for source in sources:
            try:
                await sync_source(db, source, adapter_for(source))
            except Exception:
                continue


@celery.task(
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_jitter=True,
    max_retries=5,
)
def sync_all_sources(self):
    return asyncio.run(_sync_all())


@celery.task
def expire_opportunities():
    async def run():
        async with SessionLocal() as db:
            await db.execute(
                update(Opportunity)
                .where(Opportunity.deadline_at < datetime.now(timezone.utc))
                .values(is_expired=True)
            )
            await db.commit()

    return asyncio.run(run())
