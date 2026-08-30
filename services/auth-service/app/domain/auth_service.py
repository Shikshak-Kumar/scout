class AuthDomainService:
    """Domain boundary for authentication operations."""

    def __init__(self) -> None:
        self.name = "auth-service"

    async def verify_token(self, token: str) -> dict:
        return {"token": token, "valid": True, "service": self.name}
