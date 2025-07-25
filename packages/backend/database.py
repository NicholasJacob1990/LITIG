from sqlalchemy.ext.asyncio import (
    async_sessionmaker, AsyncSession, create_async_engine
)
from sqlalchemy.orm import DeclarativeBase
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:password@db.litgo.internal:5432/postgres"
)

engine = create_async_engine(DATABASE_URL, echo=False, pool_pre_ping=True)

async_session: async_sessionmaker[AsyncSession] = async_sessionmaker(
    engine, expire_on_commit=False
)

class Base(DeclarativeBase):  # Alembic usa isso
    pass

async def get_async_session() -> AsyncSession:
    async with async_session() as session:
        yield session 