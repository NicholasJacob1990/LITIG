# backend/main.py
import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from prometheus_fastapi_instrumentator import Instrumentator
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from backend.main_routes import router as api_router
# from backend.routes import (
#     auth, cases, users, contracts, matching,
#     support, admin, ab_testing, ocr, payments,
#     notifications, reviews, video, reports
# )
from backend.routes.cases import router as cases_router
from backend.routes.consultations import router as consultations_router
from backend.routes.contracts import router as contracts_router
from backend.routes.documents import router as documents_router
from backend.routes.health_routes import router as health_router
from backend.routes.intelligent_triage_routes import router as triage_router
from backend.routes.offers import router as offers_router
from backend.routes.process_events import router as process_events_router
from backend.routes.recommendations import router as recommendations_router
from backend.routes.reviews_route import router as reviews_router
from backend.routes.tasks import router as tasks_router
from backend.routes.tasks_routes import router as celery_tasks_router
from backend.routes.webhooks import router as webhooks_router
from backend.routes.weights import router as weights_router
from backend.routes.ab_testing import router as ab_testing_router
from backend.routes.reports import router as reports_router
from backend.services.cache_service_simple import close_simple_cache, init_simple_cache
from backend.services.redis_service import redis_service

# --- Configuração de Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

# --- Configuração do Rate Limiting ---
limiter = Limiter(key_func=get_remote_address)

# --- Lifecycle do App (Cache, Redis, etc.) ---


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Iniciando serviços da aplicação...")
    try:
        # Inicializa o serviço de Redis principal
        await redis_service.initialize()
        logger.info("Redis Service inicializado.")

        # Inicializa o cache simples (que também pode usar Redis)
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        await init_simple_cache(redis_url)
        logger.info("Simple Cache Service inicializado.")

    except Exception as e:
        logger.error(f"Erro crítico durante a inicialização dos serviços: {e}")
        # Decide-se por não levantar a exceção para permitir que a API
        # suba mesmo sem Redis, mas com funcionalidade limitada.

    yield

    # Shutdown
    logger.info("Finalizando serviços da aplicação...")
    try:
        await close_simple_cache()
        logger.info("Simple Cache Service finalizado.")
    except Exception as e:
        logger.error(f"Erro ao fechar Simple Cache Service: {e}")

    try:
        await redis_service.close()
        logger.info("Redis Service finalizado.")
    except Exception as e:
        logger.error(f"Erro ao fechar Redis Service: {e}")

app = FastAPI(
    title="LITGO API",
    description="API para o sistema de match jurídico inteligente.",
    version="1.0.0",
    lifespan=lifespan,
)

# Adiciona os middlewares na aplicação
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# --- Configuração do CORS ---
# Configuração dinâmica baseada no ambiente
if os.getenv("ENVIRONMENT") == "production":
    origins = [
        os.getenv("FRONTEND_URL", "https://app.litgo.com"),
    ]
else:
    origins = [
        "http://localhost",
        "http://localhost:*",  # Permite qualquer porta do localhost
        "http://localhost:8081",  # Porta padrão do Expo Go
        "http://localhost:3000",  # Porta padrão de apps React
        "http://127.0.0.1:8081",  # Variação local
        "http://127.0.0.1:3000",  # Variação local
        "http://localhost:54857", # Porta do app Flutter em modo de desenvolvimento web
        "http://127.0.0.1:*",     # Permite qualquer porta do 127.0.0.1
        "*",  # Permite todas as origens em desenvolvimento
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"] if os.getenv(
        "ENVIRONMENT") == "production" else ["*"],
    allow_headers=["*"],
)

# --- Instrumentação para Prometheus ---
Instrumentator().instrument(app).expose(app)

# --- Inclusão das Rotas ---
app.include_router(api_router, prefix="/api")
app.include_router(offers_router, prefix="/api")
app.include_router(contracts_router, prefix="/api")
app.include_router(reviews_router, prefix="/api")
app.include_router(webhooks_router)
app.include_router(weights_router, prefix="/api/v2.2", tags=["Weights & Debugging"])
app.include_router(recommendations_router, prefix="/api", tags=["Recommendations"])
app.include_router(consultations_router, prefix="/api")
app.include_router(documents_router, prefix="/api")
app.include_router(process_events_router, prefix="/api")
app.include_router(tasks_router, prefix="/api")
app.include_router(celery_tasks_router, prefix="/api")
app.include_router(cases_router, prefix="/api")
app.include_router(health_router, prefix="/api")
app.include_router(triage_router, prefix="/api/v2", tags=["Intelligent Triage"])
app.include_router(ab_testing_router, prefix="/api/v2.2", tags=["AB Testing"])
app.include_router(reports_router, prefix="/api/v2.2", tags=["Reports"])

# CORREÇÃO: Rate limiter aplicado individualmente nas rotas em routes.py
# Removido limiter.limit("60/minute")(api_router) que causava erro nos testes


@app.get("/", tags=["Root"])
async def read_root():
    """Endpoint raiz para verificar o status da API."""
    return {"status": "ok", "message": "Bem-vindo à API LITGO!"}


@app.get("/cache/stats", tags=["Monitoring"])
async def get_cache_stats():
    """Retorna estatísticas do cache Redis."""
    from backend.services.cache_service_simple import simple_cache_service
    stats = await simple_cache_service.get_cache_stats()
    return stats


@app.get("/metrics", tags=["Monitoring"])
async def get_metrics():
    """Endpoint para Prometheus coletar métricas."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# Configuração de Logging
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="0.0.0.0", port=8000)
