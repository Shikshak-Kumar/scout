def normalize_greenhouse_job(
    job: dict,
    source: dict,
) -> dict:
    return {
        "external_id": (
            f"greenhouse_{source['board_token']}_{job['id']}"
        ),
        "source": "greenhouse",
        "source_job_id": str(job["id"]),
        "company": job.get(
            "company_name",
            source.get("company"),
        ),
        "title": job.get("title"),
        "location": job.get("location", {}).get("name"),
        "external_url": job.get("absolute_url"),
        "language": job.get("language"),
        "source_updated_at": job.get("updated_at"),
        "first_published_at": job.get("first_published"),
        "is_active": True,
    }