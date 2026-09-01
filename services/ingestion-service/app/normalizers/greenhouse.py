from app.models.job import JobOpportunity


def normalize_greenhouse_job(
    job: dict,
    source: dict,
) -> JobOpportunity:

    return JobOpportunity(
        source="greenhouse",
        external_id=str(job.get("id")) if job.get("id") else None,

        title=job.get("title", ""),

        company=(
            job.get("company_name")
            or source.get("company")
        ),

        location=(
            job.get("location", {}).get("name")
            if job.get("location")
            else None
        ),

        description=job.get("content"),

        external_url=job.get("absolute_url", ""),

        metadata={
            "source_id": source.get("id"),
            "internal_job_id": job.get("internal_job_id"),
            "requisition_id": job.get("requisition_id"),
            "updated_at": job.get("updated_at"),
            "first_published": job.get("first_published"),
            "language": job.get("language"),
        },
    )