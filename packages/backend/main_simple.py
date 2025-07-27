"""
FastAPI Application - Simplified for Docker Testing
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import redis
import psycopg2
from sqlalchemy import create_engine, text
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Criar aplicação FastAPI
app = FastAPI(
    title="LITIG-1 API - Docker Test",
    description="Simplified API for Docker environment testing",
    version="1.0.0",
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "LITIG-1 API - Docker Test Environment", "status": "running"}

@app.get("/health")
def health_check():
    """Endpoint de saúde que testa todas as conexões"""
    health_status = {
        "api": "healthy",
        "database": "unknown",
        "redis": "unknown",
        "timestamp": "2025-01-26T15:00:00Z"
    }
    
    # Testar PostgreSQL
    try:
        database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres123@database:5432/litig1_dev")
        engine = create_engine(database_url)
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            health_status["database"] = "healthy"
            logger.info("PostgreSQL connection: OK")
    except Exception as e:
        health_status["database"] = f"error: {str(e)}"
        logger.error(f"PostgreSQL connection failed: {e}")
    
    # Testar Redis
    try:
        redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
        r = redis.from_url(redis_url)
        r.ping()
        health_status["redis"] = "healthy"
        logger.info("Redis connection: OK")
    except Exception as e:
        health_status["redis"] = f"error: {str(e)}"
        logger.error(f"Redis connection failed: {e}")
    
    return health_status

@app.get("/test-database")
def test_database():
    """Testar conexão específica com o banco"""
    try:
        database_url = os.getenv("DATABASE_URL")
        engine = create_engine(database_url)
        with engine.connect() as connection:
            result = connection.execute(text("SELECT version()"))
            version = result.fetchone()[0]
            return {"status": "success", "postgres_version": version}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/test-redis")
def test_redis():
    """Testar conexão específica com Redis"""
    try:
        redis_url = os.getenv("REDIS_URL")
        r = redis.from_url(redis_url)
        info = r.info()
        return {
            "status": "success", 
            "redis_version": info.get("redis_version"),
            "connected_clients": info.get("connected_clients")
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/environment")
def show_environment():
    """Mostrar variáveis de ambiente (sem chaves sensíveis)"""
    env_vars = {
        "DATABASE_URL": os.getenv("DATABASE_URL", "Not set")[:50] + "...",
        "REDIS_URL": os.getenv("REDIS_URL", "Not set"),
        "DEBUG": os.getenv("DEBUG", "Not set"),
        "ENVIRONMENT": os.getenv("ENVIRONMENT", "Not set"),
        "APP_URL": os.getenv("APP_URL", "Not set"),
    }
    return {"environment_variables": env_vars}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 