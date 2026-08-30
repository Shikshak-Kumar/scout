class NotificationDomainService:
    """Domain boundary for notification matching and delivery."""

    def __init__(self) -> None:
        self.name = "notification-service"

    async def match_and_send(self, opportunity_id: str) -> dict:
        return {"service": self.name, "opportunity_id": opportunity_id, "sent": 0}
