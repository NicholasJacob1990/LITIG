# backend/routes.py
from datetime import datetime
from typing import Any, Dict, List

from celery.result import AsyncResult
from fastapi import APIRouter, Depends, HTTPException, Request

# TODO: run_triage_async_task foi removida, usar run_full_triage_flow_task
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address

# Importa a função de recarregamento
from .algoritmo_match import load_weights as reload_algorithm_weights
from .auth import get_current_user
from .celery_app import celery_app
from .models import (
    ExplainRequest,
    ExplainResponse,
    MatchRequest,
    MatchResponse,
    TriageRequest,
)
from .routes.ab_testing import router as ab_testing_router
from .routes.contracts import router as contracts_router

# Importar as novas rotas de triagem inteligente
from .routes.intelligent_triage_routes import router as intelligent_triage_router
from .routes.offers import router as offers_router
from .services import generate_explanations_for_matches
from .services.conversation_service import conversation_service
from .services.match_service import find_and_notify_matches
from .tasks.triage_tasks import process_triage_async as run_full_triage_flow_task

# Configuração do rate limiter para as rotas
limiter = Limiter(key_func=get_remote_address)


class TriageTaskResponse(BaseModel):
    task_id: str
    status: str
    message: str


class ConversationRequest(BaseModel):
    history: List[Dict[str, str]]


class ConversationResponse(BaseModel):
    reply: str


class HybridTriageRequest(BaseModel):
    transcription: str
    user_id: str


class HybridTriageResponse(BaseModel):
    case_id: str
    strategy_used: str
    status: str
    message: str


class DetailedAnalysisRequest(BaseModel):
    case_id: str


class DetailedAnalysisResponse(BaseModel):
    case_id: str
    detailed_analysis: Dict[str, Any]
    generated_at: str


router = APIRouter()

# Incluir as rotas de triagem inteligente
router.include_router(intelligent_triage_router)


@router.get("/triage/status/{task_id}")
async def get_triage_status(task_id: str, user: dict = Depends(get_current_user)):
    """
    Verifica o status de uma tarefa de triagem assíncrona.
    """
    task_result = AsyncResult(task_id, app=celery_app)

    if task_result.ready():
        if task_result.successful():
            return {"status": "completed", "result": task_result.get()}
        else:
            return {"status": "failed", "error": str(task_result.info)}

    return {"status": "pending"}


@router.post("/triage", response_model=TriageTaskResponse, status_code=202)
@limiter.limit("60/minute")
async def http_triage_case(request: Request, payload: TriageRequest,
                           user: dict = Depends(get_current_user)):
    """
    Endpoint para a triagem de um novo caso.
    Despacha uma tarefa assíncrona para processamento e retorna um ID de tarefa.
    """
    try:
        # Envia a tarefa para a fila do Celery
        # Usando run_full_triage_flow_task em vez da tarefa removida
        task = run_full_triage_flow_task.delay(payload.texto_cliente, "")
        return TriageTaskResponse(
            task_id=task.id,
            status="accepted",
            message="A triagem do seu caso foi iniciada. Você será notificado quando estiver concluída."
        )
    except Exception as e:
        # Erro ao despachar a tarefa (ex: Redis indisponível)
        raise HTTPException(status_code=500, detail=f"Erro ao iniciar a triagem: {e}")


@router.post("/match", response_model=MatchResponse)
async def http_find_matches(req: MatchRequest, user: dict = Depends(get_current_user)):
    """
    Endpoint para encontrar advogados para um caso.
    Recebe o ID de um caso, retorna uma lista ordenada de advogados e
    dispara notificações para os advogados encontrados.
    """
    result = await find_and_notify_matches(req)
    if result is None:
        raise HTTPException(
            status_code=404, detail=f"Caso com ID '{req.case_id}' não encontrado.")

    return result


@router.post("/explain", response_model=ExplainResponse)
@limiter.limit("30/minute")
async def http_explain_matches(
        request: Request, req: ExplainRequest, user: dict = Depends(get_current_user)):
    try:
        explanations = await generate_explanations_for_matches(req.case_id, req.lawyer_ids)
        return ExplainResponse(explanations=explanations)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar explicações: {e}")


