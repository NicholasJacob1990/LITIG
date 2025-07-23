"""
backend/routes/providers.py

Rotas da API para prestadores de serviços (advogados).
Inclui endpoints para insights de performance, diagnósticos e benchmarks.
"""
import logging
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from slowapi import Limiter
from slowapi.util import get_remote_address
from pydantic import BaseModel, Field

from auth import get_current_user
from config import get_supabase_client
from services.provider_insights_service import ProviderInsightsService

logger = logging.getLogger(__name__)

# Rate limiter para proteção dos endpoints
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/provider", tags=["Providers"])

# ============================================================================
# Modelos de Resposta
# ============================================================================

class WeakPoint(BaseModel):
    """Ponto fraco identificado no perfil do prestador"""
    feature: str = Field(..., description="Nome da feature (ex: 'response_time')")
    feature_label: str = Field(..., description="Rótulo amigável (ex: 'Tempo de Resposta')")
    current_value: float = Field(..., description="Valor atual da métrica")
    benchmark_p50: float = Field(..., description="Percentil 50 do mercado")
    benchmark_p75: float = Field(..., description="Percentil 75 do mercado")
    benchmark_p90: float = Field(..., description="Percentil 90 do mercado")
    impact_score: float = Field(..., description="Impacto no ranking (0-1)")
    improvement_potential: str = Field(..., description="Potencial de melhoria")

class Benchmark(BaseModel):
    """Benchmark anônimo de mercado"""
    feature: str = Field(..., description="Nome da feature")
    feature_label: str = Field(..., description="Rótulo amigável")
    your_value: float = Field(..., description="Seu valor")
    your_percentile: int = Field(..., description="Seu percentil no mercado")
    market_p50: float = Field(..., description="Mediana do mercado")
    market_p75: float = Field(..., description="Percentil 75")
    market_p90: float = Field(..., description="Percentil 90")
    comparison: str = Field(..., description="'above'|'below'|'at' market")

class Suggestion(BaseModel):
    """Sugestão de melhoria personalizada"""
    category: str = Field(..., description="Categoria da sugestão")
    title: str = Field(..., description="Título da sugestão")
    description: str = Field(..., description="Descrição detalhada")
    priority: str = Field(..., description="'high'|'medium'|'low'")
    estimated_impact: str = Field(..., description="Impacto estimado")
    timeframe: str = Field(..., description="Prazo para implementação")
    action_items: List[str] = Field(..., description="Itens de ação específicos")

class PerformanceInsights(BaseModel):
    """Insights de performance para prestadores"""
    provider_id: str = Field(..., description="ID do prestador")
    overall_score: int = Field(..., description="Nota geral do perfil (0-100)")
    grade: str = Field(..., description="Classificação textual")
    trend: str = Field(..., description="Tendência de evolução")
    last_updated: datetime = Field(..., description="Última atualização")
    
    # Análise de pontos fracos
    weak_points: List[WeakPoint] = Field(..., description="Pontos que precisam de melhoria")
    
    # Benchmarks de mercado
    benchmarks: List[Benchmark] = Field(..., description="Comparação com mercado")
    
    # Sugestões de melhoria
    improvement_suggestions: List[Suggestion] = Field(..., description="Sugestões práticas")
    
    # Métricas de evolução
    evolution_metrics: Dict[str, Any] = Field(..., description="Métricas de evolução temporal")
    
    # Metadados
    analysis_period: str = Field(..., description="Período analisado")
    market_segment: str = Field(..., description="Segmento de mercado para comparação")

# ============================================================================
# Endpoints
# ============================================================================

@router.get("/performance-insights", response_model=PerformanceInsights)
@limiter.limit("10/minute")
async def get_performance_insights(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client),
    period_days: int = Query(90, ge=30, le=365, description="Período de análise em dias"),
    include_benchmarks: bool = Query(True, description="Incluir benchmarks de mercado"),
    include_suggestions: bool = Query(True, description="Incluir sugestões de melhoria")
):
    """
    Obtém insights de performance detalhados para o prestador logado.
    
    Fornece:
    - Análise dos 3 pontos mais fracos do perfil
    - Benchmarks anônimos por área de atuação
    - Sugestões práticas personalizadas
    - Histórico de evolução (últimos 3 meses)
    - Nota global do perfil (0-100)
    
    Rate limit: 10 requests/minute por usuário
    """
    try:
        # Validar se é um prestador
        if current_user.get("user_metadata", {}).get("user_type") != "LAWYER":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado. Apenas para prestadores de serviços."
            )

        provider_id = current_user.get("id")
        if not provider_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não autenticado."
            )

        # Criar serviço de insights
        insights_service = ProviderInsightsService(supabase)
        
        # Gerar insights
        insights = await insights_service.generate_performance_insights(
            provider_id=provider_id,
            period_days=period_days,
            include_benchmarks=include_benchmarks,
            include_suggestions=include_suggestions
        )
        
        return insights

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar insights de performance: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao gerar insights"
        )

@router.get("/performance-summary", response_model=Dict[str, Any])
@limiter.limit("30/minute")
async def get_performance_summary(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Obtém resumo rápido de performance para exibição no dashboard.
    
    Versão simplificada do endpoint principal, otimizada para carregamento rápido.
    """
    try:
        # Validar se é um prestador
        if current_user.get("user_metadata", {}).get("user_type") != "LAWYER":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado. Apenas para prestadores de serviços."
            )

        provider_id = current_user.get("id")
        if not provider_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não autenticado."
            )

        # Criar serviço de insights
        insights_service = ProviderInsightsService(supabase)
        
        # Gerar resumo
        summary = await insights_service.generate_performance_summary(provider_id)
        
        return summary

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar resumo de performance: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao gerar resumo"
        )

@router.get("/market-benchmarks", response_model=List[Benchmark])
@limiter.limit("20/minute")
async def get_market_benchmarks(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client),
    area: Optional[str] = Query(None, description="Área de atuação específica"),
    features: Optional[List[str]] = Query(None, description="Features específicas para benchmark")
):
    """
    Obtém benchmarks de mercado anônimos para comparação.
    
    Permite filtrar por área de atuação e features específicas.
    """
    try:
        # Validar se é um prestador
        if current_user.get("user_metadata", {}).get("user_type") != "LAWYER":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado. Apenas para prestadores de serviços."
            )

        provider_id = current_user.get("id")
        if not provider_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não autenticado."
            )

        # Criar serviço de insights
        insights_service = ProviderInsightsService(supabase)
        
        # Gerar benchmarks
        benchmarks = await insights_service.generate_market_benchmarks(
            provider_id=provider_id,
            area=area,
            features=features
        )
        
        return benchmarks

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar benchmarks de mercado: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao gerar benchmarks"
        ) 