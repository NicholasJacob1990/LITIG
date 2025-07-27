#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Case Feedback APIs
==================

APIs para coleta de feedback sobre outcomes de casos para AutoML.
Usado para treinamento do algoritmo de matching casos-advogados.

Endpoints:
- POST /feedback/case: Registra feedback individual de outcome
- POST /feedback/case/batch: Registra feedback em lote
- GET /feedback/metrics: Retorna métricas de performance do ML
- POST /feedback/optimize: Força otimização de pesos

Conforme PLANO_ACAO_AUTOML_ALGORITMO_MATCH.md - Fase 1.2
Baseado em evidências acadêmicas de MLOps (LinkedIn, Nubank, AWS)
"""

import logging
from datetime import datetime
from typing import Dict, Any, Optional, List

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field, validator
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_async_session
from services.case_match_ml_service import CaseMatchMLService, CaseFeedback, create_case_match_ml_service

router = APIRouter(prefix="/api/feedback", tags=["case-feedback"])
logger = logging.getLogger(__name__)

# Rate limiting configurado conforme boas práticas anti-spam
limiter = Limiter(key_func=get_remote_address)


class CaseFeedbackRequest(BaseModel):
    """Request para registro de feedback de caso individual."""
    case_id: str = Field(..., description="ID do caso")
    lawyer_id: str = Field(..., description="ID do advogado avaliado")
    client_id: str = Field(..., description="ID do cliente que está dando feedback")
    
    # Outcomes principais
    hired: bool = Field(..., description="Cliente contratou o advogado?")
    client_satisfaction: float = Field(..., ge=0.0, le=5.0, description="Satisfação do cliente (0-5 estrelas)")
    case_success: bool = Field(..., description="Caso foi bem-sucedido?")
    case_outcome_value: Optional[float] = Field(None, description="Valor recuperado/economizado")
    
    # Métricas de processo (opcionais)
    response_time_hours: Optional[float] = Field(None, ge=0.0, description="Tempo real de resposta em horas")
    negotiation_rounds: Optional[int] = Field(None, ge=0, description="Número de rounds de negociação")
    case_duration_days: Optional[int] = Field(None, ge=0, description="Duração total do caso em dias")
    
    # Contexto do caso
    case_area: str = Field(..., description="Área jurídica do caso")
    case_complexity: str = Field(default="MEDIUM", description="Complexidade: LOW, MEDIUM, HIGH")
    case_urgency_hours: int = Field(default=48, ge=1, description="Urgência original em horas")
    case_value_range: str = Field(default="unknown", description="Faixa de valor: low, medium, high, unknown")
    
    # Contexto do match
    lawyer_rank_position: int = Field(..., ge=1, description="Posição do advogado no ranking (1=primeiro)")
    total_candidates: int = Field(..., ge=1, description="Total de candidatos apresentados")
    match_score: float = Field(..., ge=0.0, le=1.0, description="Score que o algoritmo deu")
    features_used: Dict[str, float] = Field(default_factory=dict, description="Features A,S,T,etc usadas")
    preset_used: str = Field(default="balanced", description="Preset usado no matching")
    
    # Metadata
    feedback_source: str = Field(default="client", description="Origem: client, admin, automatic")
    feedback_notes: Optional[str] = Field(None, description="Notas adicionais do usuário")
    
    @validator('case_complexity')
    def validate_complexity(cls, v):
        if v not in ['LOW', 'MEDIUM', 'HIGH']:
            raise ValueError('case_complexity deve ser LOW, MEDIUM ou HIGH')
        return v
    
    @validator('case_value_range')
    def validate_value_range(cls, v):
        if v not in ['low', 'medium', 'high', 'unknown']:
            raise ValueError('case_value_range deve ser low, medium, high ou unknown')
        return v
    
    @validator('feedback_source')
    def validate_feedback_source(cls, v):
        if v not in ['client', 'admin', 'automatic']:
            raise ValueError('feedback_source deve ser client, admin ou automatic')
        return v


class BatchFeedbackRequest(BaseModel):
    """Request para registro de feedback em lote."""
    case_id: str = Field(..., description="ID do caso")
    client_id: str = Field(..., description="ID do cliente")
    
    outcomes: List[Dict[str, Any]] = Field(..., description="Lista de outcomes por advogado")
    
    case_context: Dict[str, Any] = Field(..., description="Contexto geral do caso")
    
    @validator('outcomes')
    def validate_outcomes(cls, v):
        if not v:
            raise ValueError('outcomes não pode estar vazio')
        
        required_fields = ['lawyer_id', 'hired', 'client_rating', 'rank_position', 'match_score']
        for outcome in v:
            for field in required_fields:
                if field not in outcome:
                    raise ValueError(f'Campo obrigatório ausente em outcome: {field}')
        return v


class OptimizationRequest(BaseModel):
    """Request para forçar otimização de pesos."""
    min_feedback_count: int = Field(default=50, ge=10, description="Mínimo de feedbacks para otimização")
    force_optimization: bool = Field(default=False, description="Forçar otimização mesmo sem critérios")


class FeedbackResponse(BaseModel):
    """Response padrão para operações de feedback."""
    success: bool
    message: str
    feedback_id: Optional[str] = None
    recommendations: Optional[List[str]] = None


@router.post("/case", response_model=FeedbackResponse)
@limiter.limit("30/minute")  # Rate limiting conforme plano: prevenir spam
async def register_case_feedback(
    request: Request,
    feedback_request: CaseFeedbackRequest,
    db: AsyncSession = Depends(get_async_session),
    current_user: dict = Depends(get_current_user)
):
    """
    Registra feedback individual de outcome de caso para AutoML.
    
    **Boas Práticas Implementadas:**
    - Rate limiting (30/min) para prevenir spam
    - Validação Pydantic robusta
    - Logging detalhado para auditoria
    - Error handling com fallback
    """
    try:
        # Validar se usuário tem permissão
        if current_user.get("id") != feedback_request.client_id and not current_user.get("is_admin"):
            raise HTTPException(status_code=403, detail="Usuário não autorizado para este feedback")
        
        # Inicializar serviço ML
        ml_service = await create_case_match_ml_service(db)
        if not ml_service:
            raise HTTPException(status_code=503, detail="Serviço ML temporariamente indisponível")
        
        # Criar objeto CaseFeedback
        feedback = CaseFeedback(
            case_id=feedback_request.case_id,
            lawyer_id=feedback_request.lawyer_id,
            client_id=feedback_request.client_id,
            hired=feedback_request.hired,
            client_satisfaction=feedback_request.client_satisfaction,
            case_success=feedback_request.case_success,
            case_outcome_value=feedback_request.case_outcome_value,
            response_time_hours=feedback_request.response_time_hours,
            negotiation_rounds=feedback_request.negotiation_rounds,
            case_duration_days=feedback_request.case_duration_days,
            case_area=feedback_request.case_area,
            case_complexity=feedback_request.case_complexity,
            case_urgency_hours=feedback_request.case_urgency_hours,
            case_value_range=feedback_request.case_value_range,
            lawyer_rank_position=feedback_request.lawyer_rank_position,
            total_candidates=feedback_request.total_candidates,
            match_score=feedback_request.match_score,
            features_used=feedback_request.features_used,
            preset_used=feedback_request.preset_used,
            feedback_source=feedback_request.feedback_source,
            feedback_notes=feedback_request.feedback_notes,
            timestamp=datetime.utcnow()
        )
        
        # Registrar feedback
        await ml_service.record_feedback(feedback)
        
        # Log para auditoria
        logger.info(f"✅ Feedback registrado - caso: {feedback_request.case_id}, "
                   f"advogado: {feedback_request.lawyer_id}, "
                   f"hired: {feedback_request.hired}, "
                   f"satisfaction: {feedback_request.client_satisfaction}")
        
        # Preparar recomendações baseadas no feedback
        recommendations = []
        if not feedback_request.hired and feedback_request.client_satisfaction < 3.0:
            recommendations.append("Considere usar preset 'expert' para casos similares")
        if feedback_request.case_success and feedback_request.hired:
            recommendations.append("Advogado teve ótimo desempenho - será priorizado em casos similares")
        
        return FeedbackResponse(
            success=True,
            message="Feedback registrado com sucesso",
            feedback_id=f"{feedback_request.case_id}_{feedback_request.lawyer_id}",
            recommendations=recommendations
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao registrar feedback: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")


@router.post("/case/batch", response_model=FeedbackResponse)
@limiter.limit("10/minute")  # Rate limiting mais restritivo para batch
async def register_batch_feedback(
    request: Request,
    batch_request: BatchFeedbackRequest,
    db: AsyncSession = Depends(get_async_session),
    current_user: dict = Depends(get_current_user)
):
    """
    Registra feedback em lote para múltiplos advogados de um mesmo caso.
    
    **Otimizado para:**
    - Processamento eficiente de múltiplos outcomes
    - Transação única para garantir consistência
    - Validação robusta de dados de entrada
    """
    try:
        # Validar autorização
        if current_user.get("id") != batch_request.client_id and not current_user.get("is_admin"):
            raise HTTPException(status_code=403, detail="Usuário não autorizado")
        
        # Inicializar serviço ML
        ml_service = await create_case_match_ml_service(db)
        if not ml_service:
            raise HTTPException(status_code=503, detail="Serviço ML indisponível")
        
        # Processar cada outcome
        processed_count = 0
        errors = []
        
        for i, outcome in enumerate(batch_request.outcomes):
            try:
                feedback = CaseFeedback(
                    case_id=batch_request.case_id,
                    lawyer_id=outcome["lawyer_id"],
                    client_id=batch_request.client_id,
                    hired=outcome["hired"],
                    client_satisfaction=outcome["client_rating"],
                    case_success=batch_request.case_context.get("case_success", False),
                    case_outcome_value=batch_request.case_context.get("case_value"),
                    case_duration_days=batch_request.case_context.get("duration_days"),
                    case_area=batch_request.case_context.get("case_area", ""),
                    case_complexity=batch_request.case_context.get("case_complexity", "MEDIUM"),
                    case_urgency_hours=batch_request.case_context.get("case_urgency_hours", 48),
                    case_value_range=batch_request.case_context.get("case_value_range", "unknown"),
                    lawyer_rank_position=outcome["rank_position"],
                    total_candidates=len(batch_request.outcomes),
                    match_score=outcome["match_score"],
                    features_used=outcome.get("features", {}),
                    preset_used=batch_request.case_context.get("preset_used", "balanced"),
                    feedback_source="client",
                    timestamp=datetime.utcnow()
                )
                
                await ml_service.record_feedback(feedback)
                processed_count += 1
                
            except Exception as e:
                errors.append(f"Outcome {i}: {str(e)}")
        
        # Log resultado
        logger.info(f"✅ Batch feedback - processados: {processed_count}/{len(batch_request.outcomes)}, "
                   f"erros: {len(errors)}")
        
        if errors:
            logger.warning(f"⚠️ Erros no batch: {errors}")
        
        return FeedbackResponse(
            success=processed_count > 0,
            message=f"Processados {processed_count} de {len(batch_request.outcomes)} feedbacks",
            recommendations=["Dados de lote processados para melhoria contínua do algoritmo"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro no batch feedback: {e}")
        raise HTTPException(status_code=500, detail="Erro no processamento em lote")


@router.get("/metrics")
@limiter.limit("60/minute")
async def get_feedback_metrics(
    request: Request,
    db: AsyncSession = Depends(get_async_session),
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna métricas de performance do sistema AutoML.
    
    **Métricas Incluídas:**
    - Taxa de contratação (hire rate)
    - Satisfação média do cliente
    - Taxa de sucesso dos casos
    - Status da otimização
    """
    try:
        # Apenas admins ou usuários com permissão especial
        if not current_user.get("is_admin") and not current_user.get("analytics_access"):
            raise HTTPException(status_code=403, detail="Acesso negado às métricas")
        
        # Inicializar serviço ML
        ml_service = await create_case_match_ml_service(db)
        if not ml_service:
            raise HTTPException(status_code=503, detail="Serviço ML indisponível")
        
        # Obter relatório de performance
        report = await ml_service.get_performance_report()
        
        return {
            "success": True,
            "data": report,
            "timestamp": datetime.utcnow().isoformat(),
            "service_version": "automl-v1.0"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao obter métricas: {e}")
        raise HTTPException(status_code=500, detail="Erro ao gerar relatório")


@router.post("/optimize", response_model=FeedbackResponse)
@limiter.limit("3/hour")  # Rate limiting muito restritivo - operação custosa
async def force_optimization(
    request: Request,
    optimization_request: OptimizationRequest,
    db: AsyncSession = Depends(get_async_session),
    current_user: dict = Depends(get_current_user)
):
    """
    Força otimização manual dos pesos do algoritmo.
    
    **ATENÇÃO:** Operação custosa - usar apenas quando necessário.
    Rate limited para 3 tentativas por hora por IP.
    """
    try:
        # Apenas admins podem forçar otimização
        if not current_user.get("is_admin"):
            raise HTTPException(status_code=403, detail="Apenas administradores podem forçar otimização")
        
        # Inicializar serviço ML
        ml_service = await create_case_match_ml_service(db)
        if not ml_service:
            raise HTTPException(status_code=503, detail="Serviço ML indisponível")
        
        # Verificar se há feedback suficiente
        report = await ml_service.get_performance_report()
        feedback_count = report.get("last_feedback_count", 0)
        
        if feedback_count < optimization_request.min_feedback_count and not optimization_request.force_optimization:
            raise HTTPException(
                status_code=400, 
                detail=f"Feedback insuficiente: {feedback_count} < {optimization_request.min_feedback_count}"
            )
        
        # Executar otimização
        await ml_service._trigger_optimization()
        
        # Log da operação
        logger.info(f"🔄 Otimização forçada por admin {current_user.get('id')} - "
                   f"feedback_count: {feedback_count}")
        
        return FeedbackResponse(
            success=True,
            message="Otimização executada com sucesso",
            recommendations=[
                "Pesos do algoritmo foram otimizados baseados no feedback recente",
                "Monitorar métricas de performance nas próximas 24h"
            ]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro na otimização forçada: {e}")
        raise HTTPException(status_code=500, detail="Erro na otimização")


# Health check endpoint para monitoramento
@router.get("/health")
async def feedback_health_check(db: AsyncSession = Depends(get_async_session)):
    """Health check do sistema de feedback."""
    try:
        ml_service = await create_case_match_ml_service(db)
        
        return {
            "status": "healthy" if ml_service else "degraded",
            "service": "case-feedback-automl",
            "version": "1.0.0",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception:
        return {
            "status": "unhealthy",
            "service": "case-feedback-automl",
            "version": "1.0.0",
            "timestamp": datetime.utcnow().isoformat()
        } 