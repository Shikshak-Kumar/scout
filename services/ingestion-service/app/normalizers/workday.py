from app.models.job import JobOpportunity


def normalize_workday_job(
    job: dict,
    source: dict,
) -> JobOpportunity:

    return JobOpportunity(
        source="workday",

        external_id=(
            str(job.get("externalPath"))
            if job.get("externalPath")
            else job.get("id")
        ),

        title=job.get("title", ""),

        company=source.get("company"),

        location=job.get("locationsText"),

        description=None,

        external_url=(
            f"https://{source['host']}{job['externalPath']}"
            if job.get("externalPath")
            else ""
        ),

        metadata={
            "source_id": source.get("id"),
            "tenant": source.get("tenant"),
            "site": source.get("site"),
            "host": source.get("host"),
            "posted_on": job.get("postedOn"),
            "bullet_fields": job.get("bulletFields"),
        },
    )