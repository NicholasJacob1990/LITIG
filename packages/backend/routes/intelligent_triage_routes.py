# backend/routes/intelligent_triage_routes.py
import asyncio
import json
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address
from sse_starlette.sse import EventSourceResponse

from auth import get_current_user
from services.conversation_state_manager import conversation_state_manager
from services.intelligent_triage_orchestrator import (
    OrchestrationResult,
    intelligent_triage_orchestrator,
)
# from models import TriageMessage, TriageMessageResponse, TriageStartBody  # Classes não encontradas

# Configuração do rate limiter
limiter = Limiter(key_func=get_remote_address)

# Criação do router
router = APIRouter(prefix="/triage", tags=["Intelligent Triage"])

# ============================================================================
# Modelos de Request/Response
# ============================================================================


class StartIntelligentTriageRequest(BaseModel):
    """Request para iniciar triagem inteligente."""
    user_id: Optional[str] = Field(
        None, description="ID do usuário (opcional se autenticado)")


class StartIntelligentTriageResponse(BaseModel):
    """Response do início da triagem inteligente."""
    case_id: str
    message: str
    status: str
    timestamp: datetime = Field(default_factory=datetime.now)


class ContinueConversationRequest(BaseModel):
    """Request para continuar conversa."""
    case_id: str
    message: str


class ContinueConversationResponse(BaseModel):
    """Response da continuação da conversa."""
    case_id: str
    message: str
    status: str  # "active" | "completed"
    complexity_hint: Optional[str] = None
    confidence: Optional[float] = None
    result: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.now)


class OrchestrationStatusResponse(BaseModel):
    """Response do status da orquestração."""
    case_id: str
    status: str  # "interviewing" | "completed" | "error"
    flow_type: str
    started_at: float
    conversation_status: Optional[Dict] = None
    current_complexity: Optional[str] = None
    current_confidence: Optional[float] = None
    error: Optional[str] = None


class TriageResultResponse(BaseModel):
    """Response do resultado final da triagem."""
    case_id: str
    strategy_used: str
    complexity_level: str
    confidence_score: float
    triage_data: Dict[str, Any]
    conversation_summary: str
    processing_time_ms: int
    flow_type: str
    case_type: Optional[str] = None
    analysis_details: Optional[Dict] = None
    timestamp: datetime = Field(default_factory=datetime.now)


class ForceCompleteRequest(BaseModel):
    """Request para forçar finalização."""
    case_id: str
    reason: str = "user_request"

# ============================================================================
# Endpoints
# ============================================================================


@router.post("/start", response_model=StartIntelligentTriageResponse)
@limiter.limit("30/minute")
async def start_intelligent_triage(
    request: Request,
    payload: StartIntelligentTriageRequest,
    user: dict = Depends(get_current_user)
):
    """
    Inicia uma nova triagem inteligente conversacional.

    A IA "Entrevistadora" conduzirá uma conversa empática para entender
    o caso e detectar automaticamente a complexidade em tempo real.
    """
    try:
        # Usar user_id do token de autenticação se não fornecido
        user_id = payload.user_id or user.get("id")

        if not user_id:
            raise HTTPException(
                status_code=400,
                detail="ID do usuário é obrigatório"
            )

        # Iniciar triagem inteligente
        result = await intelligent_triage_orchestrator.start_intelligent_triage(user_id)

        return StartIntelligentTriageResponse(
            case_id=result["case_id"],
            message=result["message"],
            status=result["status"]
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao iniciar triagem inteligente: {str(e)}"
        )


@router.post("/continue", response_model=ContinueConversationResponse)
@limiter.limit("60/minute")
async def continue_conversation(
    request: Request,
    payload: ContinueConversationRequest,
    user: dict = Depends(get_current_user)
):
    """
    Continua uma conversa de triagem inteligente.

    A IA "Entrevistadora" processará a mensagem do usuário e:
    1. Avaliará a complexidade do caso em tempo real
    2. Fará perguntas de acompanhamento apropriadas
    3. Finalizará com a estratégia apropriada quando tiver dados suficientes
    """
    try:
        # Continuar conversa
        result = await intelligent_triage_orchestrator.continue_intelligent_triage(
            payload.case_id,
            payload.message
        )

        return ContinueConversationResponse(
            case_id=result["case_id"],
            message=result["message"],
            status=result["status"],
            complexity_hint=result.get("complexity_hint"),
            confidence=result.get("confidence"),
            result=result.get("result")
        )

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao continuar conversa: {str(e)}"
        )


