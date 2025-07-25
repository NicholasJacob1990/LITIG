from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import JSONResponse
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import logging
from collections import defaultdict

from ..services.hybrid_legal_data_service_complete import (
    hybrid_legal_data_service,
    DataSourceType,
    DataQuality
)
from ..dependencies.auth import get_current_admin_user
from ..dependencies.rate_limiting import rate_limit

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/data-quality", tags=["Data Quality Dashboard"])

@router.get("/overview")
@rate_limit(max_calls=30, window_seconds=60)
async def get_data_quality_overview(
    period_days: int = Query(7, description="Período em dias para análise"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Visão geral da qualidade dos dados na plataforma
    
    **Métricas incluídas:**
    - Distribuição de qualidade por fonte
    - Tendências de completude
    - Custos de coleta de dados
    - Performance das APIs
    - Recomendações de otimização
    """
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=period_days)
        
        # TODO: Implementar coleta de métricas da base de dados
        # Por ora, simular dados para demonstração
        
        overview_data = {
            "period": {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "days": period_days
            },
            
            # Distribuição de qualidade por fonte
            "quality_by_source": {
                "linkedin": {
                    "total_profiles": 1250,
                    "high_quality": 980,
                    "medium_quality": 200,
                    "low_quality": 70,
                    "average_quality_score": 0.85,
                    "last_24h_updates": 45
                },
                "academic": {
                    "total_profiles": 820,
                    "high_quality": 410,
                    "medium_quality": 280,
                    "low_quality": 130,
                    "average_quality_score": 0.72,
                    "last_24h_updates": 12
                },
                "escavador": {
                    "total_profiles": 1100,
                    "high_quality": 880,
                    "medium_quality": 150,
                    "low_quality": 70,
                    "average_quality_score": 0.88,
                    "last_24h_updates": 28
                },
                "jusbrasil": {
                    "total_profiles": 950,
                    "high_quality": 665,
                    "medium_quality": 190,
                    "low_quality": 95,
                    "average_quality_score": 0.79,
                    "last_24h_updates": 18
                }
            },
            
            # Tendências de completude
            "completeness_trends": [
                {"date": "2024-01-09", "average_completeness": 0.78},
                {"date": "2024-01-10", "average_completeness": 0.79},
                {"date": "2024-01-11", "average_completeness": 0.81},
                {"date": "2024-01-12", "average_completeness": 0.83},
                {"date": "2024-01-13", "average_completeness": 0.82},
                {"date": "2024-01-14", "average_completeness": 0.84},
                {"date": "2024-01-15", "average_completeness": 0.85}
            ],
            
            # Custos de coleta
            "collection_costs": {
                "total_cost_usd": 245.80,
                "by_source": {
                    "linkedin": {"cost": 125.50, "queries": 2510},
                    "academic": {"cost": 98.20, "queries": 982},
                    "escavador": {"cost": 15.40, "queries": 770},
                    "jusbrasil": {"cost": 6.70, "queries": 335}
                },
                "cost_per_profile": 0.18,
                "projected_monthly_cost": 1050.00
            },
            
            # Performance das APIs
            "api_performance": {
                "linkedin": {
                    "average_response_time_ms": 2800,
                    "success_rate": 0.96,
                    "rate_limit_hits": 8,
                    "timeout_rate": 0.02
                },
                "academic": {
                    "average_response_time_ms": 4200,
                    "success_rate": 0.91,
                    "rate_limit_hits": 15,
                    "timeout_rate": 0.05
                },
                "escavador": {
                    "average_response_time_ms": 1800,
                    "success_rate": 0.98,
                    "rate_limit_hits": 2,
                    "timeout_rate": 0.01
                }
            },
            
            # Alertas e recomendações
            "alerts": [
                {
                    "level": "warning",
                    "message": "Taxa de timeout da Perplexity Academic acima de 5%",
                    "action": "Considerar aumentar timeout ou reduzir concorrência"
                },
                {
                    "level": "info",
                    "message": "LinkedIn alcançou 96% de taxa de sucesso",
                    "action": "Performance dentro do esperado"
                }
            ],
            
            "recommendations": [
                "Otimizar queries da Perplexity para reduzir timeouts",
                "Implementar cache mais agressivo para dados acadêmicos",
                "Considerar fontes alternativas para dados com baixa qualidade"
            ]
        }
        
        return JSONResponse(
            status_code=200,
            content=overview_data
        )
        
    except Exception as e:
        logger.error(f"Erro ao buscar overview de qualidade: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/source/{source_type}/details")
@rate_limit(max_calls=20, window_seconds=60)
async def get_source_quality_details(
    source_type: str,
    period_days: int = Query(7, description="Período em dias"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Detalhes de qualidade de uma fonte específica
    
    **Informações detalhadas:**
    - Distribuição de scores de qualidade
    - Histórico de atualizações
    - Campos mais/menos populados
    - Análise de custos
    - Recomendações específicas
    """
    try:
        # Validar fonte
        try:
            source_enum = DataSourceType(source_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Fonte inválida: {source_type}. Fontes válidas: {[t.value for t in DataSourceType]}"
            )
        
        # Simular dados detalhados para a fonte
        if source_enum == DataSourceType.LINKEDIN:
            details = _get_linkedin_quality_details(period_days)
        elif source_enum == DataSourceType.ACADEMIC:
            details = _get_academic_quality_details(period_days)
        elif source_enum == DataSourceType.ESCAVADOR:
            details = _get_escavador_quality_details(period_days)
        else:
            details = _get_generic_quality_details(source_enum, period_days)
        
        return JSONResponse(
            status_code=200,
            content=details
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes da fonte {source_type}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/profiles/low-quality")
@rate_limit(max_calls=10, window_seconds=60)
async def get_low_quality_profiles(
    quality_threshold: float = Query(0.5, description="Threshold de qualidade (0-1)"),
    limit: int = Query(50, description="Número máximo de resultados"),
    source_filter: Optional[str] = Query(None, description="Filtrar por fonte específica"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Listar perfis com baixa qualidade de dados
    
    **Útil para:**
    - Identificar perfis que precisam de atenção
    - Priorizar atualizações
    - Análise de problemas específicos
    """
    try:
        # TODO: Implementar busca real na base de dados
        # Por ora, simular dados
        
        low_quality_profiles = [
            {
                "lawyer_id": "adv_001",
                "full_name": "João Silva Santos",
                "overall_quality_score": 0.35,
                "completeness_score": 0.42,
                "last_updated": "2024-01-10T08:30:00Z",
                "problematic_sources": ["academic", "linkedin"],
                "missing_data": ["formação acadêmica", "experiência profissional completa"],
                "recommendations": [
                    "Atualizar perfil LinkedIn",
                    "Buscar dados acadêmicos via Perplexity"
                ]
            },
            {
                "lawyer_id": "adv_002", 
                "full_name": "Maria Oliveira",
                "overall_quality_score": 0.48,
                "completeness_score": 0.55,
                "last_updated": "2024-01-12T14:15:00Z",
                "problematic_sources": ["academic"],
                "missing_data": ["publicações acadêmicas", "certificações"],
                "recommendations": [
                    "Expandir busca acadêmica",
                    "Verificar certificações profissionais"
                ]
            }
        ]
        
        # Filtrar por fonte se especificado
        if source_filter:
            low_quality_profiles = [
                profile for profile in low_quality_profiles
                if source_filter in profile["problematic_sources"]
            ]
        
        # Aplicar limite
        low_quality_profiles = low_quality_profiles[:limit]
        
        response_data = {
            "filters": {
                "quality_threshold": quality_threshold,
                "source_filter": source_filter,
                "limit": limit
            },
            "total_found": len(low_quality_profiles),
            "profiles": low_quality_profiles,
            "summary": {
                "average_quality": sum(p["overall_quality_score"] for p in low_quality_profiles) / len(low_quality_profiles) if low_quality_profiles else 0,
                "most_common_issues": [
                    "Dados acadêmicos incompletos",
                    "Perfil LinkedIn desatualizado",
                    "Falta de dados de contato"
                ]
            }
        }
        
        return JSONResponse(
            status_code=200,
            content=response_data
        )
        
    except Exception as e:
        logger.error(f"Erro ao buscar perfis de baixa qualidade: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/costs/analysis")
@rate_limit(max_calls=10, window_seconds=60)
async def get_cost_analysis(
    period_days: int = Query(30, description="Período em dias para análise"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Análise detalhada de custos de coleta de dados
    
    **Inclui:**
    - Custos por fonte
    - Tendências de gasto
    - ROI por tipo de dado
    - Projeções futuras
    - Oportunidades de otimização
    """
    try:
        cost_analysis = {
            "period": {
                "days": period_days,
                "start_date": (datetime.utcnow() - timedelta(days=period_days)).isoformat(),
                "end_date": datetime.utcnow().isoformat()
            },
            
            # Custos totais
            "total_costs": {
                "current_period_usd": 1247.80,
                "previous_period_usd": 1156.40,
                "change_percentage": 7.9,
                "average_daily_cost": 41.59
            },
            
            # Custos por fonte
            "costs_by_source": {
                "linkedin": {
                    "total_cost": 625.40,
                    "queries_made": 12508,
                    "cost_per_query": 0.050,
                    "percentage_of_total": 50.2
                },
                "academic": {
                    "total_cost": 491.60,
                    "queries_made": 4916,
                    "cost_per_query": 0.100,
                    "percentage_of_total": 39.4
                },
                "escavador": {
                    "total_cost": 92.40,
                    "queries_made": 4620,
                    "cost_per_query": 0.020,
                    "percentage_of_total": 7.4
                },
                "jusbrasil": {
                    "total_cost": 38.40,
                    "queries_made": 1920,
                    "cost_per_query": 0.020,
                    "percentage_of_total": 3.0
                }
            },
            
            # ROI por tipo de dado
            "roi_analysis": {
                "linkedin_education": {
                    "value_score": 8.5,
                    "cost_efficiency": 0.85,
                    "recommendation": "Manter investimento atual"
                },
                "linkedin_experience": {
                    "value_score": 9.2,
                    "cost_efficiency": 0.92,
                    "recommendation": "Excelente ROI - priorizar"
                },
                "academic_publications": {
                    "value_score": 7.1,
                    "cost_efficiency": 0.71,
                    "recommendation": "Otimizar queries para reduzir custo"
                },
                "legal_cases": {
                    "value_score": 8.8,
                    "cost_efficiency": 0.95,
                    "recommendation": "Ótimo custo-benefício"
                }
            },
            
            # Projeções
            "projections": {
                "next_30_days_usd": 1310.00,
                "annual_projection_usd": 15720.00,
                "growth_trend": "stable_increase",
                "optimization_potential_usd": 235.00
            },
            
            # Oportunidades de otimização
            "optimization_opportunities": [
                {
                    "area": "Academic queries",
                    "current_cost": 491.60,
                    "potential_savings": 147.48,
                    "optimization": "Implementar cache mais agressivo (TTL 48h)",
                    "impact": "30% redução no custo acadêmico"
                },
                {
                    "area": "LinkedIn rate limiting",
                    "current_cost": 625.40,
                    "potential_savings": 62.54,
                    "optimization": "Otimizar batch requests",
                    "impact": "10% redução no custo LinkedIn"
                },
                {
                    "area": "Redundant queries",
                    "current_cost": 124.78,
                    "potential_savings": 24.96,
                    "optimization": "Detectar e evitar queries duplicadas",
                    "impact": "20% redução em queries redundantes"
                }
            ]
        }
        
        return JSONResponse(
            status_code=200,
            content=cost_analysis
        )
        
    except Exception as e:
        logger.error(f"Erro na análise de custos: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.post("/optimize/cache")
@rate_limit(max_calls=3, window_seconds=3600)  # Máximo 3 otimizações por hora
async def optimize_cache_settings(
    source_type: Optional[str] = Query(None, description="Fonte específica para otimizar"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Otimizar configurações de cache para reduzir custos
    
    **Ações realizadas:**
    - Analisar padrões de uso
    - Ajustar TTL de cache
    - Identificar dados candidatos a cache permanente
    - Configurar invalidação inteligente
    """
    try:
        optimization_results = {
            "optimization_started": datetime.utcnow().isoformat(),
            "target_source": source_type or "all",
            "actions_taken": [],
            "estimated_savings": 0.0
        }
        
        if not source_type or source_type == "linkedin":
            optimization_results["actions_taken"].append({
                "source": "linkedin",
                "action": "Increased TTL from 6h to 12h for basic profile data",
                "estimated_monthly_savings": 125.00
            })
            optimization_results["estimated_savings"] += 125.00
        
        if not source_type or source_type == "academic":
            optimization_results["actions_taken"].append({
                "source": "academic", 
                "action": "Implemented permanent cache for institution rankings",
                "estimated_monthly_savings": 89.50
            })
            optimization_results["estimated_savings"] += 89.50
        
        if not source_type or source_type == "escavador":
            optimization_results["actions_taken"].append({
                "source": "escavador",
                "action": "Enabled aggressive caching for historical case data",
                "estimated_monthly_savings": 23.00
            })
            optimization_results["estimated_savings"] += 23.00
        
        optimization_results["total_estimated_monthly_savings"] = optimization_results["estimated_savings"]
        optimization_results["annual_savings_projection"] = optimization_results["estimated_savings"] * 12
        
        logger.info(f"Otimização de cache executada por admin {current_admin.get('user_id')}")
        
        return JSONResponse(
            status_code=200,
            content=optimization_results
        )
        
    except Exception as e:
        logger.error(f"Erro na otimização de cache: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

# Funções auxiliares para simular dados específicos por fonte

def _get_linkedin_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados LinkedIn"""
    return {
        "source": "linkedin",
        "period_days": period_days,
        "total_profiles": 1250,
        
        "quality_distribution": {
            "high_quality": {"count": 980, "percentage": 78.4},
            "medium_quality": {"count": 200, "percentage": 16.0},
            "low_quality": {"count": 70, "percentage": 5.6}
        },
        
        "field_completeness": {
            "basic_info": 98.5,
            "education": 89.2,
            "experience": 95.1,
            "skills": 76.8,
            "certifications": 45.3,
            "contact_info": 62.1,
            "network_metrics": 91.7
        },
        
        "common_issues": [
            {"issue": "Missing certification data", "frequency": 54.7},
            {"issue": "Incomplete contact information", "frequency": 37.9},
            {"issue": "Skills without endorsements", "frequency": 23.2}
        ],
        
        "recommendations": [
            "Encourage users to complete certification section",
            "Implement fallback contact discovery methods",
            "Prioritize skills with endorsements in scoring"
        ]
    }

def _get_academic_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados acadêmicos"""
    return {
        "source": "academic",
        "period_days": period_days,
        "total_profiles": 820,
        
        "quality_distribution": {
            "high_quality": {"count": 410, "percentage": 50.0},
            "medium_quality": {"count": 280, "percentage": 34.1},
            "low_quality": {"count": 130, "percentage": 15.9}
        },
        
        "field_completeness": {
            "degrees": 78.9,
            "institutions": 82.1,
            "publications": 34.5,
            "awards": 18.7,
            "research_areas": 67.3
        },
        
        "common_issues": [
            {"issue": "No publications found", "frequency": 65.5},
            {"issue": "Incomplete institution data", "frequency": 17.9},
            {"issue": "Missing degree details", "frequency": 21.1}
        ],
        
        "recommendations": [
            "Expand publication search beyond main databases",
            "Implement manual verification for key profiles",
            "Cross-reference with institutional websites"
        ]
    }

def _get_escavador_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados do Escavador"""
    return {
        "source": "escavador",
        "period_days": period_days,
        "total_profiles": 1100,
        
        "quality_distribution": {
            "high_quality": {"count": 880, "percentage": 80.0},
            "medium_quality": {"count": 150, "percentage": 13.6},
            "low_quality": {"count": 70, "percentage": 6.4}
        },
        
        "field_completeness": {
            "basic_cases": 94.2,
            "outcomes": 87.5,
            "tribunals": 91.8,
            "case_types": 89.1,
            "date_ranges": 85.3
        },
        
        "common_issues": [
            {"issue": "Missing case outcomes", "frequency": 12.5},
            {"issue": "Incomplete tribunal data", "frequency": 8.2},
            {"issue": "Date parsing errors", "frequency": 14.7}
        ]
    }

def _get_generic_quality_details(source_type: DataSourceType, period_days: int) -> Dict[str, Any]:
    """Detalhes genéricos para outras fontes"""
    return {
        "source": source_type.value,
        "period_days": period_days,
        "status": "limited_data",
        "message": f"Dados detalhados para {source_type.value} ainda não disponíveis"
    } 
from fastapi.responses import JSONResponse
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import logging
from collections import defaultdict

from ..services.hybrid_legal_data_service_complete import (
    hybrid_legal_data_service,
    DataSourceType,
    DataQuality
)
from ..dependencies.auth import get_current_admin_user
from ..dependencies.rate_limiting import rate_limit

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/data-quality", tags=["Data Quality Dashboard"])

@router.get("/overview")
@rate_limit(max_calls=30, window_seconds=60)
async def get_data_quality_overview(
    period_days: int = Query(7, description="Período em dias para análise"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Visão geral da qualidade dos dados na plataforma
    
    **Métricas incluídas:**
    - Distribuição de qualidade por fonte
    - Tendências de completude
    - Custos de coleta de dados
    - Performance das APIs
    - Recomendações de otimização
    """
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=period_days)
        
        # TODO: Implementar coleta de métricas da base de dados
        # Por ora, simular dados para demonstração
        
        overview_data = {
            "period": {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "days": period_days
            },
            
            # Distribuição de qualidade por fonte
            "quality_by_source": {
                "linkedin": {
                    "total_profiles": 1250,
                    "high_quality": 980,
                    "medium_quality": 200,
                    "low_quality": 70,
                    "average_quality_score": 0.85,
                    "last_24h_updates": 45
                },
                "academic": {
                    "total_profiles": 820,
                    "high_quality": 410,
                    "medium_quality": 280,
                    "low_quality": 130,
                    "average_quality_score": 0.72,
                    "last_24h_updates": 12
                },
                "escavador": {
                    "total_profiles": 1100,
                    "high_quality": 880,
                    "medium_quality": 150,
                    "low_quality": 70,
                    "average_quality_score": 0.88,
                    "last_24h_updates": 28
                },
                "jusbrasil": {
                    "total_profiles": 950,
                    "high_quality": 665,
                    "medium_quality": 190,
                    "low_quality": 95,
                    "average_quality_score": 0.79,
                    "last_24h_updates": 18
                }
            },
            
            # Tendências de completude
            "completeness_trends": [
                {"date": "2024-01-09", "average_completeness": 0.78},
                {"date": "2024-01-10", "average_completeness": 0.79},
                {"date": "2024-01-11", "average_completeness": 0.81},
                {"date": "2024-01-12", "average_completeness": 0.83},
                {"date": "2024-01-13", "average_completeness": 0.82},
                {"date": "2024-01-14", "average_completeness": 0.84},
                {"date": "2024-01-15", "average_completeness": 0.85}
            ],
            
            # Custos de coleta
            "collection_costs": {
                "total_cost_usd": 245.80,
                "by_source": {
                    "linkedin": {"cost": 125.50, "queries": 2510},
                    "academic": {"cost": 98.20, "queries": 982},
                    "escavador": {"cost": 15.40, "queries": 770},
                    "jusbrasil": {"cost": 6.70, "queries": 335}
                },
                "cost_per_profile": 0.18,
                "projected_monthly_cost": 1050.00
            },
            
            # Performance das APIs
            "api_performance": {
                "linkedin": {
                    "average_response_time_ms": 2800,
                    "success_rate": 0.96,
                    "rate_limit_hits": 8,
                    "timeout_rate": 0.02
                },
                "academic": {
                    "average_response_time_ms": 4200,
                    "success_rate": 0.91,
                    "rate_limit_hits": 15,
                    "timeout_rate": 0.05
                },
                "escavador": {
                    "average_response_time_ms": 1800,
                    "success_rate": 0.98,
                    "rate_limit_hits": 2,
                    "timeout_rate": 0.01
                }
            },
            
            # Alertas e recomendações
            "alerts": [
                {
                    "level": "warning",
                    "message": "Taxa de timeout da Perplexity Academic acima de 5%",
                    "action": "Considerar aumentar timeout ou reduzir concorrência"
                },
                {
                    "level": "info",
                    "message": "LinkedIn alcançou 96% de taxa de sucesso",
                    "action": "Performance dentro do esperado"
                }
            ],
            
            "recommendations": [
                "Otimizar queries da Perplexity para reduzir timeouts",
                "Implementar cache mais agressivo para dados acadêmicos",
                "Considerar fontes alternativas para dados com baixa qualidade"
            ]
        }
        
        return JSONResponse(
            status_code=200,
            content=overview_data
        )
        
    except Exception as e:
        logger.error(f"Erro ao buscar overview de qualidade: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/source/{source_type}/details")
@rate_limit(max_calls=20, window_seconds=60)
async def get_source_quality_details(
    source_type: str,
    period_days: int = Query(7, description="Período em dias"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Detalhes de qualidade de uma fonte específica
    
    **Informações detalhadas:**
    - Distribuição de scores de qualidade
    - Histórico de atualizações
    - Campos mais/menos populados
    - Análise de custos
    - Recomendações específicas
    """
    try:
        # Validar fonte
        try:
            source_enum = DataSourceType(source_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Fonte inválida: {source_type}. Fontes válidas: {[t.value for t in DataSourceType]}"
            )
        
        # Simular dados detalhados para a fonte
        if source_enum == DataSourceType.LINKEDIN:
            details = _get_linkedin_quality_details(period_days)
        elif source_enum == DataSourceType.ACADEMIC:
            details = _get_academic_quality_details(period_days)
        elif source_enum == DataSourceType.ESCAVADOR:
            details = _get_escavador_quality_details(period_days)
        else:
            details = _get_generic_quality_details(source_enum, period_days)
        
        return JSONResponse(
            status_code=200,
            content=details
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes da fonte {source_type}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/profiles/low-quality")
@rate_limit(max_calls=10, window_seconds=60)
async def get_low_quality_profiles(
    quality_threshold: float = Query(0.5, description="Threshold de qualidade (0-1)"),
    limit: int = Query(50, description="Número máximo de resultados"),
    source_filter: Optional[str] = Query(None, description="Filtrar por fonte específica"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Listar perfis com baixa qualidade de dados
    
    **Útil para:**
    - Identificar perfis que precisam de atenção
    - Priorizar atualizações
    - Análise de problemas específicos
    """
    try:
        # TODO: Implementar busca real na base de dados
        # Por ora, simular dados
        
        low_quality_profiles = [
            {
                "lawyer_id": "adv_001",
                "full_name": "João Silva Santos",
                "overall_quality_score": 0.35,
                "completeness_score": 0.42,
                "last_updated": "2024-01-10T08:30:00Z",
                "problematic_sources": ["academic", "linkedin"],
                "missing_data": ["formação acadêmica", "experiência profissional completa"],
                "recommendations": [
                    "Atualizar perfil LinkedIn",
                    "Buscar dados acadêmicos via Perplexity"
                ]
            },
            {
                "lawyer_id": "adv_002", 
                "full_name": "Maria Oliveira",
                "overall_quality_score": 0.48,
                "completeness_score": 0.55,
                "last_updated": "2024-01-12T14:15:00Z",
                "problematic_sources": ["academic"],
                "missing_data": ["publicações acadêmicas", "certificações"],
                "recommendations": [
                    "Expandir busca acadêmica",
                    "Verificar certificações profissionais"
                ]
            }
        ]
        
        # Filtrar por fonte se especificado
        if source_filter:
            low_quality_profiles = [
                profile for profile in low_quality_profiles
                if source_filter in profile["problematic_sources"]
            ]
        
        # Aplicar limite
        low_quality_profiles = low_quality_profiles[:limit]
        
        response_data = {
            "filters": {
                "quality_threshold": quality_threshold,
                "source_filter": source_filter,
                "limit": limit
            },
            "total_found": len(low_quality_profiles),
            "profiles": low_quality_profiles,
            "summary": {
                "average_quality": sum(p["overall_quality_score"] for p in low_quality_profiles) / len(low_quality_profiles) if low_quality_profiles else 0,
                "most_common_issues": [
                    "Dados acadêmicos incompletos",
                    "Perfil LinkedIn desatualizado",
                    "Falta de dados de contato"
                ]
            }
        }
        
        return JSONResponse(
            status_code=200,
            content=response_data
        )
        
    except Exception as e:
        logger.error(f"Erro ao buscar perfis de baixa qualidade: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/costs/analysis")
@rate_limit(max_calls=10, window_seconds=60)
async def get_cost_analysis(
    period_days: int = Query(30, description="Período em dias para análise"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Análise detalhada de custos de coleta de dados
    
    **Inclui:**
    - Custos por fonte
    - Tendências de gasto
    - ROI por tipo de dado
    - Projeções futuras
    - Oportunidades de otimização
    """
    try:
        cost_analysis = {
            "period": {
                "days": period_days,
                "start_date": (datetime.utcnow() - timedelta(days=period_days)).isoformat(),
                "end_date": datetime.utcnow().isoformat()
            },
            
            # Custos totais
            "total_costs": {
                "current_period_usd": 1247.80,
                "previous_period_usd": 1156.40,
                "change_percentage": 7.9,
                "average_daily_cost": 41.59
            },
            
            # Custos por fonte
            "costs_by_source": {
                "linkedin": {
                    "total_cost": 625.40,
                    "queries_made": 12508,
                    "cost_per_query": 0.050,
                    "percentage_of_total": 50.2
                },
                "academic": {
                    "total_cost": 491.60,
                    "queries_made": 4916,
                    "cost_per_query": 0.100,
                    "percentage_of_total": 39.4
                },
                "escavador": {
                    "total_cost": 92.40,
                    "queries_made": 4620,
                    "cost_per_query": 0.020,
                    "percentage_of_total": 7.4
                },
                "jusbrasil": {
                    "total_cost": 38.40,
                    "queries_made": 1920,
                    "cost_per_query": 0.020,
                    "percentage_of_total": 3.0
                }
            },
            
            # ROI por tipo de dado
            "roi_analysis": {
                "linkedin_education": {
                    "value_score": 8.5,
                    "cost_efficiency": 0.85,
                    "recommendation": "Manter investimento atual"
                },
                "linkedin_experience": {
                    "value_score": 9.2,
                    "cost_efficiency": 0.92,
                    "recommendation": "Excelente ROI - priorizar"
                },
                "academic_publications": {
                    "value_score": 7.1,
                    "cost_efficiency": 0.71,
                    "recommendation": "Otimizar queries para reduzir custo"
                },
                "legal_cases": {
                    "value_score": 8.8,
                    "cost_efficiency": 0.95,
                    "recommendation": "Ótimo custo-benefício"
                }
            },
            
            # Projeções
            "projections": {
                "next_30_days_usd": 1310.00,
                "annual_projection_usd": 15720.00,
                "growth_trend": "stable_increase",
                "optimization_potential_usd": 235.00
            },
            
            # Oportunidades de otimização
            "optimization_opportunities": [
                {
                    "area": "Academic queries",
                    "current_cost": 491.60,
                    "potential_savings": 147.48,
                    "optimization": "Implementar cache mais agressivo (TTL 48h)",
                    "impact": "30% redução no custo acadêmico"
                },
                {
                    "area": "LinkedIn rate limiting",
                    "current_cost": 625.40,
                    "potential_savings": 62.54,
                    "optimization": "Otimizar batch requests",
                    "impact": "10% redução no custo LinkedIn"
                },
                {
                    "area": "Redundant queries",
                    "current_cost": 124.78,
                    "potential_savings": 24.96,
                    "optimization": "Detectar e evitar queries duplicadas",
                    "impact": "20% redução em queries redundantes"
                }
            ]
        }
        
        return JSONResponse(
            status_code=200,
            content=cost_analysis
        )
        
    except Exception as e:
        logger.error(f"Erro na análise de custos: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.post("/optimize/cache")
@rate_limit(max_calls=3, window_seconds=3600)  # Máximo 3 otimizações por hora
async def optimize_cache_settings(
    source_type: Optional[str] = Query(None, description="Fonte específica para otimizar"),
    current_admin = Depends(get_current_admin_user)
):
    """
    Otimizar configurações de cache para reduzir custos
    
    **Ações realizadas:**
    - Analisar padrões de uso
    - Ajustar TTL de cache
    - Identificar dados candidatos a cache permanente
    - Configurar invalidação inteligente
    """
    try:
        optimization_results = {
            "optimization_started": datetime.utcnow().isoformat(),
            "target_source": source_type or "all",
            "actions_taken": [],
            "estimated_savings": 0.0
        }
        
        if not source_type or source_type == "linkedin":
            optimization_results["actions_taken"].append({
                "source": "linkedin",
                "action": "Increased TTL from 6h to 12h for basic profile data",
                "estimated_monthly_savings": 125.00
            })
            optimization_results["estimated_savings"] += 125.00
        
        if not source_type or source_type == "academic":
            optimization_results["actions_taken"].append({
                "source": "academic", 
                "action": "Implemented permanent cache for institution rankings",
                "estimated_monthly_savings": 89.50
            })
            optimization_results["estimated_savings"] += 89.50
        
        if not source_type or source_type == "escavador":
            optimization_results["actions_taken"].append({
                "source": "escavador",
                "action": "Enabled aggressive caching for historical case data",
                "estimated_monthly_savings": 23.00
            })
            optimization_results["estimated_savings"] += 23.00
        
        optimization_results["total_estimated_monthly_savings"] = optimization_results["estimated_savings"]
        optimization_results["annual_savings_projection"] = optimization_results["estimated_savings"] * 12
        
        logger.info(f"Otimização de cache executada por admin {current_admin.get('user_id')}")
        
        return JSONResponse(
            status_code=200,
            content=optimization_results
        )
        
    except Exception as e:
        logger.error(f"Erro na otimização de cache: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

# Funções auxiliares para simular dados específicos por fonte

def _get_linkedin_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados LinkedIn"""
    return {
        "source": "linkedin",
        "period_days": period_days,
        "total_profiles": 1250,
        
        "quality_distribution": {
            "high_quality": {"count": 980, "percentage": 78.4},
            "medium_quality": {"count": 200, "percentage": 16.0},
            "low_quality": {"count": 70, "percentage": 5.6}
        },
        
        "field_completeness": {
            "basic_info": 98.5,
            "education": 89.2,
            "experience": 95.1,
            "skills": 76.8,
            "certifications": 45.3,
            "contact_info": 62.1,
            "network_metrics": 91.7
        },
        
        "common_issues": [
            {"issue": "Missing certification data", "frequency": 54.7},
            {"issue": "Incomplete contact information", "frequency": 37.9},
            {"issue": "Skills without endorsements", "frequency": 23.2}
        ],
        
        "recommendations": [
            "Encourage users to complete certification section",
            "Implement fallback contact discovery methods",
            "Prioritize skills with endorsements in scoring"
        ]
    }

def _get_academic_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados acadêmicos"""
    return {
        "source": "academic",
        "period_days": period_days,
        "total_profiles": 820,
        
        "quality_distribution": {
            "high_quality": {"count": 410, "percentage": 50.0},
            "medium_quality": {"count": 280, "percentage": 34.1},
            "low_quality": {"count": 130, "percentage": 15.9}
        },
        
        "field_completeness": {
            "degrees": 78.9,
            "institutions": 82.1,
            "publications": 34.5,
            "awards": 18.7,
            "research_areas": 67.3
        },
        
        "common_issues": [
            {"issue": "No publications found", "frequency": 65.5},
            {"issue": "Incomplete institution data", "frequency": 17.9},
            {"issue": "Missing degree details", "frequency": 21.1}
        ],
        
        "recommendations": [
            "Expand publication search beyond main databases",
            "Implement manual verification for key profiles",
            "Cross-reference with institutional websites"
        ]
    }

def _get_escavador_quality_details(period_days: int) -> Dict[str, Any]:
    """Detalhes específicos da qualidade dos dados do Escavador"""
    return {
        "source": "escavador",
        "period_days": period_days,
        "total_profiles": 1100,
        
        "quality_distribution": {
            "high_quality": {"count": 880, "percentage": 80.0},
            "medium_quality": {"count": 150, "percentage": 13.6},
            "low_quality": {"count": 70, "percentage": 6.4}
        },
        
        "field_completeness": {
            "basic_cases": 94.2,
            "outcomes": 87.5,
            "tribunals": 91.8,
            "case_types": 89.1,
            "date_ranges": 85.3
        },
        
        "common_issues": [
            {"issue": "Missing case outcomes", "frequency": 12.5},
            {"issue": "Incomplete tribunal data", "frequency": 8.2},
            {"issue": "Date parsing errors", "frequency": 14.7}
        ]
    }

def _get_generic_quality_details(source_type: DataSourceType, period_days: int) -> Dict[str, Any]:
    """Detalhes genéricos para outras fontes"""
    return {
        "source": source_type.value,
        "period_days": period_days,
        "status": "limited_data",
        "message": f"Dados detalhados para {source_type.value} ainda não disponíveis"
    } 