import asyncio

from app.scrapers.indeed import IndeedScraper


async def main():
    scraper = IndeedScraper(
        query="Software Engineer",
        location="India",
    )

    jobs = await scraper.fetch_jobs()

    print(f"Jobs found: {len(jobs)}")

    for job in jobs[:5]:
        print(job)


asyncio.run(main())