#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
routes/admin_economy_dashboard.py

API endpoints para dashboard de economia de API - Painel do Administrador.
Apenas para administradores do sistema, não para clientes ou advogados.
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from pydantic import BaseModel

try:
    from config.database import get_database
except ImportError:
    # Fallback para desenvolvimento
    async def get_database():
        import asyncpg
        yield asyncpg.connect("postgresql://user:password@localhost/database")
from services.economy_calculator_service import economy_calculator

# ============================================================================
# CONFIGURAÇÃO DO ROUTER
# ============================================================================

router = APIRouter(
    prefix="/admin/economy",
    tags=["Admin Economy Dashboard"],
    dependencies=[Depends(HTTPBearer())]  # Requer autenticação
)

# ============================================================================
# MODELOS PYDANTIC
# ============================================================================

class EconomyMetrics(BaseModel):
    """Métricas de economia em tempo real."""
    date_recorded: str
    cache_hit_rate: float
    economy_percentage: float
    api_calls_saved: int
    daily_savings: float
    total_requests: int

class OptimizationReport(BaseModel):
    """Relatório de otimização."""
    generated_at: str
    report_type: str
    performance_metrics: Dict[str, Any]
    recommendations: List[str]
    usage_analysis: Dict[str, Any]

class DashboardSummary(BaseModel):
    """Resumo do dashboard."""
    current_economy_rate: float
    monthly_savings: float
    annual_projection: float
    cache_hit_rate: float
    active_processes: int
    last_optimization: Optional[str]

# ============================================================================
# ENDPOINTS PRINCIPAIS
# ============================================================================

@router.get("/dashboard/summary", response_model=DashboardSummary)
async def get_dashboard_summary():
    """
    Retorna resumo executivo do dashboard de economia.
    Apenas para administradores.
    """
    async with get_database() as conn:
        # Buscar métricas mais recentes
        recent_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage,
                daily_savings,
                api_calls_saved,
                total_api_calls
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        
        recent_metrics = await conn.fetchrow(recent_metrics_query)
        
        # Buscar número de processos ativos
        active_processes_query = """
            SELECT COUNT(DISTINCT cnj) as active_count
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '30 days'
        """
        
        active_count_result = await conn.fetchrow(active_processes_query)
        
        # Buscar última otimização
        last_optimization_query = """
            SELECT generated_at
            FROM optimization_reports 
            WHERE report_type = 'daily_optimization'
            ORDER BY generated_at DESC 
            LIMIT 1
        """
        
        last_opt_result = await conn.fetchrow(last_optimization_query)
        
        # Calcular projeções
        current_rate = float(recent_metrics['economy_percentage'] or 0) if recent_metrics else 0
        daily_savings = float(recent_metrics['daily_savings'] or 0) if recent_metrics else 0
        monthly_savings = daily_savings * 30
        annual_projection = monthly_savings * 12
        
        return DashboardSummary(
            current_economy_rate=current_rate,
            monthly_savings=monthly_savings,
            annual_projection=annual_projection,
            cache_hit_rate=float(recent_metrics['cache_hit_rate'] or 0) if recent_metrics else 0,
            active_processes=int(active_count_result['active_count'] or 0) if active_count_result else 0,
            last_optimization=last_opt_result['generated_at'].isoformat() if last_opt_result else None
        )

