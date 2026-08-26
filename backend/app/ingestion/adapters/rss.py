from datetime import datetime, timezone
import feedparser, httpx
from app.ingestion.base import SourceAdapter, SourceItem, NormalizedItem


class RSSAdapter(SourceAdapter):
    def __init__(self, url: str, name: str):
        self.url = url
        self.name = name

    async def fetch(self, cursor):
        headers = {}
        if cursor.get("etag"):
            headers["If-None-Match"] = cursor["etag"]
        async with httpx.AsyncClient(timeout=30, follow_redirects=True) as c:
            r = await c.get(self.url, headers=headers)
        if r.status_code == 304:
            return [], cursor
        r.raise_for_status()
        parsed = feedparser.loads(r.content)
        now = datetime.now(timezone.utc)
        items = [
            SourceItem(str(e.get("id") or e.get("link")), e.get("link"), now, dict(e))
            for e in parsed.entries
            if e.get("link")
        ]
        return items, {"etag": r.headers.get("etag"), "last_checked": now.isoformat()}

    def parse(self, item):
        p = item.payload
        published = None
        if p.get("published_parsed"):
            published = datetime(*p["published_parsed"][:6], tzinfo=timezone.utc)
        return NormalizedItem(
            p.get("title", "").strip(),
            self.name,
            "general",
            p.get("summary", "")[:12000],
            item.source_url,
            item.source_url,
            published,
            structured={"feed_url": self.url},
        )
