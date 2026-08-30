from __future__ import annotations

from pydantic import BaseModel
from fastapi import APIRouter

from app.infra.broker import NotificationConsumer

router = APIRouter()
consumer = NotificationConsumer()


class NotificationPreference(BaseModel):
    channel: str
    enabled: bool = True


@router.get("/notifications")
async def list_notifications() -> dict[str, object]:
    return {"status": "ok", "items": consumer.list_notifications()}


@router.get("/preferences")
async def list_preferences() -> dict[str, object]:
    return {"status": "ok", "items": consumer.list_preferences()}


@router.post("/notifications/test-event")
async def test_event() -> dict[str, str]:
    consumer.consume()
    return {"status": "ok", "message": "event consumer started"}


@router.post("/preferences")
async def save_preference(payload: NotificationPreference) -> dict[str, object]:
    item = consumer.add_preference(payload.channel, payload.enabled)
    return {"status": "ok", "item": item}
