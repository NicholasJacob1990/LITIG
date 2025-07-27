#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LLM Enhanced Partnership Routes
===============================

Rotas específicas para recomendações de parcerias aprimoradas com LLMs.
Integra-se ao sistema tradicional de parcerias com análises inteligentes.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.security import HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
import os
from datetime import datetime

from ..dependencies.auth import get_current_user
from ..dependencies.database import get_async_db
from ..services.partnership_recommendation_service import (
    PartnershipRecommendationService,
    PartnershipRecommendation
)

router = APIRouter(prefix="/partnerships", tags=["Parcerias LLM Enhanced"])
security = HTTPBearer()


@router.get("/recommendations/enhanced/{lawyer_id}", 
            response_model=List[dict],
            summary="🤖 Recomendações de Parcerias com LLM")
async def get_enhanced_partnership_recommendations(
    lawyer_id: str,
    limit: int = Query(10, ge=1, le=20, description="Número de recomendações"),
    min_confidence: float = Query(0.6, ge=0.0, le=1.0, description="Confiança mínima"),
    exclude_same_firm: bool = Query(True, description="Excluir mesmo escritório"),
    enable_llm: bool = Query(True, description="Ativar análises LLM"),
    expand_search: bool = Query(False, description="🆕 Incluir perfis públicos via busca externa"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    🤖 **Recomendações de Parcerias Aprimoradas com LLM**
    
    Combina algoritmo tradicional de clustering com análises LLM para:
    - Análise contextual de sinergia profissional
    - Avaliação de compatibilidade de estilos de trabalho
    - Identificação de oportunidades estratégicas
    - Explicações inteligentes das recomendações
    
    **🆕 Modelo Híbrido (expand_search=true):**
    - Combina advogados registrados na plataforma
    - Com perfis públicos encontrados via busca na web
    - Diferenciação visual por `status` (verified vs public_profile)
    
    **Algoritmo Híbrido:**
    - 70% Score tradicional (complementaridade de clusters)
    - 30% Score LLM (sinergia e compatibilidade)
    
    **Retorna:**
    Lista de recomendações com scores combinados e insights LLM.
    """
    
    # Verificar se LLM está habilitado no sistema
    llm_system_enabled = os.getenv("ENABLE_PARTNERSHIP_LLM", "false").lower() == "true"
    
    if not llm_system_enabled:
        raise HTTPException(
            status_code=501,
            detail="Sistema de parcerias LLM não está habilitado. Configure ENABLE_PARTNERSHIP_LLM=true"
        )
    
    try:
        # Inicializar serviço de recomendações
        recommendation_service = PartnershipRecommendationService(db)
        
        # Verificar se advogado existe
        if not await _lawyer_exists(db, lawyer_id):
            raise HTTPException(
                status_code=404,
                detail=f"Advogado {lawyer_id} não encontrado"
            )
        
        # Buscar recomendações (já inclui LLM se habilitado no serviço)
        recommendations = await recommendation_service.get_recommendations(
            lawyer_id=lawyer_id,
            limit=limit,
            min_confidence=min_confidence,
            exclude_same_firm=exclude_same_firm,
            expand_search=expand_search  # 🆕 Parâmetro de busca híbrida
        )
        
        if not recommendations:
            return {
                "message": "Nenhuma recomendação encontrada",
                "suggestions": [
                    "Reduza min_confidence para incluir mais candidatos",
                    "Verifique se o advogado possui clusters de especialização",
                    "Considere incluir advogados do mesmo escritório (exclude_same_firm=false)"
                ]
            }
        
        # Formatar resposta com insights LLM
        formatted_recommendations = []
        
        for rec in recommendations:
            # Estrutura básica da recomendação
            rec_dict = {
                "lawyer_id": rec.lawyer_id,
                "lawyer_name": rec.lawyer_name,
                "firm_name": rec.firm_name,
                "compatibility_clusters": rec.compatibility_clusters,
                "traditional_scores": {
                    "complementarity_score": round(rec.complementarity_score, 3),
                    "diversity_score": round(rec.diversity_score, 3),
                    "momentum_score": round(rec.momentum_score, 3),
                    "reputation_score": round(rec.reputation_score, 3),
                    "firm_synergy_score": round(rec.firm_synergy_score, 3)
                },
                "final_score": round(rec.final_score, 3),
                "recommendation_reason": rec.recommendation_reason,
                "firm_synergy_reason": rec.firm_synergy_reason,
                # 🆕 Campos do modelo híbrido
                "status": rec.status,  # "verified" ou "public_profile"
                "invitation_id": rec.invitation_id,  # Para perfis convidados
                "profile_data": rec.profile_data  # Dados do perfil externo (se aplicável)
            }
            
            # Adicionar insights LLM se disponíveis
            if hasattr(rec, 'llm_enhanced') and rec.llm_enhanced and hasattr(rec, 'llm_insights'):
                insights = rec.llm_insights
                rec_dict["llm_analysis"] = {
                    "synergy_score": round(insights.synergy_score, 3),
                    "compatibility_factors": insights.compatibility_factors,
                    "strategic_opportunities": insights.strategic_opportunities,
                    "potential_challenges": insights.potential_challenges,
                    "collaboration_style_match": insights.collaboration_style_match,
                    "market_positioning_advantage": insights.market_positioning_advantage,
                    "client_value_proposition": insights.client_value_proposition,
                    "confidence_score": round(insights.confidence_score, 3),
                    "reasoning": insights.reasoning
                }
                rec_dict["algorithm_version"] = "hybrid_traditional_llm_v1.0"
            else:
                rec_dict["llm_analysis"] = None
                rec_dict["algorithm_version"] = "traditional_clustering_v2.0"
            
            formatted_recommendations.append(rec_dict)
        
        # 🆕 Calcular estatísticas do modelo híbrido
        internal_count = sum(1 for rec in recommendations if rec.status == "verified")
        external_count = sum(1 for rec in recommendations if rec.status == "public_profile")
        
        return {
            "lawyer_id": lawyer_id,
            "total_recommendations": len(formatted_recommendations),
            "algorithm_info": {
                "llm_enabled": llm_system_enabled and enable_llm,
                "traditional_weight": 0.7,
                "llm_weight": 0.3,
                "min_confidence": min_confidence,
                "exclude_same_firm": exclude_same_firm,
                "expand_search": expand_search,  # 🆕 Busca híbrida habilitada
                "hybrid_model": expand_search  # 🆕 Indica se está usando modelo híbrido
            },
            "recommendations": formatted_recommendations,
            "metadata": {
                "generated_at": f"{datetime.utcnow().isoformat()}Z",
                "system_version": "partnership_llm_enhanced_v1.0",
                # 🆕 Estatísticas do modelo híbrido
                "hybrid_stats": {
                    "internal_profiles": internal_count,
                    "external_profiles": external_count,
                    "hybrid_ratio": round(external_count / max(len(recommendations), 1), 2) if expand_search else 0.0
                }
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao gerar recomendações: {str(e)}"
        )


@router.get("/analysis/synergy/{lawyer_a_id}/{lawyer_b_id}",
            summary="🧠 Análise LLM de Sinergia entre Advogados")
async def analyze_lawyer_synergy(
    lawyer_a_id: str,
    lawyer_b_id: str,
    collaboration_context: Optional[str] = Query(None, description="Contexto específico da colaboração"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    🧠 **Análise LLM de Sinergia Profissional**
    
    Usa LLMs para análise detalhada de compatibilidade entre dois advogados:
    - Complementaridade de especialidades
    - Compatibilidade de estilos de trabalho
    - Oportunidades estratégicas
    - Desafios potenciais
    - Proposta de valor para clientes
    
    **Exemplo de contexto:**
    "Assessoria completa para startup em expansão internacional"
    """
    
    # Verificar se LLM está habilitado
    llm_enabled = os.getenv("ENABLE_PARTNERSHIP_LLM", "false").lower() == "true"
    
    if not llm_enabled:
        raise HTTPException(
            status_code=501,
            detail="Análises LLM não estão habilitadas"
        )
    
    try:
        # Verificar se ambos advogados existem
        if not await _lawyer_exists(db, lawyer_a_id):
            raise HTTPException(status_code=404, detail=f"Advogado {lawyer_a_id} não encontrado")
        
        if not await _lawyer_exists(db, lawyer_b_id):
            raise HTTPException(status_code=404, detail=f"Advogado {lawyer_b_id} não encontrado")
        
        # Inicializar serviços
        recommendation_service = PartnershipRecommendationService(db)
        
        if not recommendation_service.llm_enhancer:
            raise HTTPException(
                status_code=503,
                detail="Serviço LLM não está disponível"
            )
        
        # Criar perfis para análise
        profile_a = await recommendation_service._create_lawyer_profile_for_llm(lawyer_a_id)
        profile_b = await recommendation_service._create_lawyer_profile_for_llm(lawyer_b_id)
        
        if not profile_a or not profile_b:
            raise HTTPException(
                status_code=400,
                detail="Não foi possível criar perfis completos para análise"
            )
        
        # Análise LLM
        insights = await recommendation_service.llm_enhancer.analyze_partnership_synergy(
            profile_a, profile_b, collaboration_context
        )
        
        return {
            "lawyer_a": {
                "id": profile_a.lawyer_id,
                "name": profile_a.name,
                "firm": profile_a.firm_name,
                "specializations": profile_a.specialization_areas
            },
            "lawyer_b": {
                "id": profile_b.lawyer_id,
                "name": profile_b.name,
                "firm": profile_b.firm_name,
                "specializations": profile_b.specialization_areas
            },
            "collaboration_context": collaboration_context,
            "synergy_analysis": {
                "synergy_score": round(insights.synergy_score, 3),
                "compatibility_factors": insights.compatibility_factors,
                "strategic_opportunities": insights.strategic_opportunities,
                "potential_challenges": insights.potential_challenges,
                "collaboration_style_match": insights.collaboration_style_match,
                "market_positioning_advantage": insights.market_positioning_advantage,
                "client_value_proposition": insights.client_value_proposition,
                "confidence_score": round(insights.confidence_score, 3),
                "detailed_reasoning": insights.reasoning
            },
            "metadata": {
                "analysis_type": "llm_partnership_synergy",
                "generated_at": f"{datetime.utcnow().isoformat()}Z",
                "model_version": "partnership_llm_v1.0"
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro na análise de sinergia: {str(e)}"
        )


async def _lawyer_exists(db: AsyncSession, lawyer_id: str) -> bool:
    """Verifica se advogado existe no banco."""
    from sqlalchemy import text
    
    query = text("SELECT 1 FROM lawyers WHERE id = :lawyer_id LIMIT 1")
    result = await db.execute(query, {"lawyer_id": lawyer_id})
    return result.fetchone() is not None 