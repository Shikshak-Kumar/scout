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

def normalize_workday_job(
    job: dict,
    source: dict,
) -> dict:
    external_path = job.get("externalPath", "")

    return {
        "external_id": (
            f"workday_{source['tenant']}_{external_path}"
        ),
        "source": "workday",
        "source_job_id": external_path,
        "company": source.get("company"),
        "title": job.get("title"),
        "location": job.get("locationsText"),
        "external_url": (
            f"https://{source['host']}"
            f"/{source['site']}"
            f"{external_path}"
        ),
        "posted_at": job.get("postedOn"),
        "is_active": True,
    }