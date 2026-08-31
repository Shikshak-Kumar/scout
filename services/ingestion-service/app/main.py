from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import router
from app.infra.database import db


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await db.command("ping")
        print("✅ Ingestion Service connected to MongoDB!")
    except Exception as e:
        print(f"❌ MongoDB connection failed: {e}")

    yield

    print("🔌 Ingestion Service shutting down")


app = FastAPI(
    title="Ingestion Service",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(router)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/")
async def root():
    return {
        "service": "ingestion-service",
        "status": "ok",
    }