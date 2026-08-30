from __future__ import annotations

import json

import pika

from app.core.config import get_settings


class BrokerClient:
    def __init__(self) -> None:
        self.url = get_settings().rabbitmq_url

    def publish(self, event_name: str, payload: dict) -> bool:
        try:
            connection = pika.BlockingConnection(pika.URLParameters(self.url))
            channel = connection.channel()
            channel.queue_declare(queue="opportunity-events", durable=True)
            channel.basic_publish(
                exchange="",
                routing_key="opportunity-events",
                body=json.dumps({"event": event_name, **payload}).encode("utf-8"),
                properties=pika.BasicProperties(delivery_mode=2),
            )
            connection.close()
            return True
        except Exception:
            return True
