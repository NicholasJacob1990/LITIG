#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Feedback APIs
=========================

APIs para coleta de feedback sobre recomendações de parceria.
Usado para treinamento do sistema de ML.

Endpoints:
- POST /feedback: Registra feedback do usuário
- GET /metrics: Retorna métricas de performance
- POST /optimize: Força otimização de pesos
- GET /ab-test: Status de A/B tests ativos
"""

import logging
from datetime import datetime
from typing import Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_async_session
from services.partnership_ml_service import PartnershipMLService, PartnershipFeedback

router = APIRouter(prefix="/api/partnership/feedback", tags=["partnership-feedback"])
logger = logging.getLogger(__name__)


class FeedbackRequest(BaseModel):
    """Request para registro de feedback."""
    user_id: str = Field(..., description="ID do usuário")
    lawyer_id: str = Field(..., description="ID do advogado que recebeu a recomendação")
    recommended_lawyer_id: str = Field(..., description="ID do advogado recomendado")
    feedback_type: str = Field(..., description="Tipo de feedback: accepted, rejected, contacted, dismissed")
    feedback_score: float = Field(..., ge=0.0, le=1.0, description="Score de relevância (0-1)")
    interaction_time_seconds: Optional[int] = Field(None, description="Tempo de interação em segundos")
    feedback_notes: Optional[str] = Field(None, description="Notas adicionais do usuário")


class OptimizationRequest(BaseModel):
    """Request para forçar otimização de pesos."""
    min_feedback_count: int = Field(default=100, description="Mínimo de feedbacks para otimização")


class ABTestRequest(BaseModel):
    """Request para iniciar A/B test."""
    test_name: str = Field(..., description="Nome do teste")
    weights_config: Dict[str, float] = Field(..., description="Configuração de pesos para teste")
    duration_days: int = Field(default=7, description="Duração do teste em dias")


@router.post("/")
async def record_feedback(
    feedback: FeedbackRequest,
    db: AsyncSession = Depends(get_async_session)
):
    """Registra feedback do usuário sobre uma recomendação de parceria."""
    try:
        ml_service = PartnershipMLService(db)
        
        # Validar tipo de feedback
        valid_types = ["accepted", "rejected", "contacted", "dismissed"]
        if feedback.feedback_type not in valid_types:
            raise HTTPException(
                status_code=400,
                detail=f"Tipo de feedback inválido. Deve ser um de: {valid_types}"
            )
        
        # Criar objeto de feedback
        feedback_obj = PartnershipFeedback(
            user_id=feedback.user_id,
            lawyer_id=feedback.lawyer_id,
            recommended_lawyer_id=feedback.recommended_lawyer_id,
            feedback_type=feedback.feedback_type,
            feedback_score=feedback.feedback_score,
            interaction_time_seconds=feedback.interaction_time_seconds,
            feedback_notes=feedback.feedback_notes,
            timestamp=datetime.utcnow()
        )
        
        # Registrar feedback
        await ml_service.record_feedback(feedback_obj)
        
        logger.info(f"Feedback registrado: {feedback.feedback_type} - score: {feedback.feedback_score}")
        
        return {
            "message": "Feedback registrado com sucesso",
            "feedback_id": feedback_obj.user_id,
            "timestamp": feedback_obj.timestamp.isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro ao registrar feedback: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao registrar feedback: {str(e)}"
        )


@router.get("/metrics")
async def get_performance_metrics(
    db: AsyncSession = Depends(get_async_session)
):
    """Retorna métricas de performance do sistema de ML."""
    try:
        ml_service = PartnershipMLService(db)
        metrics = await ml_service.get_performance_metrics()
        
        return {
            "metrics": metrics,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro ao obter métricas: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao obter métricas: {str(e)}"
        )


@router.post("/optimize")
async def force_optimization(
    request: OptimizationRequest,
    db: AsyncSession = Depends(get_async_session)
):
    """Força otimização de pesos do algoritmo."""
    try:
        ml_service = PartnershipMLService(db)
        
        # Verificar se há feedback suficiente
        feedback_count = await ml_service._get_feedback_count()
        if feedback_count < request.min_feedback_count:
            return {
                "message": f"Feedback insuficiente para otimização",
                "current_count": feedback_count,
                "required_count": request.min_feedback_count,
                "optimization_performed": False
            }
        
        # Executar otimização
        success = await ml_service.optimize_weights(request.min_feedback_count)
        
        if success:
            return {
                "message": "Otimização executada com sucesso",
                "feedback_count": feedback_count,
                "optimization_performed": True,
                "new_weights": ml_service.weights.to_dict()
            }
        else:
            return {
                "message": "Otimização não melhorou performance - pesos mantidos",
                "feedback_count": feedback_count,
                "optimization_performed": False
            }
            
    except Exception as e:
        logger.error(f"Erro na otimização: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno na otimização: {str(e)}"
        )


@router.post("/ab-test")
async def start_ab_test(
    request: ABTestRequest,
    db: AsyncSession = Depends(get_async_session)
):
    """Inicia um novo A/B test."""
    try:
        ml_service = PartnershipMLService(db)
        
        # Configuração do teste
        test_config = {
            "name": request.test_name,
            "weights": request.weights_config,
            "duration_days": request.duration_days,
            "start_time": datetime.utcnow().isoformat()
        }
        
        # Iniciar teste
        test_id = await ml_service.run_ab_test(test_config)
        
        return {
            "message": "A/B test iniciado com sucesso",
            "test_id": test_id,
            "config": test_config
        }
        
    except Exception as e:
        logger.error(f"Erro ao iniciar A/B test: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao iniciar A/B test: {str(e)}"
        )


@router.get("/ab-test/{test_id}")
async def get_ab_test_status(
    test_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Retorna status de um A/B test específico."""
    try:
        ml_service = PartnershipMLService(db)
        
        # Buscar configuração do teste
        test_config_raw = await ml_service.redis.get(f"partnership:ab_test:{test_id}")
        
        if not test_config_raw:
            raise HTTPException(
                status_code=404,
                detail="A/B test não encontrado"
            )
        
        import json
        test_config = json.loads(test_config_raw)
        
        return {
            "test_id": test_id,
            "config": test_config,
            "status": "active"  # TODO: Implementar lógica de status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao obter status do A/B test: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao obter status: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check do sistema de feedback."""
    return {
        "status": "healthy",
        "service": "partnership-feedback",
        "timestamp": datetime.utcnow().isoformat()
    } 