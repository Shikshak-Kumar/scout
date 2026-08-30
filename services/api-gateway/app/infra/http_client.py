from __future__ import annotations

import httpx


class ServiceClient:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")

    async def get(self, path: str, *, params: dict | None = None, headers: dict | None = None):
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.base_url}{path}", params=params, headers=headers)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPError as exc:
            return {"status": "degraded", "service": self.base_url, "error": str(exc)}

    async def post(self, path: str, *, json: dict | None = None, headers: dict | None = None):
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.post(f"{self.base_url}{path}", json=json, headers=headers)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPError as exc:
            return {"status": "degraded", "service": self.base_url, "error": str(exc)}