@router.get("/metrics/historical")
async def get_historical_metrics(days: int = 30):
    """
    Retorna métricas históricas de economia.
    
    Args:
        days: Número de dias para buscar (padrão: 30)
    """
    if days > 365:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 365 dias permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                date_recorded,
                cache_hit_rate,
                economy_percentage,
                api_calls_saved,
                total_api_calls,
                daily_savings,
                avg_response_time_ms,
                offline_uptime_percentage
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '%d days'
            ORDER BY date_recorded ASC
        """ % days
        
        results = await conn.fetch(query)
        
        return {
            "period_days": days,
            "data_points": len(results),
            "metrics": [
                {
                    "date": row['date_recorded'].isoformat(),
                    "cache_hit_rate": float(row['cache_hit_rate'] or 0),
                    "economy_percentage": float(row['economy_percentage'] or 0),
                    "api_calls_saved": int(row['api_calls_saved'] or 0),
                    "total_api_calls": int(row['total_api_calls'] or 0),
                    "daily_savings": float(row['daily_savings'] or 0),
                    "avg_response_time_ms": int(row['avg_response_time_ms'] or 0),
                    "offline_uptime": float(row['offline_uptime_percentage'] or 0)
                }
                for row in results
            ]
        }

@router.get("/optimization/reports")
async def get_optimization_reports(limit: int = 10):
    """
    Retorna relatórios de otimização mais recentes.
    
    Args:
        limit: Número máximo de relatórios (padrão: 10)
    """
    if limit > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 50 relatórios permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                generated_at,
                report_data,
                report_type
            FROM optimization_reports 
            ORDER BY generated_at DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "total_reports": len(results),
            "reports": [
                {
                    "generated_at": row['generated_at'].isoformat(),
                    "report_type": row['report_type'],
                    "data": row['report_data']
                }
                for row in results
            ]
        }

@router.get("/scenarios/comparison")
async def get_economy_scenarios():
    """
    Retorna comparação de cenários de economia.
    Mostra economia para diferentes tamanhos de escritório.
    """
    try:
        # Calcular cenários usando o economy calculator
        scenarios = economy_calculator.compare_scenarios()
        
        return {
            "generated_at": datetime.now().isoformat(),
            "scenarios": scenarios["scenarios"],
            "summary": scenarios["summary"],
            "recommendations": [
                "📊 Escritórios pequenos: ROI em ~3 meses",
                "🚀 Escritórios médios: ROI em ~2 semanas", 
                "🏆 Escritórios grandes: ROI em ~2 dias",
                "💡 Sistema se paga sozinho muito rapidamente"
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular cenários: {str(e)}"
        )

@router.get("/processes/top-consumers")
async def get_top_api_consumers(limit: int = 20):
    """
    Retorna processos que mais consomem API.
    Útil para identificar oportunidades de otimização.
    """
    async with get_database() as conn:
        query = """
            SELECT 
                cnj,
                access_count,
                detected_phase,
                process_area,
                last_accessed_at,
                redis_ttl_seconds,
                db_ttl_seconds,
                access_pattern
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            ORDER BY access_count DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "analysis_period": "7_days",
            "total_processes": len(results),
            "top_consumers": [
                {
                    "cnj": row['cnj'],
                    "access_count": int(row['access_count'] or 0),
                    "detected_phase": row['detected_phase'],
                    "process_area": row['process_area'],
                    "last_accessed": row['last_accessed_at'].isoformat() if row['last_accessed_at'] else None,
                    "current_config": {
                        "redis_ttl_hours": (row['redis_ttl_seconds'] or 3600) / 3600,
                        "db_ttl_hours": (row['db_ttl_seconds'] or 86400) / 3600,
                        "access_pattern": row['access_pattern']
                    }
                }
                for row in results
            ]
        }

@router.get("/cache/performance")
async def get_cache_performance():
    """
    Retorna análise detalhada de performance do cache.
    """
    async with get_database() as conn:
        # Métricas por fonte de dados
        source_metrics_query = """
            SELECT 
                'redis' as source,
                COUNT(*) as hits,
                AVG(EXTRACT(EPOCH FROM (NOW() - last_accessed_at))*1000) as avg_response_ms
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '1 day'
            
            UNION ALL
            
            SELECT 
                'database' as source,
                COUNT(*) as hits,
                200 as avg_response_ms  -- Estimativa
            FROM process_movements 
            WHERE fetched_from_api_at > NOW() - INTERVAL '1 day'
        """
        
        source_results = await conn.fetch(source_metrics_query)
        
        # Cache hit por fase processual
        phase_cache_query = """
            SELECT 
                detected_phase,
                COUNT(*) as processes,
                AVG(access_count) as avg_access_count,
                AVG(redis_ttl_seconds / 3600.0) as avg_redis_ttl_hours
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            GROUP BY detected_phase
            ORDER BY COUNT(*) DESC
        """
        
        phase_results = await conn.fetch(phase_cache_query)
        
        return {
            "cache_sources": [
                {
                    "source": row['source'],
                    "hits": int(row['hits'] or 0),
                    "avg_response_ms": float(row['avg_response_ms'] or 0)
                }
                for row in source_results
            ],
            "performance_by_phase": [
                {
                    "phase": row['detected_phase'] or 'unknown',
                    "processes": int(row['processes'] or 0),
                    "avg_access_count": float(row['avg_access_count'] or 0),
                    "avg_redis_ttl_hours": float(row['avg_redis_ttl_hours'] or 0)
                }
                for row in phase_results
            ]
        }

@router.post("/optimization/trigger")
async def trigger_manual_optimization():
    """
    Dispara otimização manual do sistema.
    Apenas para administradores em casos especiais.
    """
    try:
        # Importar o job de otimização
        from jobs.economic_optimization_job import EconomicOptimizationJob
        
        # Executar otimização única
        job = EconomicOptimizationJob()
        await job.run_daily_optimization()
        
        return {
            "status": "success",
            "message": "Otimização manual executada com sucesso",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao executar otimização manual: {str(e)}"
        )

