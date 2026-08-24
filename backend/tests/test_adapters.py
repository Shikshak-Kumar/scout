from datetime import datetime,timezone
from app.ingestion.base import SourceItem
from app.ingestion.adapters.github import GitHubAdapter
def test_github_rejects_unrelated_issue():
    item=SourceItem("1","https://github.com/acme/repo/issues/1",datetime.now(timezone.utc),{"title":"Fix typo","body":"documentation only","labels":[],"html_url":"https://github.com/acme/repo/issues/1","repository_url":"https://api.github.com/repos/acme/repo","created_at":"2026-01-01T00:00:00Z"})
    assert GitHubAdapter().parse(item) is None
def test_github_accepts_actual_opportunity():
    item=SourceItem("2","https://github.com/acme/repo/issues/2",datetime.now(timezone.utc),{"title":"Open source fellowship applications","body":"Apply for our fellowship","labels":[],"html_url":"https://github.com/acme/repo/issues/2","repository_url":"https://api.github.com/repos/acme/repo","created_at":"2026-01-01T00:00:00Z"})
    assert GitHubAdapter().parse(item).organization=="acme"

