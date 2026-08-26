from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.core.config import get_settings
from app.db.session import engine
from app.models import Base
from app.api import auth, opportunities


@asynccontextmanager
async def lifespan(app):
    if get_settings().environment == "development":
        async with engine.begin() as conn:
            await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title="Scout API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_settings().allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth.router, prefix="/v1")
app.include_router(opportunities.router, prefix="/v1")


@app.get("/health")
async def health():
    return {"status": "ok"}