@router.get("/health/system")
async def get_system_health():
    """
    Retorna saúde geral do sistema de economia.
    """
    async with get_database() as conn:
        # Verificar se o sistema está funcionando
        health_checks = {}
        
        # 1. Verificar se há dados recentes
        recent_data_query = """
            SELECT COUNT(*) as recent_count
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '2 days'
        """
        recent_result = await conn.fetchrow(recent_data_query)
        health_checks["recent_data"] = int(recent_result['recent_count'] or 0) > 0
        
        # 2. Verificar se há processos sendo otimizados
        active_optimization_query = """
            SELECT COUNT(*) as active_count
            FROM process_optimization_config 
            WHERE updated_at > NOW() - INTERVAL '1 day'
        """
        active_result = await conn.fetchrow(active_optimization_query)
        health_checks["active_optimization"] = int(active_result['active_count'] or 0) > 0
        
        # 3. Verificar últimas métricas
        last_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        metrics_result = await conn.fetchrow(last_metrics_query)
        
        if metrics_result:
            hit_rate = float(metrics_result['cache_hit_rate'] or 0)
            economy_rate = float(metrics_result['economy_percentage'] or 0)
            health_checks["cache_performance"] = hit_rate > 90
            health_checks["economy_target"] = economy_rate > 90
        else:
            health_checks["cache_performance"] = False
            health_checks["economy_target"] = False
        
        # Calcular saúde geral
        health_score = sum(health_checks.values()) / len(health_checks) * 100
        
        status = "healthy" if health_score >= 75 else "warning" if health_score >= 50 else "critical"
        
        return {
            "overall_health": status,
            "health_score": health_score,
            "checks": health_checks,
            "last_check": datetime.now().isoformat(),
            "recommendations": _get_health_recommendations(health_checks)
        }

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

def _get_health_recommendations(health_checks: Dict[str, bool]) -> List[str]:
    """Gera recomendações baseadas na saúde do sistema."""
    recommendations = []
    
    if not health_checks.get("recent_data"):
        recommendations.append("⚠️ Verificar job de coleta de métricas")
    
    if not health_checks.get("active_optimization"):
        recommendations.append("🔧 Verificar job de otimização automática")
    
    if not health_checks.get("cache_performance"):
        recommendations.append("📈 Cache hit rate baixo - revisar TTLs")
    
    if not health_checks.get("economy_target"):
        recommendations.append("💰 Meta de economia não atingida - analisar configurações")
    
    if not recommendations:
        recommendations.append("✅ Sistema funcionando perfeitamente")
    
    return recommendations 