@router.post("/triage/full-flow", response_model=HybridTriageResponse, status_code=202)
@limiter.limit("30/minute")
async def http_hybrid_triage_flow(
        request: Request, payload: HybridTriageRequest, user: dict = Depends(get_current_user)):
    """
    Endpoint para o Pipeline de Triagem Híbrida.
    Executa roteamento inteligente, triagem com estratégia apropriada e matching.
    """
    try:
        # Envia a tarefa completa para a fila do Celery
        task = run_full_triage_flow_task.delay(payload.transcription, payload.user_id)

        # Em um cenário real, retornaríamos o task_id para polling
        # Mas para simplificar, vamos simular uma resposta imediata
        return HybridTriageResponse(
            case_id=f"case_{task.id}",
            strategy_used="hybrid",
            status="processing",
            message="Análise híbrida iniciada com sucesso. Você será notificado quando estiver concluída."
        )
    except Exception as e:
        raise HTTPException(status_code=500,
                            detail=f"Erro ao iniciar análise híbrida: {e}")


@router.get("/cases/{case_id}/detailed-analysis",
            response_model=DetailedAnalysisResponse)
@limiter.limit("30/minute")
async def get_detailed_analysis(
        request: Request, case_id: str, user: dict = Depends(get_current_user)):
    """
    Endpoint para obter análise detalhada de um caso.
    Retorna a análise rica gerada pelo OpenAI.
    """
    try:
        import os

        from supabase import create_client

        # Conectar ao Supabase
        SUPABASE_URL = os.getenv("SUPABASE_URL")
        SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
        supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

        # Buscar o caso
        case_response = supabase.table("cases").select(
            "*").eq("id", case_id).single().execute()

        if not case_response.data:
            raise HTTPException(status_code=404, detail="Caso não encontrado")

        case_data = case_response.data
        detailed_analysis = case_data.get("detailed_analysis")

        if not detailed_analysis:
            raise HTTPException(
                status_code=404, detail="Análise detalhada não disponível para este caso")

        return DetailedAnalysisResponse(
            case_id=case_id,
            detailed_analysis=detailed_analysis,
            generated_at=case_data.get("created_at", datetime.now().isoformat())
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500,
                            detail=f"Erro ao buscar análise detalhada: {e}")


@router.post("/triage/conversation", response_model=ConversationResponse)
@limiter.limit("120/minute")
async def http_triage_conversation(
        request: Request, payload: ConversationRequest, user: dict = Depends(get_current_user)):
    """
    Endpoint para a conversa de triagem interativa.
    Recebe o histórico e retorna a próxima mensagem da IA.
    """
    try:
        reply = await conversation_service.get_next_ai_message(payload.history)
        return ConversationResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500,
                            detail=f"Erro ao processar a conversa: {e}")

# === Endpoints Internos ===


@router.post("/internal/reload_weights", status_code=200)
async def http_reload_weights():
    """
    Endpoint interno para recarregar os pesos do algoritmo de match a partir do arquivo.
    Isso permite atualizar o modelo de LTR sem reiniciar a aplicação.
    """
    try:
        new_weights = reload_algorithm_weights()
        return {"status": "success", "message": "Pesos do algoritmo recarregados.",
                "new_weights": new_weights}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao recarregar os pesos: {e}")


@router.get("/business-metrics/test")
async def test_business_metrics():
    """
    Endpoint de teste para métricas de negócio.
    """
    try:
        from .services.business_metrics import business_metrics

        # Testar métricas básicas
        conversion_metrics = await business_metrics.calculate_conversion_metrics(7)
        health_metrics = await business_metrics.calculate_system_health()

        return {
            "status": "success",
            "conversion_metrics": conversion_metrics,
            "health_metrics": health_metrics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reports/test")
async def test_report_generation(report_type: str = "weekly"):
    """
    Endpoint para testar geração de relatórios.

    Args:
        report_type: "weekly" ou "monthly"
    """
    try:
        from .jobs.automated_reports import test_report_generation

        # Executar job de teste
        result = test_report_generation.delay(report_type)

        return {
            "status": "success",
            "message": f"Job de relatório {report_type} iniciado",
            "task_id": result.id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reports/status/{task_id}")
async def check_report_status(task_id: str):
    """
    Verifica o status de um job de relatório.
    """
    try:
        from .celery_app import celery_app

        result = celery_app.AsyncResult(task_id)

        return {
            "task_id": task_id,
            "status": result.status,
            "result": result.result if result.ready() else None
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reports/test-direct")
async def test_report_direct():
    """
    Testa geração de relatório diretamente sem usar Celery.
    """
    try:
        from .services.automated_reports import automated_reports_service

        # Gerar relatório diretamente
        result = await automated_reports_service.generate_weekly_report()

        return {
            "status": "success",
            "message": "Relatório gerado com sucesso",
            "result": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Importar rotas existentes

# Registrar rotas no router principal (não em app)
router.include_router(offers_router)
router.include_router(contracts_router)
router.include_router(ab_testing_router)
