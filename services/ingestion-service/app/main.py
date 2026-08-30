from fastapi import FastAPI

from app.api.routes import router

app = FastAPI(title="Ingestion Service", version="1.0.0")
app.include_router(router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/")
async def root() -> dict[str, str]:
    return {"service": "ingestion-service", "status": "ok"}
