from celery import Celery
from app.core.config import get_settings

settings = get_settings()
celery = Celery(
    "scout",
    broker=settings.redis_url,
    backend=settings.redis_url,
    include=["app.tasks.ingestion"],
)
celery.conf.update(
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    task_routes={"app.tasks.ingestion.*": {"queue": "ingestion"}},
    beat_schedule={
        "sync-sources": {
            "task": "app.tasks.ingestion.sync_all_sources",
            "schedule": 900.0,
        },
        "expire-opportunities": {
            "task": "app.tasks.ingestion.expire_opportunities",
            "schedule": 3600.0,
        },
    },
)
