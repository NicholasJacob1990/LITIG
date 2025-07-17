#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FastAPI - Sistema de Matching Jurídico LITGO5
Versão HÍBRIDA com dados do Escavador e Jusbrasil
"""

import asyncio
import hashlib
import json
import logging
import os
import time
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

# Configuração de environment
from dotenv import load_dotenv

# Imports externos
try:
    import numpy as np
    import psycopg2
    import psycopg2.extras
    import redis.asyncio as aioredis
    from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, Query, status
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from pydantic import BaseModel, Field
except ImportError as e:
    print(f"Erro: Dependência não instalada: {e.name}")
    print("Execute: pip install -r requirements.txt")
    exit(1)

# Imports locais
from backend.algoritmo_match import (
    KPI,
    Case,
    DiversityMeta,
    Lawyer,
    MatchmakingAlgorithm,
    load_weights, # ⚡ Adicionar import da função load_weights
)
from backend.routes import (
    cases, recommendations, payments, offers, reviews_route, timeline, contracts, financials,
    availability, directory_search, hiring_proposals
)
from backend.api.schemas import (
    CaseRequestSchema,
    EquityDataUpdate,
    ErrorResponseSchema,
    ExplainabilitySchema,
    HealthCheckSchema,
    LawyerListResponseSchema,
    MatchedLawyerSchema,
    MatchRequestSchema,
    MatchResponseSchema,
    SyncStatusSchema,
)

# -------------------------------------------------------------
# ⚡ CHAVE 4: Recarregamento automático de pesos sem downtime
# -------------------------------------------------------------
import pathlib

# Configuração de polling de pesos
WEIGHTS_POLL_SECONDS = int(os.getenv("WEIGHTS_POLL_SECONDS", "300"))  # 5 minutos padrão
WEIGHTS_PATH = pathlib.Path(os.getenv("WEIGHTS_PATH", "packages/backend/models/ltr_weights.json"))

# -------------------------------------------------------------
# Armazenamento de resultados para explicability (Redis TTL 1h)
# -------------------------------------------------------------
EXPLAIN_TTL_SEC = 3600  # 1 hora

from backend.auth import get_current_user
from backend.services.ab_testing import ab_testing_service
from backend.services.hybrid_integration import HybridLegalDataService

# Configuração
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
ESCAVADOR_API_KEY = os.getenv("ESCAVADOR_API_KEY")
JUSBRASIL_API_KEY = os.getenv("JUSBRASIL_API_KEY")

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="LITGO5 - API de Matching Jurídico HÍBRIDA",
    description="API para matching inteligente usando dados do Escavador (primário) e Jusbrasil (fallback).",
    version="3.0.0-hybrid",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ⚡ CHAVE 4: Background task para polling automático de pesos
@app.on_event("startup")
async def start_weights_polling():
    """
    Inicia o polling automático de pesos LTR.
    Verifica mudanças no arquivo de pesos a cada WEIGHTS_POLL_SECONDS.
    """
    async def _poll_weights():
        """Task de polling que roda em background."""
        last_mtime = 0
        logger.info(f"Iniciando polling de pesos: {WEIGHTS_PATH} (intervalo: {WEIGHTS_POLL_SECONDS}s)")
        
        while True:
            try:
                if WEIGHTS_PATH.exists():
                    current_mtime = WEIGHTS_PATH.stat().st_mtime
                    if current_mtime != last_mtime and last_mtime != 0:
                        logger.info("Arquivo de pesos modificado - recarregando...")
                        new_weights = load_weights()
                        logger.info(f"Pesos atualizados: {new_weights}")
                    last_mtime = current_mtime
                else:
                    logger.warning(f"Arquivo de pesos não encontrado: {WEIGHTS_PATH}")
            except Exception as e:
                logger.error(f"Erro no polling de pesos: {e}")
            
            await asyncio.sleep(WEIGHTS_POLL_SECONDS)
    
    # Criar task em background
    asyncio.create_task(_poll_weights())

# Incluir os roteadores
app.include_router(cases.router, prefix="/api")
app.include_router(recommendations.router, prefix="/api")
app.include_router(payments.router, prefix="/api")
app.include_router(offers.router, prefix="/api")
app.include_router(reviews_route.router, prefix="/api")
app.include_router(timeline.router, prefix="/api")
app.include_router(contracts.router, prefix="/api")
app.include_router(financials.router, prefix="/api")
app.include_router(availability.router, prefix="/api")
app.include_router(directory_search.router, prefix="/api")
app.include_router(hiring_proposals.router, prefix="/api")

# Conexão Redis global
redis_client: Optional[aioredis.Redis] = None

# ============================================================================
# STARTUP/SHUTDOWN
# ============================================================================


@app.on_event("startup")
async def startup_event():
    """Inicialização da aplicação"""
    global redis_client
    if REDIS_URL:
        try:
            redis_client = aioredis.from_url(REDIS_URL, decode_responses=True)
            if redis_client:
                await redis_client.ping()
            logger.info("✅ Conectado ao Redis")
        except Exception as e:
            logger.warning(f"⚠️ Redis não disponível: {e}")
            redis_client = None

    # Verificar conexão com PostgreSQL
    try:
        conn = get_db_connection()
        conn.close()
        logger.info("✅ Conectado ao PostgreSQL")
    except Exception as e:
        logger.error(f"❌ Erro ao conectar com PostgreSQL: {e}")

    logger.info("🚀 API LITGO5 HÍBRIDA iniciada")


@app.on_event("shutdown")
async def shutdown_event():
    """Limpeza na parada da aplicação"""
    global redis_client
    if redis_client:
        await redis_client.close()
    logger.info("🔻 API LITGO5 HÍBRIDA encerrada")

# ============================================================================
# DEPENDÊNCIAS
# ============================================================================


async def get_redis() -> Optional[aioredis.Redis]:
    """Dependency para Redis"""
    return redis_client


def get_db_connection():
    """Cria conexão com PostgreSQL"""
    if not DATABASE_URL:
        raise Exception("DATABASE_URL não configurada")

    return psycopg2.connect(
        DATABASE_URL,
        cursor_factory=psycopg2.extras.DictCursor
    )

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================


def convert_case_schema_to_model(case_data: CaseRequestSchema) -> Case:
    """Converte schema de caso para modelo interno"""
    return Case(
        id=str(uuid.uuid4()),
        area=case_data.area.value,
        subarea=case_data.subarea,
        urgency_h=case_data.urgency_hours,
        coords=(case_data.coordinates.latitude, case_data.coordinates.longitude),
        complexity=case_data.complexity.value,
        # Placeholder - em produção usar modelo real
        summary_embedding=np.random.rand(384)
    )


def convert_lawyer_to_schema(lawyer: Lawyer, case_coords: tuple) -> MatchedLawyerSchema:
    """Converte modelo de advogado para schema de resposta"""

    # Calcular distância
    def haversine(lat1, lon1, lat2, lon2):
        from math import asin, cos, radians, sin, sqrt
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
        return 2 * asin(sqrt(a)) * 6371  # km

    distance = haversine(
        case_coords[0], case_coords[1],
        lawyer.geo_latlon[0], lawyer.geo_latlon[1]
    )

    # Dados realistas do Jusbrasil
    jusbrasil_data = getattr(lawyer, 'jusbrasil_stats', {})

    return MatchedLawyerSchema(
        id=lawyer.id,
        nome=lawyer.nome,
        expertise_areas=lawyer.tags_expertise,
        score=lawyer.scores.get('fair_base', 0.0) if lawyer.scores else 0.0,
        distance_km=round(distance, 1),
        estimated_response_time_hours=lawyer.kpi.tempo_resposta_h,
        rating=lawyer.kpi.avaliacao_media,
        review_texts=getattr(lawyer, 'review_texts', []),
        is_available=getattr(lawyer, 'is_available', False),
        total_cases=jusbrasil_data.get('total_processes', 0),
        estimated_success_rate=jusbrasil_data.get('estimated_success_rate', 0.5),
        specialization_score=jusbrasil_data.get('specialization_score', 0.0),
        activity_level=jusbrasil_data.get('activity_level', 'low'),
        data_quality=jusbrasil_data.get('data_quality', 'unavailable'),
        data_limitations=jusbrasil_data.get('limitations', []),
        coordinates={
            "latitude": lawyer.geo_latlon[0],
            "longitude": lawyer.geo_latlon[1]},
        oab_numero=getattr(lawyer, 'oab_numero', None),
        uf=getattr(lawyer, 'uf', None),
        phone=getattr(lawyer, 'phone', None),
        email=getattr(lawyer, 'email', None)
    )


async def load_lawyers_from_db(
        connection, filters: Optional[dict] = None) -> List[Lawyer]:
    """Carrega advogados do banco de dados com filtros opcionais"""
    cursor = connection.cursor()

    # Query base com novos campos realistas
    query = """
        SELECT
            l.id, l.nome, l.oab_numero, l.uf,
            l.latitude, l.longitude,
            l.kpi, l.curriculo_json,
            l.tags_expertise,
            l.review_texts,
            l.is_available,
            l.success_rate, l.total_cases,
            l.kpi_subarea,
            l.estimated_success_rate,
            l.jusbrasil_areas,
            l.jusbrasil_activity_level,
            l.jusbrasil_specialization,
            l.jusbrasil_data_quality,
            l.jusbrasil_limitations
        FROM lawyers l
        WHERE l.ativo = true
    """

    params = []

    # Aplicar filtros
    if filters:
        if filters.get("area"):
            query += " AND %s = ANY(l.tags_expertise)"
            params.append(filters["area"])

        if filters.get("uf"):
            query += " AND l.uf = %s"
            params.append(filters["uf"])

        if filters.get("coordinates") and filters.get("radius_km"):
            # Filtro geográfico usando Haversine
            lat, lon, radius = filters["coordinates"][0], filters["coordinates"][1], filters["radius_km"]
            query += """
                AND (
                    6371 * acos(
                        cos(radians(%s)) * cos(radians(l.latitude)) *
                        cos(radians(l.longitude) - radians(%s)) +
                        sin(radians(%s)) * sin(radians(l.latitude))
                    )
                ) <= %s
            """
            params.extend([lat, lon, lat, radius])

        if filters.get("min_rating"):
            query += " AND COALESCE((l.kpi->>'avaliacao_media')::float, 0) >= %s"
            params.append(filters["min_rating"])

    # Limitar resultados
    limit = filters.get("limit", 100) if filters else 100
    offset = filters.get("offset", 0) if filters else 0
    query += " ORDER BY l.estimated_success_rate DESC LIMIT %s OFFSET %s"
    params.extend([limit, offset])

    cursor.execute(query, params)
    rows = cursor.fetchall()

    lawyers = []
    for row in rows:
        kpi_data = row.get("kpi", {}) or {}

        lawyer = Lawyer(
            id=row["id"],
            nome=row["nome"],
            tags_expertise=row.get("tags_expertise", []),
            review_texts=row.get("review_texts", []),
            geo_latlon=(row.get("latitude", 0.0), row.get("longitude", 0.0)),
            curriculo_json=row.get("curriculo_json", {}),
            kpi=KPI(
                success_rate=row.get("success_rate", 0.0),
                cases_30d=kpi_data.get("cases_30d", 0),
                capacidade_mensal=kpi_data.get("capacidade_mensal", 25),
                avaliacao_media=kpi_data.get("avaliacao_media", 4.0),
                tempo_resposta_h=kpi_data.get("tempo_resposta_h", 24),
                cv_score=kpi_data.get("cv_score", 0.0)
            ),
            kpi_subarea=row.get("kpi_subarea", {}),
        )

        # Adicionar atributos extras usando setattr para evitar erros do linter
        setattr(lawyer, 'is_available', row.get("is_available", False))
        setattr(lawyer, 'oab_numero', row.get("oab_numero"))
        setattr(lawyer, 'uf', row.get("uf"))

        # Adicionar dados REALISTAS do Jusbrasil
        setattr(lawyer, 'jusbrasil_stats', {
            'total_processes': row.get("total_cases", 0),
            'estimated_success_rate': row.get("estimated_success_rate", 0.5),
            'areas_distribution': row.get("jusbrasil_areas", {}),
            'activity_level': row.get("jusbrasil_activity_level", "low"),
            'specialization_score': row.get("jusbrasil_specialization", 0.0),
            'data_quality': row.get("jusbrasil_data_quality", "unavailable"),
            'limitations': row.get("jusbrasil_limitations", [])
        })

        lawyers.append(lawyer)

    return lawyers

# ============================================================================
# ENDPOINTS DA API
# ============================================================================


@app.get("/",
         response_model=Dict[str, str],
         summary="Página inicial da API")
async def root():
    """Endpoint raiz da API"""
    return {
        "message": "🤖 LITGO5 - API de Matching Jurídico Inteligente HÍBRIDA",
        "version": "3.0.0-hybrid",
        "docs": "/docs",
        "redoc": "/redoc",
        "health": "/health",
        "transparency": "Dados do Jusbrasil são estimativas baseadas em heurísticas"
    }


@app.get("/health",
         response_model=HealthCheckSchema,
         summary="Health check da API")
async def health_check(redis: Optional[aioredis.Redis] = Depends(get_redis)):
    """Verifica saúde dos serviços da API"""
    services = {}

    # Testar Redis
    try:
        if redis:
            await redis.ping()
            services["redis"] = "healthy"
        else:
            services["redis"] = "unavailable"
    except Exception:
        services["redis"] = "unhealthy"

    # Testar PostgreSQL
    try:
        connection = get_db_connection()
        connection.close()
        services["postgresql"] = "healthy"
    except Exception:
        services["postgresql"] = "unhealthy"

    # Status geral
    status = "healthy" if all(s == "healthy" for s in services.values()) else "degraded"

    return HealthCheckSchema(
        status=status,
        version="3.0.0-hybrid",
        services=services
    )


async def enrich_lawyer(lawyer: Lawyer, service: HybridLegalDataService) -> Lawyer:
    """Função auxiliar para enriquecer um advogado com dados híbridos."""
    lawyer_info = {'id': lawyer.id, 'oab_numero': getattr(
        lawyer, 'oab_numero', None), 'uf': getattr(lawyer, 'uf', None)}
    hybrid_stats = await service.get_unified_lawyer_data(lawyer_info)

    # Adicionar os dados ao objeto do advogado
    setattr(lawyer, 'hybrid_stats', hybrid_stats)

    # Atualizar KPI com dados mais precisos
    if hybrid_stats.primary_source == 'escavador':
        lawyer.kpi.success_rate = hybrid_stats.real_success_rate

    return lawyer


@app.post("/api/match",
          response_model=MatchResponseSchema,
          responses={
              400: {
                  "model": ErrorResponseSchema}, 500: {
                  "model": ErrorResponseSchema}},
          summary="Matching inteligente HÍBRIDA de advogados",
          description="Encontra os melhores advogados para um caso usando dados HÍBRIDOS do Escavador e Jusbrasil")
async def match_lawyers(
    request: MatchRequestSchema,
    background_tasks: BackgroundTasks,
    redis: Optional[aioredis.Redis] = Depends(get_redis),
    current_user: Any = Depends(get_current_user)
):
    """
    Endpoint principal para matching de advogados HÍBRIDA.

    Usa algoritmo ML com dados FACTÍVEIS do Jusbrasil:
    - Volume de processos
    - Distribuição por área jurídica
    - Estimativas de performance (não dados reais)
    - Transparência total sobre limitações
    """
    start_time = time.time()

    try:
        # (v2.6) A/B Testing: Obter versão do modelo
        model_version, test_group, test_id = ab_testing_service.get_model_for_request(
            user_id=str(current_user.id))

        # Gerar ID único do caso
        case_id = f"case_{uuid.uuid4().hex[:12]}"

        # Converter request para modelo interno
        case = convert_case_schema_to_model(request.case)
        case.id = case_id

        # Cache key para o matching
        cache_key = f"match_hybrid:{hash(str(request.dict()))}:{model_version}"

        # Verificar cache (opcional)
        if redis:
            cached_result = await redis.get(cache_key)
            if cached_result:
                # Nota: O cache aqui pode não refletir um teste A/B para este usuário específico.
                # Para uma implementação robusta, a chave de cache deveria incluir o
                # `model_version`.
                logger.info(f"Cache hit para matching híbrido {case_id}")
                return JSONResponse(content=json.loads(cached_result))

        # (v2.6) Armazenar dados do teste A/B no Redis para futura conversão
        if redis and test_id and test_group:
            ab_test_info = {
                "test_id": test_id,
                "group": test_group,
                "user_id": str(current_user.id),
                "model_version": model_version
            }
            # TTL de 7 dias para registrar a conversão
            await redis.setex(f"ab_test_info:{case_id}", timedelta(days=7), json.dumps(ab_test_info))
            logger.info(
                f"Usuário {current_user.id} no grupo '{test_group}' do teste '{test_id}' para o caso {case_id}")

        # Conectar ao banco e carregar advogados
        connection = get_db_connection()
        try:
            # Filtros baseados no caso
            filters = {
                "area": request.case.area.value,
                "coordinates": (request.case.coordinates.latitude, request.case.coordinates.longitude),
                "radius_km": 100,  # 100km de raio
                # Carregar mais para melhor seleção
                "limit": min(request.top_n * 10, 200)
            }

            lawyers = await load_lawyers_from_db(connection, filters)

            if not lawyers:
                raise HTTPException(
                    status_code=404,
                    detail="Nenhum advogado encontrado para os critérios especificados"
                )

            # Inicia o serviço híbrido
            if not ESCAVADOR_API_KEY:
                raise HTTPException(status_code=500,
                                    detail="ESCAVADOR_API_KEY não configurada.")

            hybrid_service = HybridLegalDataService(
                db_connection=connection,
                escavador_api_key=ESCAVADOR_API_KEY,
                jusbrasil_api_key=JUSBRASIL_API_KEY
            )

            # Enriquecer advogados com dados HÍBRIDOS
            enrich_tasks = [enrich_lawyer(lawyer, hybrid_service) for lawyer in lawyers]
            enriched_lawyers = await asyncio.gather(*enrich_tasks)

            # ⭐️ ADICIONADO: Exclui o próprio usuário da lista de candidatos
            user_id_to_exclude = str(current_user.id)
            filtered_lawyers = [lawyer for lawyer in enriched_lawyers if lawyer.id != user_id_to_exclude]

            matcher = MatchmakingAlgorithm()
            ranking = await matcher.rank(
                case, filtered_lawyers, request.top_n, request.preset.value, model_version=model_version
            )

            # ---- Armazenar dados de explicabilidade ------------------
            match_id = str(uuid.uuid4())
            if redis:
                try:
                    explain_payload = [lw.scores for lw in ranking]
                    await redis.set(
                        f"match:result:{match_id}",
                        json.dumps(explain_payload, default=str),
                        ex=EXPLAIN_TTL_SEC,
                    )
                except Exception as e:
                    logger.warning(f"Falha ao gravar resultado de match no Redis: {e}")
            else:
                match_id = "local-" + match_id

            # Converter para schema de resposta
            case_coords = (
                request.case.coordinates.latitude,
                request.case.coordinates.longitude)
            matched_lawyers = [
                convert_lawyer_to_schema(lawyer, case_coords)
                for lawyer in ranking
            ]

            # Preparar resposta
            execution_time_ms = (time.time() - start_time) * 1000

            response = MatchResponseSchema(
                success=True,
                case_id=case_id,
                match_id=match_id,
                lawyers=matched_lawyers,
                total_lawyers_evaluated=len(lawyers),
                algorithm_version="v3.0-hybrid",
                preset_used=request.preset,
                execution_time_ms=round(execution_time_ms, 2),
                weights_used=ranking[0].scores.get(
                    "weights_used", {}) if ranking and ranking[0].scores else {},
                case_complexity=request.case.complexity,
                # (v2.6) Adicionar dados do A/B Test na resposta
                ab_test_group=test_group,
                model_version_used=model_version,
                # Adicionar transparência sobre limitações
                data_transparency={
                    "jusbrasil_limitations": [
                        "Dados são estimativas baseadas em heurísticas",
                        "API não fornece vitórias/derrotas reais",
                        "Foco em volume e distribuição de casos",
                        "Adequado para matching por experiência, não performance"
                    ],
                    "estimation_disclaimer": "Taxas de sucesso são estimativas baseadas em padrões históricos do setor"
                }
            )

            # Salvar no cache (TTL de 1 hora)
            if redis:
                await redis.setex(cache_key, 3600, response.json())

            # Log da operação
            logger.info(
                f"Matching HÍBRIDA concluído: {case_id}, {len(matched_lawyers)} advogados, {execution_time_ms:.1f}ms")

            # Task em background para analytics
            background_tasks.add_task(log_matching_analytics, case_id,
                                      request, len(lawyers), execution_time_ms)

            return response

        finally:
            connection.close()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no matching híbrido: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno no matching: {str(e)}"
        )


@app.get("/api/lawyers",
         response_model=LawyerListResponseSchema,
         summary="Listar advogados",
         description="Lista advogados com dados REALISTAS do Jusbrasil")
async def list_lawyers(
    limit: int = Query(20, ge=1, le=100, description="Limite de resultados"),
    offset: int = Query(0, ge=0, description="Offset para paginação")
):
    """Lista advogados com dados REALISTAS e transparência total"""

    try:
        connection = get_db_connection()
        try:
            # Preparar filtros simples
            filters = {"limit": limit, "offset": offset}

            # Carregar advogados
            lawyers = await load_lawyers_from_db(connection, filters)

            # Converter para schema
            case_coords = (0, 0)  # Coordenadas default
            lawyer_schemas = [
                convert_lawyer_to_schema(lawyer, case_coords)
                for lawyer in lawyers
            ]

            return LawyerListResponseSchema(
                success=True,
                lawyers=lawyer_schemas,
                total=len(lawyers),
                limit=limit,
                offset=offset,
                data_transparency={
                    "disclaimer": "Dados do Jusbrasil são estimativas baseadas em heurísticas",
                    "limitations": [
                        "API não categoriza vitórias/derrotas automaticamente",
                        "Processos em segredo de justiça não são retornados",
                        "Adequado para matching por experiência, não performance"
                    ]
                }
            )

        finally:
            connection.close()

    except Exception as e:
        logger.error(f"Erro ao listar advogados: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao buscar advogados: {str(e)}"
        )


@app.get("/api/lawyers/{lawyer_id}/sync-status",
         response_model=SyncStatusSchema,
         summary="Status de sincronização HÍBRIDA do advogado")
async def get_lawyer_sync_status(lawyer_id: str):
    """Obtém status da sincronização HÍBRIDA com Jusbrasil para um advogado"""

    try:
        connection = get_db_connection()
        try:
            cursor = connection.cursor()

            # Buscar dados de sincronização HÍBRIDA
            cursor.execute("""
                SELECT
                    id,
                    last_jusbrasil_sync,
                    total_cases,
                    estimated_success_rate,
                    jusbrasil_data_quality,
                    jusbrasil_limitations,
                    CASE
                        WHEN last_jusbrasil_sync IS NULL THEN 'never_synced'
                        WHEN last_jusbrasil_sync < NOW() - INTERVAL '7 days' THEN 'outdated'
                        ELSE 'up_to_date'
                    END as sync_status
                FROM lawyers
                WHERE id = %s
            """, (lawyer_id,))

            row: Optional[Dict[str, Any]] = cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Advogado não encontrado")

            # Calcular próxima sync (estimativa)
            next_sync = None
            if row.get("last_jusbrasil_sync"):
                from datetime import timedelta
                next_sync = row["last_jusbrasil_sync"] + timedelta(days=7)

            return SyncStatusSchema(
                lawyer_id=lawyer_id,
                last_sync=row.get("last_jusbrasil_sync"),
                total_cases=row.get("total_cases") or 0,
                sync_status=row.get("sync_status"),
                next_sync=next_sync,
                data_quality=row.get("jusbrasil_data_quality", "unavailable"),
                estimated_success_rate=row.get("estimated_success_rate", 0.5),
                limitations=row.get("jusbrasil_limitations", []),
                transparency_note="Dados são estimativas baseadas em heurísticas, não dados reais de performance"
            )

        finally:
            connection.close()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar status de sync: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao buscar status: {str(e)}"
        )


@app.post("/api/admin/sync-lawyer/{lawyer_id}",
          summary="Forçar sincronização HÍBRIDA de advogado",
          description="Força sincronização imediata HÍBRIDA com Jusbrasil (admin only)")
async def force_lawyer_sync(lawyer_id: str, background_tasks: BackgroundTasks):
    """Força sincronização HÍBRIDA de um advogado específico com Jusbrasil"""

    # Em produção, adicionar autenticação de admin aqui

    try:
        # Adicionar task em background
        background_tasks.add_task(sync_lawyer_hybrid_task, lawyer_id)

        return {
            "success": True,
            "message": f"Sincronização HÍBRIDA do advogado {lawyer_id} iniciada em background",
            "lawyer_id": lawyer_id,
            "transparency_note": "Sincronização coletará apenas dados factíveis (volume, distribuição, estimativas)"
        }

    except Exception as e:
        logger.error(f"Erro ao iniciar sync: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao iniciar sincronização: {str(e)}"
        )


@app.patch("/api/lawyers/me/equity",
           status_code=status.HTTP_204_NO_CONTENT,
           summary="Atualizar dados de equidade do advogado",
           description="Permite que o advogado autenticado atualize seus dados de diversidade.")
async def update_equity_data(
    equity_data: EquityDataUpdate,
    current_user: Any = Depends(get_current_user),
    db: Any = Depends(get_db_connection)
):
    """
    Atualiza os dados de equidade para o advogado logado.
    Requer consentimento explícito (timestamp).
    """
    if current_user.role != 'lawyer':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="Apenas advogados podem atualizar seus dados.")

    try:
        with db.cursor() as cursor:
            # O `dict(exclude_unset=True)` garante que apenas os campos enviados sejam
            # atualizados.
            update_payload = equity_data.dict(exclude_unset=True)

            # Remove o `consent_ts` do payload de update do banco, ele serve apenas
            # para registro.
            if 'consent_ts' in update_payload:
                del update_payload['consent_ts']

            if not update_payload:
                return  # Nenhum dado para atualizar

            # Constrói a query de update dinamicamente
            set_clause = ", ".join([f"{key} = %s" for key in update_payload.keys()])
            query = f"UPDATE lawyers SET {set_clause} WHERE id = %s"

            params = list(update_payload.values()) + [current_user.id]

            cursor.execute(query, params)
            db.commit()

            if cursor.rowcount == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                    detail="Advogado não encontrado.")

    except psycopg2.Error as e:
        logger.error(f"Erro de banco de dados ao atualizar dados de equidade: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Erro ao salvar dados.")
    finally:
        db.close()

    return


@app.post("/api/cases/{case_id}/accept",
          status_code=status.HTTP_200_OK,
          summary="Registra a aceitação de um caso por um cliente",
          description="Marca um caso como aceito e registra a conversão para o teste A/B, se aplicável.")
async def accept_case(
    case_id: str,
    background_tasks: BackgroundTasks,
    redis: Optional[aioredis.Redis] = Depends(get_redis),
    db: Any = Depends(get_db_connection),
    current_user: Any = Depends(get_current_user)
):
    """
    Este endpoint é chamado quando um cliente aceita a proposta de um advogado.
    Ele atualiza o status do caso e registra uma conversão para o teste A/B.
    """
    # 1. Registrar a conversão para o teste A/B
    if redis:
        ab_test_key = f"ab_test_info:{case_id}"
        test_info_raw = await redis.get(ab_test_key)
        if test_info_raw:
            try:
                test_info = json.loads(test_info_raw)
                logger.info(f"Registrando conversão para o teste A/B: {test_info}")
                background_tasks.add_task(
                    ab_testing_service.record_conversion,
                    user_id=test_info["user_id"],
                    test_id=test_info["test_id"],
                    group=test_info["group"],
                    converted=True
                )
                # Opcional: remover a chave para evitar registros duplicados
                await redis.delete(ab_test_key)
            except json.JSONDecodeError:
                logger.error(
                    f"Erro ao decodificar informações do teste A/B para o caso {case_id}")

    # 2. Atualizar o status do caso no banco de dados (exemplo)
    try:
        with db.cursor() as cursor:
            # Esta query é um exemplo. A tabela e os campos podem variar.
            # Idealmente, teríamos uma tabela `cases` com um campo `status`.
            # UPDATE cases SET status = 'accepted', accepted_at = NOW() WHERE id = %s
            # AND client_id = %s
            logger.info(
                f"Status do caso {case_id} seria atualizado para 'aceito' pelo usuário {current_user.id}")
            # cursor.execute("UPDATE cases SET status = 'accepted' WHERE id = %s", (case_id,))
            # db.commit()

    except psycopg2.Error as e:
        logger.error(f"Erro ao atualizar status do caso {case_id}: {e}")
        # Não falhar a request inteira por causa disso, mas logar o erro.

    finally:
        db.close()

    return {"success": True, "message": "Caso aceito e conversão registrada."}

# ============================================================================
# TASKS EM BACKGROUND
# ============================================================================


async def log_matching_analytics(case_id: str, request: MatchRequestSchema,
                                 total_lawyers: int, execution_time_ms: float):
    """Log analytics do matching para análise posterior"""
    try:
        analytics_data = {
            "case_id": case_id,
            "timestamp": datetime.utcnow().isoformat(),
            "area": request.case.area.value,
            "subarea": request.case.subarea,
            "urgency_hours": request.case.urgency_hours,
            "complexity": request.case.complexity.value,
            "top_n": request.top_n,
            "preset": request.preset.value,
            "total_lawyers_evaluated": total_lawyers,
            "execution_time_ms": execution_time_ms,
            "include_jusbrasil": request.include_jusbrasil_data,
            "api_version": "3.0.0-hybrid"
        }

        logger.info(f"Analytics: {analytics_data}")

        # Em produção, salvar em sistema de analytics (ex: ClickHouse, BigQuery)

    except Exception as e:
        logger.error(f"Erro ao registrar analytics: {e}")


async def sync_lawyer_hybrid_task(lawyer_id: str):
    """Task para sincronizar advogado específico com dados HÍBRIDOS"""
    try:
        from backend.jobs.jusbrasil_sync_hybrid import HybridJusbrasilSyncJob

        job = HybridJusbrasilSyncJob()
        job.connect_db()

        try:
            # Buscar dados do advogado
            cursor = job.db_connection.cursor()
            cursor.execute("""
                SELECT id, oab_numero, uf, nome
                FROM lawyers
                WHERE id = %s AND oab_numero IS NOT NULL
            """, (lawyer_id,))

            lawyer_data = cursor.fetchone()
            if not lawyer_data:
                logger.warning(f"Advogado {lawyer_id} não encontrado ou sem OAB")
                return

            # Executar sincronização HÍBRIDA
            stats = await job.integration.sync_lawyer_hybrid_data(dict(lawyer_data))

            logger.info(
                f"Sincronização HÍBRIDA do advogado {lawyer_id} concluída: {stats.total_processes} processos estimados")

        finally:
            job.close_db()

    except Exception as e:
        logger.error(f"Erro na sincronização HÍBRIDA do advogado {lawyer_id}: {e}")

# ============================================================================
# EXPLAINABILITY ENDPOINT
# ============================================================================


@app.get(
    "/api/explain/{match_id}",
    response_model=ExplainabilitySchema,
    summary="Explicabilidade de um ranking",
    description="Retorna detalhes de features e pesos para um resultado de match previamente calculado."
)
async def explain_match(match_id: str, redis: Optional[aioredis.Redis] = Depends(get_redis)):
    if not redis:
        raise HTTPException(status_code=503, detail="Serviço de explicabilidade indisponível (Redis ausente)")

    data = await redis.get(f"match:result:{match_id}")
    if not data:
        raise HTTPException(status_code=404, detail="Match id não encontrado ou expirado")

    try:
        payload = json.loads(data)
        
        # Estruturar resposta conforme schema
        response = ExplainabilitySchema(
            match_id=match_id,
            lawyers=payload.get("lawyers", []),
            weights_used=payload.get("weights_used", {}),
            preset=payload.get("preset", "balanced"),
            case_complexity=payload.get("case_complexity", "MEDIUM"),
            algorithm_version=payload.get("algorithm_version", "v2.7-rc")
        )
        
        return response
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Falha ao decodificar dados de explicabilidade")

# ============================================================================
# EXCEPTION HANDLERS
# ============================================================================


@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Handler para HTTPExceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponseSchema(
            error_code=f"HTTP_{exc.status_code}",
            message=exc.detail,
            timestamp=datetime.utcnow()
        ).dict()
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Handler para exceções gerais"""
    logger.error(f"Erro não tratado: {exc}")
    return JSONResponse(
        status_code=500,
        content=ErrorResponseSchema(
            error_code="INTERNAL_ERROR",
            message="Erro interno do servidor",
            details={"error": str(exc)},
            timestamp=datetime.utcnow()
        ).dict()
    )

# ============================================================================
# ENTRADA DA APLICAÇÃO
# ============================================================================

if __name__ == "__main__":
    try:
        import uvicorn
        uvicorn.run(
            "backend.api.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except ImportError:
        print("Para executar a API, instale uvicorn: pip install uvicorn")