# -*- coding: utf-8 -*-
"""
routes/admin_economy_dashboard.py

API endpoints para dashboard de economia de API - Painel do Administrador.
Apenas para administradores do sistema, não para clientes ou advogados.
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from pydantic import BaseModel

try:
    from config.database import get_database
except ImportError:
    # Fallback para desenvolvimento
    async def get_database():
        import asyncpg
        yield asyncpg.connect("postgresql://user:password@localhost/database")
from services.economy_calculator_service import economy_calculator

# ============================================================================
# CONFIGURAÇÃO DO ROUTER
# ============================================================================

router = APIRouter(
    prefix="/admin/economy",
    tags=["Admin Economy Dashboard"],
    dependencies=[Depends(HTTPBearer())]  # Requer autenticação
)

# ============================================================================
# MODELOS PYDANTIC
# ============================================================================

class EconomyMetrics(BaseModel):
    """Métricas de economia em tempo real."""
    date_recorded: str
    cache_hit_rate: float
    economy_percentage: float
    api_calls_saved: int
    daily_savings: float
    total_requests: int

class OptimizationReport(BaseModel):
    """Relatório de otimização."""
    generated_at: str
    report_type: str
    performance_metrics: Dict[str, Any]
    recommendations: List[str]
    usage_analysis: Dict[str, Any]

class DashboardSummary(BaseModel):
    """Resumo do dashboard."""
    current_economy_rate: float
    monthly_savings: float
    annual_projection: float
    cache_hit_rate: float
    active_processes: int
    last_optimization: Optional[str]

# ============================================================================
# ENDPOINTS PRINCIPAIS
# ============================================================================

@router.get("/dashboard/summary", response_model=DashboardSummary)
async def get_dashboard_summary():
    """
    Retorna resumo executivo do dashboard de economia.
    Apenas para administradores.
    """
    async with get_database() as conn:
        # Buscar métricas mais recentes
        recent_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage,
                daily_savings,
                api_calls_saved,
                total_api_calls
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        
        recent_metrics = await conn.fetchrow(recent_metrics_query)
        
        # Buscar número de processos ativos
        active_processes_query = """
            SELECT COUNT(DISTINCT cnj) as active_count
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '30 days'
        """
        
        active_count_result = await conn.fetchrow(active_processes_query)
        
        # Buscar última otimização
        last_optimization_query = """
            SELECT generated_at
            FROM optimization_reports 
            WHERE report_type = 'daily_optimization'
            ORDER BY generated_at DESC 
            LIMIT 1
        """
        
        last_opt_result = await conn.fetchrow(last_optimization_query)
        
        # Calcular projeções
        current_rate = float(recent_metrics['economy_percentage'] or 0) if recent_metrics else 0
        daily_savings = float(recent_metrics['daily_savings'] or 0) if recent_metrics else 0
        monthly_savings = daily_savings * 30
        annual_projection = monthly_savings * 12
        
        return DashboardSummary(
            current_economy_rate=current_rate,
            monthly_savings=monthly_savings,
            annual_projection=annual_projection,
            cache_hit_rate=float(recent_metrics['cache_hit_rate'] or 0) if recent_metrics else 0,
            active_processes=int(active_count_result['active_count'] or 0) if active_count_result else 0,
            last_optimization=last_opt_result['generated_at'].isoformat() if last_opt_result else None
        )

@router.get("/metrics/historical")
async def get_historical_metrics(days: int = 30):
    """
    Retorna métricas históricas de economia.
    
    Args:
        days: Número de dias para buscar (padrão: 30)
    """
    if days > 365:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 365 dias permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                date_recorded,
                cache_hit_rate,
                economy_percentage,
                api_calls_saved,
                total_api_calls,
                daily_savings,
                avg_response_time_ms,
                offline_uptime_percentage
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '%d days'
            ORDER BY date_recorded ASC
        """ % days
        
        results = await conn.fetch(query)
        
        return {
            "period_days": days,
            "data_points": len(results),
            "metrics": [
                {
                    "date": row['date_recorded'].isoformat(),
                    "cache_hit_rate": float(row['cache_hit_rate'] or 0),
                    "economy_percentage": float(row['economy_percentage'] or 0),
                    "api_calls_saved": int(row['api_calls_saved'] or 0),
                    "total_api_calls": int(row['total_api_calls'] or 0),
                    "daily_savings": float(row['daily_savings'] or 0),
                    "avg_response_time_ms": int(row['avg_response_time_ms'] or 0),
                    "offline_uptime": float(row['offline_uptime_percentage'] or 0)
                }
                for row in results
            ]
        }

@router.get("/optimization/reports")
async def get_optimization_reports(limit: int = 10):
    """
    Retorna relatórios de otimização mais recentes.
    
    Args:
        limit: Número máximo de relatórios (padrão: 10)
    """
    if limit > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 50 relatórios permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                generated_at,
                report_data,
                report_type
            FROM optimization_reports 
            ORDER BY generated_at DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "total_reports": len(results),
            "reports": [
                {
                    "generated_at": row['generated_at'].isoformat(),
                    "report_type": row['report_type'],
                    "data": row['report_data']
                }
                for row in results
            ]
        }

