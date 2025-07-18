#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/routes/ratings.py

Sistema completo de avaliações para casos finalizados.
Implementação do Sprint 3.1 do PLANO_ACAO_DETALHADO.md
"""

import uuid
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field

from ..auth import get_current_user
from ..config import get_supabase_client
from ..services.notification_service import notify_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ratings", tags=["Ratings"])

# ============================================================================
# Request/Response Models
# ============================================================================

class RatingRequest(BaseModel):
    case_id: str = Field(..., description="ID do caso avaliado")
    lawyer_id: str = Field(..., description="ID do advogado")
    client_id: str = Field(..., description="ID do cliente")
    rater_type: str = Field(..., description="Tipo do avaliador (client ou lawyer)")
    overall_rating: float = Field(..., ge=1, le=5, description="Avaliação geral (1-5)")
    communication_rating: float = Field(..., ge=1, le=5, description="Avaliação comunicação (1-5)")
    expertise_rating: float = Field(..., ge=1, le=5, description="Avaliação expertise (1-5)")
    responsiveness_rating: float = Field(..., ge=1, le=5, description="Avaliação responsividade (1-5)")
    value_rating: float = Field(..., ge=1, le=5, description="Avaliação custo-benefício (1-5)")
    comment: Optional[str] = Field(None, max_length=500, description="Comentário opcional")
    tags: List[str] = Field(default_factory=list, description="Tags destacadas")

class RatingResponse(BaseModel):
    id: str
    case_id: str
    lawyer_id: str
    client_id: str
    rater_type: str
    overall_rating: float
    communication_rating: float
    expertise_rating: float
    responsiveness_rating: float
    value_rating: float
    comment: Optional[str]
    tags: List[str]
    created_at: datetime
    is_verified: bool
    case_title: Optional[str] = None
    rater_name: Optional[str] = None

class LawyerRatingStats(BaseModel):
    lawyer_id: str
    overall_rating: float
    total_ratings: int
    communication_avg: float
    expertise_avg: float
    responsiveness_avg: float
    value_avg: float
    star_distribution: Dict[str, int]
    last_updated: datetime

# ============================================================================
# Endpoints
# ============================================================================

@router.post("/", response_model=Dict[str, Any])
async def create_rating(
    rating_request: RatingRequest,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Cria uma nova avaliação para um caso finalizado.
    
    Verifica permissões, valida caso finalizado e cria avaliação.
    Atualiza estatísticas do advogado e envia notificações.
    """
    try:
        user_id = current_user.get("id")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não autenticado"
            )

        # Verificar se o usuário tem permissão para avaliar este caso
        if not await _can_rate_case(supabase, user_id, rating_request.case_id, rating_request.rater_type):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Você não tem permissão para avaliar este caso"
            )
        
        # Verificar se já existe avaliação
        existing_rating = await _get_existing_rating(
            supabase,
            rating_request.case_id,
            user_id,
            rating_request.rater_type
        )
        
        if existing_rating:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Você já avaliou este caso"
            )
        
        # Criar avaliação
        rating_data = {
            "case_id": rating_request.case_id,
            "lawyer_id": rating_request.lawyer_id,
            "client_id": rating_request.client_id,
            "rater_id": user_id,
            "rater_type": rating_request.rater_type,
            "overall_rating": rating_request.overall_rating,
            "communication_rating": rating_request.communication_rating,
            "expertise_rating": rating_request.expertise_rating,
            "responsiveness_rating": rating_request.responsiveness_rating,
            "value_rating": rating_request.value_rating,
            "comment": rating_request.comment,
            "tags": rating_request.tags,
            "created_at": datetime.utcnow().isoformat(),
            "is_verified": True,
            "is_public": True
        }
        
        result = supabase.table("ratings").insert(rating_data).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao criar avaliação"
            )
        
        rating_id = result.data[0]["id"]
        
        # Atualizar estatísticas do advogado (apenas para avaliações de clientes)
        if rating_request.rater_type == "client":
            await _update_lawyer_statistics(supabase, rating_request.lawyer_id)
        
        # Enviar notificação para o avaliado
        await _send_rating_notification(rating_request, current_user)
        
        logger.info(f"Avaliação criada com sucesso: {rating_id}")
        
        return {
            "success": True,
            "rating_id": rating_id,
            "message": "Avaliação criada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar avaliação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.get("/lawyer/{lawyer_id}", response_model=Dict[str, Any])
async def get_lawyer_ratings(
    lawyer_id: str,
    page: int = Query(1, ge=1, description="Página"),
    limit: int = Query(10, ge=1, le=50, description="Itens por página"),
    supabase = Depends(get_supabase_client)
):
    """
    Retorna avaliações de um advogado específico com paginação.
    """
    try:
        offset = (page - 1) * limit
        
        # Buscar avaliações do advogado
        ratings_result = supabase.table("ratings") \
            .select("""
                *,
                cases(title),
                rater:rater_id(name)
            """) \
            .eq("lawyer_id", lawyer_id) \
            .eq("rater_type", "client") \
            .eq("is_public", True) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()
        
        # Buscar contagem total
        total_result = supabase.table("ratings") \
            .select("id", count="exact") \
            .eq("lawyer_id", lawyer_id) \
            .eq("rater_type", "client") \
            .eq("is_public", True) \
            .execute()
        
        total_count = total_result.count if total_result.count else 0
        
        # Formatar avaliações
        ratings = []
        for row in ratings_result.data:
            rating = {
                "id": row["id"],
                "case_id": row["case_id"],
                "case_title": row["cases"]["title"] if row["cases"] else "Caso Confidencial",
                "rater_name": row["rater"]["name"] if row["rater"] else "Cliente Anônimo",
                "overall_rating": row["overall_rating"],
                "communication_rating": row["communication_rating"],
                "expertise_rating": row["expertise_rating"],
                "responsiveness_rating": row["responsiveness_rating"],
                "value_rating": row["value_rating"],
                "comment": row["comment"],
                "tags": row["tags"] or [],
                "created_at": row["created_at"],
                "is_verified": row["is_verified"]
            }
            ratings.append(rating)
        
        # Buscar estatísticas
        stats = await _get_lawyer_rating_stats(supabase, lawyer_id)
        
        return {
            "success": True,
            "ratings": ratings,
            "statistics": stats,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total_count,
                "total_pages": (total_count + limit - 1) // limit
            }
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar avaliações do advogado {lawyer_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.get("/case/{case_id}/can-rate")
async def can_rate_case(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Verifica se o usuário atual pode avaliar um caso específico.
    """
    try:
        user_id = current_user.get("id")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não autenticado"
            )
        
        # Buscar informações do caso
        case_result = supabase.table("cases") \
            .select("id, client_id, lawyer_id, status") \
            .eq("id", case_id) \
            .single() \
            .execute()
        
        if not case_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Caso não encontrado"
            )
        
        case_data = case_result.data
        
        # Verificar se o caso está finalizado
        if case_data["status"] != "completed":
            return {
                "can_rate": False,
                "reason": "Caso ainda não foi finalizado"
            }
        
        # Determinar tipo do usuário e permissão
        rater_type = None
        if case_data["client_id"] == user_id:
            rater_type = "client"
        elif case_data["lawyer_id"] == user_id:
            rater_type = "lawyer"
        else:
            return {
                "can_rate": False,
                "reason": "Você não está envolvido neste caso"
            }
        
        # Verificar se já avaliou
        existing_rating = await _get_existing_rating(
            supabase, case_id, user_id, rater_type
        )
        
        if existing_rating:
            return {
                "can_rate": False,
                "reason": "Você já avaliou este caso",
                "existing_rating_id": existing_rating["id"]
            }
        
        return {
            "can_rate": True,
            "rater_type": rater_type,
            "case_info": {
                "id": case_data["id"],
                "lawyer_id": case_data["lawyer_id"],
                "client_id": case_data["client_id"]
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao verificar permissão de avaliação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.get("/stats/lawyer/{lawyer_id}")
async def get_lawyer_statistics(
    lawyer_id: str,
    supabase = Depends(get_supabase_client)
):
    """
    Retorna estatísticas detalhadas de avaliação de um advogado.
    """
    try:
        stats = await _get_lawyer_rating_stats(supabase, lawyer_id)
        return {
            "success": True,
            "statistics": stats
        }
    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# ============================================================================
# Helper Functions
# ============================================================================

async def _can_rate_case(supabase, user_id: str, case_id: str, rater_type: str) -> bool:
    """
    Verifica se o usuário pode avaliar este caso.
    """
    try:
        # Verificar se o caso existe e está finalizado
        case_result = supabase.table("cases") \
            .select("id, client_id, lawyer_id, status") \
            .eq("id", case_id) \
            .eq("status", "completed") \
            .single() \
            .execute()
        
        if not case_result.data:
            return False
        
        case_data = case_result.data
        
        # Verificar se o usuário está relacionado ao caso
        if rater_type == "client":
            return case_data["client_id"] == user_id
        elif rater_type == "lawyer":
            return case_data["lawyer_id"] == user_id
        
        return False
        
    except Exception as e:
        logger.error(f"Erro ao verificar permissão: {e}")
        return False

async def _get_existing_rating(supabase, case_id: str, user_id: str, rater_type: str):
    """
    Verifica se já existe avaliação do usuário para este caso.
    """
    try:
        result = supabase.table("ratings") \
            .select("id") \
            .eq("case_id", case_id) \
            .eq("rater_id", user_id) \
            .eq("rater_type", rater_type) \
            .single() \
            .execute()
        
        return result.data
    except:
        return None

async def _update_lawyer_statistics(supabase, lawyer_id: str):
    """
    Atualiza estatísticas agregadas do advogado.
    """
    try:
        # Calcular novas estatísticas
        stats = await _calculate_lawyer_stats(supabase, lawyer_id)
        
        # Atualizar ou inserir estatísticas
        upsert_data = {
            "lawyer_id": lawyer_id,
            "overall_rating": stats["overall_rating"],
            "total_ratings": stats["total_ratings"],
            "communication_avg": stats["communication_avg"],
            "expertise_avg": stats["expertise_avg"],
            "responsiveness_avg": stats["responsiveness_avg"],
            "value_avg": stats["value_avg"],
            "star_distribution": stats["star_distribution"],
            "last_updated": datetime.utcnow().isoformat()
        }
        
        supabase.table("lawyer_rating_stats") \
            .upsert(upsert_data) \
            .execute()
        
        logger.info(f"Estatísticas atualizadas para advogado {lawyer_id}")
        
    except Exception as e:
        logger.error(f"Erro ao atualizar estatísticas: {e}")

async def _calculate_lawyer_stats(supabase, lawyer_id: str) -> Dict[str, Any]:
    """
    Calcula estatísticas de avaliação do advogado.
    """
    try:
        result = supabase.table("ratings") \
            .select("*") \
            .eq("lawyer_id", lawyer_id) \
            .eq("rater_type", "client") \
            .execute()
        
        if not result.data:
            return {
                "overall_rating": 0.0,
                "total_ratings": 0,
                "communication_avg": 0.0,
                "expertise_avg": 0.0,
                "responsiveness_avg": 0.0,
                "value_avg": 0.0,
                "star_distribution": {str(i): 0 for i in range(1, 6)}
            }
        
        ratings = result.data
        total_ratings = len(ratings)
        
        # Calcular médias
        avg_overall = sum(r["overall_rating"] for r in ratings) / total_ratings
        avg_communication = sum(r["communication_rating"] for r in ratings) / total_ratings
        avg_expertise = sum(r["expertise_rating"] for r in ratings) / total_ratings
        avg_responsiveness = sum(r["responsiveness_rating"] for r in ratings) / total_ratings
        avg_value = sum(r["value_rating"] for r in ratings) / total_ratings
        
        # Distribuição de estrelas
        star_distribution = {str(i): 0 for i in range(1, 6)}
        for rating in ratings:
            star = str(int(round(rating["overall_rating"])))
            if star in star_distribution:
                star_distribution[star] += 1
        
        return {
            "overall_rating": round(avg_overall, 2),
            "total_ratings": total_ratings,
            "communication_avg": round(avg_communication, 2),
            "expertise_avg": round(avg_expertise, 2),
            "responsiveness_avg": round(avg_responsiveness, 2),
            "value_avg": round(avg_value, 2),
            "star_distribution": star_distribution
        }
        
    except Exception as e:
        logger.error(f"Erro ao calcular estatísticas: {e}")
        return {
            "overall_rating": 0.0,
            "total_ratings": 0,
            "communication_avg": 0.0,
            "expertise_avg": 0.0,
            "responsiveness_avg": 0.0,
            "value_avg": 0.0,
            "star_distribution": {str(i): 0 for i in range(1, 6)}
        }

async def _get_lawyer_rating_stats(supabase, lawyer_id: str) -> Dict[str, Any]:
    """
    Busca estatísticas agregadas do advogado.
    """
    try:
        # Primeiro tentar buscar estatísticas já calculadas
        stats_result = supabase.table("lawyer_rating_stats") \
            .select("*") \
            .eq("lawyer_id", lawyer_id) \
            .single() \
            .execute()
        
        if stats_result.data:
            return stats_result.data
        
        # Se não existir, calcular na hora
        stats = await _calculate_lawyer_stats(supabase, lawyer_id)
        return stats
        
    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas: {e}")
        return {
            "overall_rating": 0.0,
            "total_ratings": 0,
            "communication_avg": 0.0,
            "expertise_avg": 0.0,
            "responsiveness_avg": 0.0,
            "value_avg": 0.0,
            "star_distribution": {str(i): 0 for i in range(1, 6)}
        }

async def _send_rating_notification(rating_request: RatingRequest, current_user: dict):
    """
    Envia notificação sobre nova avaliação.
    """
    try:
        target_user_id = None
        notification_title = ""
        notification_message = ""
        
        if rating_request.rater_type == "client":
            # Cliente avaliou advogado
            target_user_id = rating_request.lawyer_id
            notification_title = "Nova Avaliação Recebida"
            notification_message = f"Você recebeu uma avaliação de {current_user.get('name', 'um cliente')}"
        else:
            # Advogado avaliou cliente
            target_user_id = rating_request.client_id
            notification_title = "Avaliação do Advogado"
            notification_message = f"Você foi avaliado por {current_user.get('name', 'seu advogado')}"
        
        if target_user_id and notify_service:
            await notify_service.send_notification(
                user_id=target_user_id,
                notification_type="rating_received",
                title=notification_title,
                message=notification_message,
                data={
                    "case_id": rating_request.case_id,
                    "rating": rating_request.overall_rating,
                    "rater_type": rating_request.rater_type
                }
            )
            
    except Exception as e:
        logger.error(f"Erro ao enviar notificação de avaliação: {e}")
        # Não falhar a criação da avaliação por erro de notificação 