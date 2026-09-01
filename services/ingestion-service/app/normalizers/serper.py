import re
from urllib.parse import urlparse

from app.models.job import JobOpportunity


def extract_from_title(raw_title: str) -> tuple[str, str | None]:
    """Extract job title and company from search result title."""

    if not raw_title:
        return "", None

    # Pattern:
    # Software Engineer at Google
    match = re.match(
        r"^(.*?)\s+at\s+(.+?)(?:\s+[—|]\s+.*)?$",
        raw_title,
        re.IGNORECASE,
    )

    if match:
        return (
            match.group(1).strip(),
            match.group(2).strip(),
        )

    # Pattern:
    # Google hiring Software Engineer
    match = re.match(
        r"^(.+?)\s+hiring\s+(.+?)(?:\s+in\s+.*)?$",
        raw_title,
        re.IGNORECASE,
    )

    if match:
        return (
            match.group(2).strip(),
            match.group(1).strip(),
        )

    return raw_title.strip(), None


def extract_company_from_linkedin_url(url: str) -> str | None:
    """
    Example:
    software-engineer-at-cheil-india-4428430909
                         ↓
                    Cheil India
    """

    if not url or "linkedin.com" not in url:
        return None

    path = urlparse(url).path

    # Get last meaningful slug
    slug = path.rstrip("/").split("/")[-1]

    # Look for "-at-company-name-123456"
    match = re.search(
        r"-at-(.+?)-\d+$",
        slug,
        re.IGNORECASE,
    )

    if not match:
        return None

    company_slug = match.group(1)

    # Convert hyphens to spaces
    company = company_slug.replace("-", " ")

    return company.title()


def normalize_serper_job(job: dict) -> JobOpportunity:
    raw_title = job.get("title", "")
    external_url = job.get("external_url", "")

    title, company = extract_from_title(raw_title)

    # Fallback: extract company from LinkedIn URL
    if not company:
        company = extract_company_from_linkedin_url(external_url)

    return JobOpportunity(
        source=job.get("source", "web"),
        external_id=None,
        title=title,
        company=company,
        location=job.get("location"),
        description=job.get("snippet"),
        salary=None,
        external_url=external_url,
        metadata={
            "discovered_via": "serper",
            "raw_title": raw_title,
        },
    )