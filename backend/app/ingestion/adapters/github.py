from datetime import datetime, timezone
import httpx
from app.ingestion.base import SourceAdapter, SourceItem, NormalizedItem

TERMS = (
    "internship",
    "fellowship",
    "scholarship",
    "hackathon",
    "research assistant",
    "open source program",
    "conference",
    "cfp",
    "mentorship",
)


class GitHubAdapter(SourceAdapter):
    def __init__(
        self,
        token: str | None = None,
        query: str = 'is:issue is:open (internship OR fellowship OR hackathon OR "research assistant")',
    ):
        self.token = token
        self.query = query

    async def fetch(self, cursor: dict):
        headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        params = {"q": self.query, "sort": "updated", "order": "desc", "per_page": 50}
        if cursor.get("updated_after"):
            params["q"] += f' updated:>{cursor["updated_after"]}'
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.get(
                "https://api.github.com/search/issues", headers=headers, params=params
            )
            response.raise_for_status()
        now = datetime.now(timezone.utc)
        values = [
            SourceItem(str(x["id"]), x["html_url"], now, x)
            for x in response.json()["items"]
        ]
        latest = max(
            (x.payload["updated_at"] for x in values),
            default=cursor.get("updated_after"),
        )
        return values, {"updated_after": latest}

    def parse(self, item):
        p = item.payload
        text = f'{p.get("title","")} {p.get("body") or ""}'.lower()
        labels = {x["name"].lower() for x in p.get("labels", [])}
        if not any(term in text or term in labels for term in TERMS):
            return None
        repo_url = p.get("repository_url", "")
        org = (
            repo_url.split("/repos/")[-1].split("/")[0]
            if "/repos/" in repo_url
            else "GitHub community"
        )
        return NormalizedItem(
            p["title"],
            org,
            "open_source",
            (p.get("body") or "")[:12000],
            p["html_url"],
            p["html_url"],
            datetime.fromisoformat(p["created_at"].replace("Z", "+00:00")),
            structured={"labels": list(labels), "repository_url": repo_url},
        )