@router.get("/scenarios/comparison")
async def get_economy_scenarios():
    """
    Retorna comparação de cenários de economia.
    Mostra economia para diferentes tamanhos de escritório.
    """
    try:
        # Calcular cenários usando o economy calculator
        scenarios = economy_calculator.compare_scenarios()
        
        return {
            "generated_at": datetime.now().isoformat(),
            "scenarios": scenarios["scenarios"],
            "summary": scenarios["summary"],
            "recommendations": [
                "📊 Escritórios pequenos: ROI em ~3 meses",
                "🚀 Escritórios médios: ROI em ~2 semanas", 
                "🏆 Escritórios grandes: ROI em ~2 dias",
                "💡 Sistema se paga sozinho muito rapidamente"
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular cenários: {str(e)}"
        )

@router.get("/processes/top-consumers")
async def get_top_api_consumers(limit: int = 20):
    """
    Retorna processos que mais consomem API.
    Útil para identificar oportunidades de otimização.
    """
    async with get_database() as conn:
        query = """
            SELECT 
                cnj,
                access_count,
                detected_phase,
                process_area,
                last_accessed_at,
                redis_ttl_seconds,
                db_ttl_seconds,
                access_pattern
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            ORDER BY access_count DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "analysis_period": "7_days",
            "total_processes": len(results),
            "top_consumers": [
                {
                    "cnj": row['cnj'],
                    "access_count": int(row['access_count'] or 0),
                    "detected_phase": row['detected_phase'],
                    "process_area": row['process_area'],
                    "last_accessed": row['last_accessed_at'].isoformat() if row['last_accessed_at'] else None,
                    "current_config": {
                        "redis_ttl_hours": (row['redis_ttl_seconds'] or 3600) / 3600,
                        "db_ttl_hours": (row['db_ttl_seconds'] or 86400) / 3600,
                        "access_pattern": row['access_pattern']
                    }
                }
                for row in results
            ]
        }

@router.get("/cache/performance")
async def get_cache_performance():
    """
    Retorna análise detalhada de performance do cache.
    """
    async with get_database() as conn:
        # Métricas por fonte de dados
        source_metrics_query = """
            SELECT 
                'redis' as source,
                COUNT(*) as hits,
                AVG(EXTRACT(EPOCH FROM (NOW() - last_accessed_at))*1000) as avg_response_ms
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '1 day'
            
            UNION ALL
            
            SELECT 
                'database' as source,
                COUNT(*) as hits,
                200 as avg_response_ms  -- Estimativa
            FROM process_movements 
            WHERE fetched_from_api_at > NOW() - INTERVAL '1 day'
        """
        
        source_results = await conn.fetch(source_metrics_query)
        
        # Cache hit por fase processual
        phase_cache_query = """
            SELECT 
                detected_phase,
                COUNT(*) as processes,
                AVG(access_count) as avg_access_count,
                AVG(redis_ttl_seconds / 3600.0) as avg_redis_ttl_hours
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            GROUP BY detected_phase
            ORDER BY COUNT(*) DESC
        """
        
        phase_results = await conn.fetch(phase_cache_query)
        
        return {
            "cache_sources": [
                {
                    "source": row['source'],
                    "hits": int(row['hits'] or 0),
                    "avg_response_ms": float(row['avg_response_ms'] or 0)
                }
                for row in source_results
            ],
            "performance_by_phase": [
                {
                    "phase": row['detected_phase'] or 'unknown',
                    "processes": int(row['processes'] or 0),
                    "avg_access_count": float(row['avg_access_count'] or 0),
                    "avg_redis_ttl_hours": float(row['avg_redis_ttl_hours'] or 0)
                }
                for row in phase_results
            ]
        }

@router.post("/optimization/trigger")
async def trigger_manual_optimization():
    """
    Dispara otimização manual do sistema.
    Apenas para administradores em casos especiais.
    """
    try:
        # Importar o job de otimização
        from jobs.economic_optimization_job import EconomicOptimizationJob
        
        # Executar otimização única
        job = EconomicOptimizationJob()
        await job.run_daily_optimization()
        
        return {
            "status": "success",
            "message": "Otimização manual executada com sucesso",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao executar otimização manual: {str(e)}"
        )

@router.get("/health/system")
async def get_system_health():
    """
    Retorna saúde geral do sistema de economia.
    """
    async with get_database() as conn:
        # Verificar se o sistema está funcionando
        health_checks = {}
        
        # 1. Verificar se há dados recentes
        recent_data_query = """
            SELECT COUNT(*) as recent_count
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '2 days'
        """
        recent_result = await conn.fetchrow(recent_data_query)
        health_checks["recent_data"] = int(recent_result['recent_count'] or 0) > 0
        
        # 2. Verificar se há processos sendo otimizados
        active_optimization_query = """
            SELECT COUNT(*) as active_count
            FROM process_optimization_config 
            WHERE updated_at > NOW() - INTERVAL '1 day'
        """
        active_result = await conn.fetchrow(active_optimization_query)
        health_checks["active_optimization"] = int(active_result['active_count'] or 0) > 0
        
        # 3. Verificar últimas métricas
        last_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        metrics_result = await conn.fetchrow(last_metrics_query)
        
        if metrics_result:
            hit_rate = float(metrics_result['cache_hit_rate'] or 0)
            economy_rate = float(metrics_result['economy_percentage'] or 0)
            health_checks["cache_performance"] = hit_rate > 90
            health_checks["economy_target"] = economy_rate > 90
        else:
            health_checks["cache_performance"] = False
            health_checks["economy_target"] = False
        
        # Calcular saúde geral
        health_score = sum(health_checks.values()) / len(health_checks) * 100
        
        status = "healthy" if health_score >= 75 else "warning" if health_score >= 50 else "critical"
        
        return {
            "overall_health": status,
            "health_score": health_score,
            "checks": health_checks,
            "last_check": datetime.now().isoformat(),
            "recommendations": _get_health_recommendations(health_checks)
        }

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

def _get_health_recommendations(health_checks: Dict[str, bool]) -> List[str]:
    """Gera recomendações baseadas na saúde do sistema."""
    recommendations = []
    
    if not health_checks.get("recent_data"):
        recommendations.append("⚠️ Verificar job de coleta de métricas")
    
    if not health_checks.get("active_optimization"):
        recommendations.append("🔧 Verificar job de otimização automática")
    
    if not health_checks.get("cache_performance"):
        recommendations.append("📈 Cache hit rate baixo - revisar TTLs")
    
    if not health_checks.get("economy_target"):
        recommendations.append("💰 Meta de economia não atingida - analisar configurações")
    
    if not recommendations:
        recommendations.append("✅ Sistema funcionando perfeitamente")
    
    return recommendations 
# -*- coding: utf-8 -*-
"""
routes/admin_economy_dashboard.py

API endpoints para dashboard de economia de API - Painel do Administrador.
Apenas para administradores do sistema, não para clientes ou advogados.
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from pydantic import BaseModel

try:
    from config.database import get_database
except ImportError:
    # Fallback para desenvolvimento
    async def get_database():
        import asyncpg
        yield asyncpg.connect("postgresql://user:password@localhost/database")
from services.economy_calculator_service import economy_calculator

# ============================================================================
# CONFIGURAÇÃO DO ROUTER
# ============================================================================

router = APIRouter(
    prefix="/admin/economy",
    tags=["Admin Economy Dashboard"],
    dependencies=[Depends(HTTPBearer())]  # Requer autenticação
)

# ============================================================================
# MODELOS PYDANTIC
# ============================================================================

class EconomyMetrics(BaseModel):
    """Métricas de economia em tempo real."""
    date_recorded: str
    cache_hit_rate: float
    economy_percentage: float
    api_calls_saved: int
    daily_savings: float
    total_requests: int

class OptimizationReport(BaseModel):
    """Relatório de otimização."""
    generated_at: str
    report_type: str
    performance_metrics: Dict[str, Any]
    recommendations: List[str]
    usage_analysis: Dict[str, Any]

class DashboardSummary(BaseModel):
    """Resumo do dashboard."""
    current_economy_rate: float
    monthly_savings: float
    annual_projection: float
    cache_hit_rate: float
    active_processes: int
    last_optimization: Optional[str]

# ============================================================================
# ENDPOINTS PRINCIPAIS
# ============================================================================

@router.get("/dashboard/summary", response_model=DashboardSummary)
async def get_dashboard_summary():
    """
    Retorna resumo executivo do dashboard de economia.
    Apenas para administradores.
    """
    async with get_database() as conn:
        # Buscar métricas mais recentes
        recent_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage,
                daily_savings,
                api_calls_saved,
                total_api_calls
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        
        recent_metrics = await conn.fetchrow(recent_metrics_query)
        
        # Buscar número de processos ativos
        active_processes_query = """
            SELECT COUNT(DISTINCT cnj) as active_count
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '30 days'
        """
        
        active_count_result = await conn.fetchrow(active_processes_query)
        
        # Buscar última otimização
        last_optimization_query = """
            SELECT generated_at
            FROM optimization_reports 
            WHERE report_type = 'daily_optimization'
            ORDER BY generated_at DESC 
            LIMIT 1
        """
        
        last_opt_result = await conn.fetchrow(last_optimization_query)
        
        # Calcular projeções
        current_rate = float(recent_metrics['economy_percentage'] or 0) if recent_metrics else 0
        daily_savings = float(recent_metrics['daily_savings'] or 0) if recent_metrics else 0
        monthly_savings = daily_savings * 30
        annual_projection = monthly_savings * 12
        
        return DashboardSummary(
            current_economy_rate=current_rate,
            monthly_savings=monthly_savings,
            annual_projection=annual_projection,
            cache_hit_rate=float(recent_metrics['cache_hit_rate'] or 0) if recent_metrics else 0,
            active_processes=int(active_count_result['active_count'] or 0) if active_count_result else 0,
            last_optimization=last_opt_result['generated_at'].isoformat() if last_opt_result else None
        )

@router.get("/metrics/historical")
async def get_historical_metrics(days: int = 30):
    """
    Retorna métricas históricas de economia.
    
    Args:
        days: Número de dias para buscar (padrão: 30)
    """
    if days > 365:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 365 dias permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                date_recorded,
                cache_hit_rate,
                economy_percentage,
                api_calls_saved,
                total_api_calls,
                daily_savings,
                avg_response_time_ms,
                offline_uptime_percentage
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '%d days'
            ORDER BY date_recorded ASC
        """ % days
        
        results = await conn.fetch(query)
        
        return {
            "period_days": days,
            "data_points": len(results),
            "metrics": [
                {
                    "date": row['date_recorded'].isoformat(),
                    "cache_hit_rate": float(row['cache_hit_rate'] or 0),
                    "economy_percentage": float(row['economy_percentage'] or 0),
                    "api_calls_saved": int(row['api_calls_saved'] or 0),
                    "total_api_calls": int(row['total_api_calls'] or 0),
                    "daily_savings": float(row['daily_savings'] or 0),
                    "avg_response_time_ms": int(row['avg_response_time_ms'] or 0),
                    "offline_uptime": float(row['offline_uptime_percentage'] or 0)
                }
                for row in results
            ]
        }

@router.get("/optimization/reports")
async def get_optimization_reports(limit: int = 10):
    """
    Retorna relatórios de otimização mais recentes.
    
    Args:
        limit: Número máximo de relatórios (padrão: 10)
    """
    if limit > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Máximo de 50 relatórios permitido"
        )
    
    async with get_database() as conn:
        query = """
            SELECT 
                generated_at,
                report_data,
                report_type
            FROM optimization_reports 
            ORDER BY generated_at DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "total_reports": len(results),
            "reports": [
                {
                    "generated_at": row['generated_at'].isoformat(),
                    "report_type": row['report_type'],
                    "data": row['report_data']
                }
                for row in results
            ]
        }

