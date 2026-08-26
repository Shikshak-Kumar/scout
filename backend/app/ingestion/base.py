from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import AsyncIterator, Any


@dataclass(frozen=True)
class SourceItem:
    external_id: str
    source_url: str
    fetched_at: datetime
    payload: dict[str, Any]


@dataclass(frozen=True)
class NormalizedItem:
    title: str
    organization: str
    category: str
    description: str
    source_url: str
    application_url: str | None = None
    source_published_at: datetime | None = None
    deadline_text: str | None = None
    structured: dict | None = None


class SourceAdapter(ABC):
    @abstractmethod
    async def fetch(self, cursor: dict) -> tuple[list[SourceItem], dict]: ...
    @abstractmethod
    def parse(self, item: SourceItem) -> NormalizedItem | None: ...
    def validate(self, item: NormalizedItem) -> bool:
        return bool(
            item.title.strip()
            and item.organization.strip()
            and item.source_url.startswith("https://")
        )

    def identify(self, item: SourceItem) -> str:
        return item.external_id
