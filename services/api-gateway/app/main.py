from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router


app = FastAPI(
    title="Scout API Gateway",
)

# Allow Flutter Web (and any browser-based client) to reach the API.
# In production, replace "*" with your actual frontend origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(
    router,
    prefix="/api",
)


@app.get("/")
async def root():
    return {
        "service": "api-gateway",
        "status": "ok",
    }