@router.get("/scenarios/comparison")
async def get_economy_scenarios():
    """
    Retorna comparação de cenários de economia.
    Mostra economia para diferentes tamanhos de escritório.
    """
    try:
        # Calcular cenários usando o economy calculator
        scenarios = economy_calculator.compare_scenarios()
        
        return {
            "generated_at": datetime.now().isoformat(),
            "scenarios": scenarios["scenarios"],
            "summary": scenarios["summary"],
            "recommendations": [
                "📊 Escritórios pequenos: ROI em ~3 meses",
                "🚀 Escritórios médios: ROI em ~2 semanas", 
                "🏆 Escritórios grandes: ROI em ~2 dias",
                "💡 Sistema se paga sozinho muito rapidamente"
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular cenários: {str(e)}"
        )

@router.get("/processes/top-consumers")
async def get_top_api_consumers(limit: int = 20):
    """
    Retorna processos que mais consomem API.
    Útil para identificar oportunidades de otimização.
    """
    async with get_database() as conn:
        query = """
            SELECT 
                cnj,
                access_count,
                detected_phase,
                process_area,
                last_accessed_at,
                redis_ttl_seconds,
                db_ttl_seconds,
                access_pattern
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            ORDER BY access_count DESC 
            LIMIT $1
        """
        
        results = await conn.fetch(query, limit)
        
        return {
            "analysis_period": "7_days",
            "total_processes": len(results),
            "top_consumers": [
                {
                    "cnj": row['cnj'],
                    "access_count": int(row['access_count'] or 0),
                    "detected_phase": row['detected_phase'],
                    "process_area": row['process_area'],
                    "last_accessed": row['last_accessed_at'].isoformat() if row['last_accessed_at'] else None,
                    "current_config": {
                        "redis_ttl_hours": (row['redis_ttl_seconds'] or 3600) / 3600,
                        "db_ttl_hours": (row['db_ttl_seconds'] or 86400) / 3600,
                        "access_pattern": row['access_pattern']
                    }
                }
                for row in results
            ]
        }

@router.get("/cache/performance")
async def get_cache_performance():
    """
    Retorna análise detalhada de performance do cache.
    """
    async with get_database() as conn:
        # Métricas por fonte de dados
        source_metrics_query = """
            SELECT 
                'redis' as source,
                COUNT(*) as hits,
                AVG(EXTRACT(EPOCH FROM (NOW() - last_accessed_at))*1000) as avg_response_ms
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '1 day'
            
            UNION ALL
            
            SELECT 
                'database' as source,
                COUNT(*) as hits,
                200 as avg_response_ms  -- Estimativa
            FROM process_movements 
            WHERE fetched_from_api_at > NOW() - INTERVAL '1 day'
        """
        
        source_results = await conn.fetch(source_metrics_query)
        
        # Cache hit por fase processual
        phase_cache_query = """
            SELECT 
                detected_phase,
                COUNT(*) as processes,
                AVG(access_count) as avg_access_count,
                AVG(redis_ttl_seconds / 3600.0) as avg_redis_ttl_hours
            FROM process_optimization_config 
            WHERE last_accessed_at > NOW() - INTERVAL '7 days'
            GROUP BY detected_phase
            ORDER BY COUNT(*) DESC
        """
        
        phase_results = await conn.fetch(phase_cache_query)
        
        return {
            "cache_sources": [
                {
                    "source": row['source'],
                    "hits": int(row['hits'] or 0),
                    "avg_response_ms": float(row['avg_response_ms'] or 0)
                }
                for row in source_results
            ],
            "performance_by_phase": [
                {
                    "phase": row['detected_phase'] or 'unknown',
                    "processes": int(row['processes'] or 0),
                    "avg_access_count": float(row['avg_access_count'] or 0),
                    "avg_redis_ttl_hours": float(row['avg_redis_ttl_hours'] or 0)
                }
                for row in phase_results
            ]
        }

@router.post("/optimization/trigger")
async def trigger_manual_optimization():
    """
    Dispara otimização manual do sistema.
    Apenas para administradores em casos especiais.
    """
    try:
        # Importar o job de otimização
        from jobs.economic_optimization_job import EconomicOptimizationJob
        
        # Executar otimização única
        job = EconomicOptimizationJob()
        await job.run_daily_optimization()
        
        return {
            "status": "success",
            "message": "Otimização manual executada com sucesso",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao executar otimização manual: {str(e)}"
        )

@router.get("/health/system")
async def get_system_health():
    """
    Retorna saúde geral do sistema de economia.
    """
    async with get_database() as conn:
        # Verificar se o sistema está funcionando
        health_checks = {}
        
        # 1. Verificar se há dados recentes
        recent_data_query = """
            SELECT COUNT(*) as recent_count
            FROM api_economy_metrics 
            WHERE date_recorded > NOW() - INTERVAL '2 days'
        """
        recent_result = await conn.fetchrow(recent_data_query)
        health_checks["recent_data"] = int(recent_result['recent_count'] or 0) > 0
        
        # 2. Verificar se há processos sendo otimizados
        active_optimization_query = """
            SELECT COUNT(*) as active_count
            FROM process_optimization_config 
            WHERE updated_at > NOW() - INTERVAL '1 day'
        """
        active_result = await conn.fetchrow(active_optimization_query)
        health_checks["active_optimization"] = int(active_result['active_count'] or 0) > 0
        
        # 3. Verificar últimas métricas
        last_metrics_query = """
            SELECT 
                cache_hit_rate,
                economy_percentage
            FROM api_economy_metrics 
            ORDER BY date_recorded DESC 
            LIMIT 1
        """
        metrics_result = await conn.fetchrow(last_metrics_query)
        
        if metrics_result:
            hit_rate = float(metrics_result['cache_hit_rate'] or 0)
            economy_rate = float(metrics_result['economy_percentage'] or 0)
            health_checks["cache_performance"] = hit_rate > 90
            health_checks["economy_target"] = economy_rate > 90
        else:
            health_checks["cache_performance"] = False
            health_checks["economy_target"] = False
        
        # Calcular saúde geral
        health_score = sum(health_checks.values()) / len(health_checks) * 100
        
        status = "healthy" if health_score >= 75 else "warning" if health_score >= 50 else "critical"
        
        return {
            "overall_health": status,
            "health_score": health_score,
            "checks": health_checks,
            "last_check": datetime.now().isoformat(),
            "recommendations": _get_health_recommendations(health_checks)
        }

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

def _get_health_recommendations(health_checks: Dict[str, bool]) -> List[str]:
    """Gera recomendações baseadas na saúde do sistema."""
    recommendations = []
    
    if not health_checks.get("recent_data"):
        recommendations.append("⚠️ Verificar job de coleta de métricas")
    
    if not health_checks.get("active_optimization"):
        recommendations.append("🔧 Verificar job de otimização automática")
    
    if not health_checks.get("cache_performance"):
        recommendations.append("📈 Cache hit rate baixo - revisar TTLs")
    
    if not health_checks.get("economy_target"):
        recommendations.append("💰 Meta de economia não atingida - analisar configurações")
    
    if not recommendations:
        recommendations.append("✅ Sistema funcionando perfeitamente")
    
    return recommendations 