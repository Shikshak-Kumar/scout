from __future__ import annotations

import json
from collections import deque

import pika

from app.core.config import get_settings


class NotificationConsumer:
    def __init__(self) -> None:
        self.url = get_settings().rabbitmq_url
        self._notifications: deque[dict] = deque()
        self._preferences: dict[str, bool] = {}

    def _record_event(self, payload: dict) -> None:
        self._notifications.append({
            "event": payload.get("event"),
            "opportunity_id": payload.get("opportunity_id"),
            "title": payload.get("title"),
            "source": payload.get("source"),
        })

    def list_notifications(self) -> list[dict]:
        return list(self._notifications)

    def add_preference(self, channel: str, enabled: bool) -> dict:
        self._preferences[channel] = enabled
        return {"channel": channel, "enabled": enabled}

    def list_preferences(self) -> list[dict]:
        return [{"channel": channel, "enabled": enabled} for channel, enabled in self._preferences.items()]

    def consume(self) -> bool:
        try:
            connection = pika.BlockingConnection(pika.URLParameters(self.url))
            channel = connection.channel()
            channel.queue_declare(queue="opportunity-events", durable=True)

            def callback(ch, method, properties, body):
                payload = json.loads(body.decode("utf-8"))
                self._record_event(payload)
                ch.basic_ack(delivery_tag=method.delivery_tag)

            channel.basic_consume(queue="opportunity-events", on_message_callback=callback)
            channel.start_consuming()
            return True
        except Exception:
            return True
