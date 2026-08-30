from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.core.config import get_settings
from app.db.session import engine
from app.models import Base
from app.api import auth, opportunities


async def ensure_database_schema() -> None:
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)

        user_exists = (
            await conn.execute(
                text(
                    "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='users')"
                )
            )
        ).scalar_one()
        if not user_exists:
            return

        columns = {
            row[0]
            for row in (
                await conn.execute(
                    text(
                        "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='users'"
                    )
                )
            ).all()
        }
        if "keycloak_id" not in columns:
            await conn.execute(
                text("ALTER TABLE users ADD COLUMN IF NOT EXISTS keycloak_id VARCHAR(255)")
            )
        if "password_hash" not in columns:
            await conn.execute(
                text(
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT 'dev-user-password'"
                )
            )

        index_names = {
            row[0]
            for row in (
                await conn.execute(
                    text(
                        "SELECT indexname FROM pg_indexes WHERE schemaname='public' AND tablename='users'"
                    )
                )
            ).all()
        }
        if "ix_users_keycloak_id" not in index_names:
            await conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_keycloak_id ON users (keycloak_id)"
                )
            )


@asynccontextmanager
async def lifespan(app):
    if get_settings().environment == "development":
        await ensure_database_schema()
    yield


app = FastAPI(title="Scout API", version="1.0.0", lifespan=lifespan)

if get_settings().environment == "development":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex="https?://.*",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
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