@router.get("/status/{case_id}", response_model=OrchestrationStatusResponse)
@limiter.limit("120/minute")
async def get_orchestration_status(
    case_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Obtém o status atual de uma orquestração de triagem inteligente.

    Retorna informações sobre:
    - Status da conversa (ativa, completa, erro)
    - Tipo de fluxo sendo usado
    - Complexidade detectada até o momento
    - Confiança na avaliação
    """
    try:
        status = await intelligent_triage_orchestrator.get_orchestration_status(case_id)

        if not status:
            raise HTTPException(
                status_code=404,
                detail=f"Orquestração {case_id} não encontrada"
            )

        return OrchestrationStatusResponse(**status)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter status: {str(e)}"
        )


@router.get("/result/{case_id}", response_model=TriageResultResponse)
@limiter.limit("60/minute")
async def get_triage_result(
    case_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Obtém o resultado final de uma triagem inteligente completa.

    Retorna:
    - Estratégia utilizada (simple/failover/ensemble)
    - Dados de triagem processados
    - Detalhes da análise
    - Tempo de processamento
    - Tipo de fluxo executado
    """
    try:
        result = await intelligent_triage_orchestrator.get_orchestration_result(case_id)

        if not result:
            raise HTTPException(
                status_code=404,
                detail=f"Resultado para {case_id} não encontrado ou ainda não disponível"
            )

        return TriageResultResponse(
            case_id=result.case_id,
            strategy_used=result.strategy_used,
            complexity_level=result.complexity_level,
            confidence_score=result.confidence_score,
            triage_data=result.triage_data,
            conversation_summary=result.conversation_summary,
            processing_time_ms=result.processing_time_ms,
            flow_type=result.flow_type,
            case_type=result.triage_data.get("case_type"),
            analysis_details=result.analysis_details
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter resultado: {str(e)}"
        )


@router.post("/force-complete", response_model=TriageResultResponse)
@limiter.limit("10/minute")
async def force_complete_conversation(
    payload: ForceCompleteRequest,
    user: dict = Depends(get_current_user)
):
    """
    Força a finalização de uma conversa em andamento.

    Útil para casos de timeout ou quando o usuário deseja finalizar
    a conversa antes da conclusão natural.
    """
    try:
        result = await intelligent_triage_orchestrator.force_complete_conversation(
            payload.case_id,
            payload.reason
        )

        if not result:
            raise HTTPException(
                status_code=404,
                detail=f"Conversa {
                    payload.case_id} não encontrada ou não pode ser finalizada"
            )

        return TriageResultResponse(
            case_id=result.case_id,
            strategy_used=result.strategy_used,
            complexity_level=result.complexity_level,
            confidence_score=result.confidence_score,
            triage_data=result.triage_data,
            conversation_summary=result.conversation_summary,
            processing_time_ms=result.processing_time_ms,
            flow_type=result.flow_type,
            case_type=result.triage_data.get("case_type"),
            analysis_details=result.analysis_details
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao forçar finalização: {str(e)}"
        )


@router.delete("/cleanup/{case_id}")
@limiter.limit("30/minute")
async def cleanup_orchestration(
    case_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Remove uma orquestração da memória após processamento.

    Útil para liberar recursos após obter o resultado final.
    """
    try:
        intelligent_triage_orchestrator.cleanup_orchestration(case_id)

        return {
            "case_id": case_id,
            "status": "cleaned_up",
            "message": "Orquestração removida da memória"
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao limpar orquestração: {str(e)}"
        )

# ============================================================================
# Endpoints de Streaming
# ============================================================================


@router.get("/stream/{case_id}")
async def stream_triage_updates(
        case_id: str, request: Request, user: dict = Depends(get_current_user)):
    """
    Endpoint de streaming para receber atualizações da triagem em tempo real.

    Usa Server-Sent Events (SSE) para enviar eventos como:
    - 'triage_update': progresso da conversa
    - 'complexity_update': nova avaliação de complexidade
    - 'triage_completed': resultado final
    """
    async def event_generator():
        try:
            async for event in intelligent_triage_orchestrator.stream_events(case_id):
                if await request.is_disconnected():
                    break
                yield event
        except asyncio.CancelledError:
            # Captura o cancelamento quando o cliente se desconecta
            print(f"Cliente desconectou do stream para o caso {case_id}")

    return EventSourceResponse(event_generator())

# ============================================================================
# Endpoints de Monitoramento e Estatísticas (Refatorado para Redis)
# ============================================================================


@router.get("/stats", response_model=Dict[str, Any])
@limiter.limit("10/minute")
async def get_system_stats(
    user: dict = Depends(get_current_user)
):
    """
    Obtém estatísticas do sistema de triagem inteligente diretamente do Redis.
    """
    try:
        stats = await conversation_state_manager.get_system_stats()
        return stats

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter estatísticas do sistema: {str(e)}"
        )

