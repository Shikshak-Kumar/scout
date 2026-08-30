#!/usr/bin/env python3
"""
Seed the database with legitimate opportunity sources.
Run after the database is created.

Usage:
    python3 seed_sources.py
"""

import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.models.entities import Source
from app.core.config import get_settings


async def seed_sources():
    settings = get_settings()
    
    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=False,
    )
    
    # Create session factory
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    sources = [
        {
            "name": "GitHub Issues - Opportunities",
            "adapter": "github",
            "base_url": "https://api.github.com/search/issues",
            "enabled": True,
            "authoritative": False,  # Public sources
        },
        {
            "name": "MLH - Major League Hacking",
            "adapter": "rss",
            "base_url": "https://mlh.io/feed",
            "enabled": True,
            "authoritative": True,  # Official source
        },
        {
            "name": "LinkedIn Jobs - Internships",
            "adapter": "rss",
            "base_url": "https://www.linkedin.com/jobs/search/?keywords=internship&geoId=92000000&trk=public_jobs_jobs-search-bar_search-submit&position=1&pageNum=0&f_T=9",
            "enabled": False,  # Requires authentication
            "authoritative": False,
        },
        {
            "name": "Indeed - Opportunities",
            "adapter": "rss",
            "base_url": "https://www.indeed.com/rss/jobs?q=internship&l=",
            "enabled": True,
            "authoritative": False,
        },
        {
            "name": "AngelList - Startups",
            "adapter": "rss",
            "base_url": "https://angel.co/feed",
            "enabled": False,  # Check if feed exists
            "authoritative": False,
        },
        {
            "name": "Google Summer of Code",
            "adapter": "rss",
            "base_url": "https://summerofcode.withgoogle.com/feed",
            "enabled": True,
            "authoritative": True,
        },
        {
            "name": "Internships.com",
            "adapter": "rss",
            "base_url": "https://www.internships.com/feeds/latest.xml",
            "enabled": True,
            "authoritative": False,
        },
    ]
    
    async with async_session() as session:
        for source_data in sources:
            # Check if source already exists
            from sqlalchemy import select
            stmt = select(Source).where(Source.name == source_data["name"])
            existing = await session.execute(stmt)
            if existing.scalar_one_or_none():
                print(f"✓ {source_data['name']} already exists")
                continue
            
            # Create new source
            source = Source(**source_data)
            session.add(source)
            print(f"+ Added {source_data['name']}")
        
        await session.commit()
        print("\n✓ Database seeding complete!")


if __name__ == "__main__":
    asyncio.run(seed_sources())
