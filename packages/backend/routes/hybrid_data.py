# -*- coding: utf-8 -*-
"""
Endpoints para Dados Híbridos com Transparência
==============================================

Este módulo fornece endpoints para acessar dados consolidados
de advogados e escritórios com transparência completa sobre
as fontes de dados utilizadas.
"""

from datetime import datetime
from typing import Dict, List, Optional, Any
import json

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from pydantic import BaseModel, Field

from database import get_async_session
from models.lawyer import Lawyer
from models.law_firm import LawFirm
from services.hybrid_legal_data_service import HybridLegalDataService, DataTransparency
from jobs.jusbrasil_sync_hybrid import sync_single_lawyer_task, get_sync_status


router = APIRouter(prefix="/api/v1/hybrid", tags=["Hybrid Data"])


# Schemas de resposta
class DataTransparencyResponse(BaseModel):
    """Schema para transparência de dados."""
    source: str
    last_updated: datetime
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    data_freshness_hours: int
    validation_status: str
    source_url: Optional[str] = None
    api_version: Optional[str] = None


class HybridLawyerResponse(BaseModel):
    """Schema para resposta de advogado híbrido."""
    lawyer_id: str
    oab_number: str
    name: str
    specializations: List[str]
    success_metrics: Dict[str, float]
    reputation_score: float
    cases_won: int
    cases_total: int
    avg_case_duration_days: float
    data_transparency: List[DataTransparencyResponse]
    data_quality: Dict[str, Any]
    last_sync: Optional[datetime] = None


class SyncStatusResponse(BaseModel):
    """Schema para status de sincronização."""
    total_lawyers: int
    synced_lawyers: int
    recently_synced: int
    sync_coverage: float
    avg_confidence: float
    last_check: datetime
    error_count: int = 0


class SyncReportResponse(BaseModel):
    """Schema para relatório de sincronização."""
    entity_type: str
    total_entities: int
    synced_entities: int
    sync_coverage: float
    recently_synced: int
    avg_quality_score: float
    error_count: int


# Dependências
async def get_hybrid_service() -> HybridLegalDataService:
    """Fornece instância do serviço híbrido."""
    service = HybridLegalDataService()
    try:
        yield service
    finally:
        await service.close()


# Endpoints
@router.get("/lawyers/{lawyer_id}", response_model=HybridLawyerResponse)
async def get_lawyer_hybrid_data(
    lawyer_id: str,
    force_refresh: bool = Query(False, description="Forçar atualização dos dados"),
    session: AsyncSession = Depends(get_async_session),
    hybrid_service: HybridLegalDataService = Depends(get_hybrid_service)
):
    """
    Obtém dados consolidados de um advogado com transparência de fontes.
    
    Args:
        lawyer_id: ID do advogado
        force_refresh: Se True, força atualização dos dados
        
    Returns:
        Dados consolidados com transparência
    """
    # Buscar advogado no banco
    result = await session.execute(
        select(Lawyer).where(Lawyer.id == lawyer_id)
    )
    lawyer = result.scalar_one_or_none()
    
    if not lawyer:
        raise HTTPException(status_code=404, detail="Advogado não encontrado")
    
    # Se force_refresh, disparar sincronização
    if force_refresh:
        sync_single_lawyer_task.delay(lawyer_id)
    
    # Buscar dados híbridos
    hybrid_data = await hybrid_service.get_lawyer_data(lawyer_id, lawyer.oab_number)
    
    if not hybrid_data:
        raise HTTPException(
            status_code=404, 
            detail="Dados híbridos não encontrados para este advogado"
        )
    
    # Obter métricas de qualidade
    data_quality = await hybrid_service.get_data_quality_metrics(lawyer_id)
    
    # Converter transparências
    transparency_responses = [
        DataTransparencyResponse(
            source=t.source.value,
            last_updated=t.last_updated,
            confidence_score=t.confidence_score,
            data_freshness_hours=t.data_freshness_hours,
            validation_status=t.validation_status,
            source_url=t.source_url,
            api_version=t.api_version
        )
        for t in hybrid_data.data_transparency
    ]
    
    return HybridLawyerResponse(
        lawyer_id=hybrid_data.lawyer_id,
        oab_number=hybrid_data.oab_number,
        name=hybrid_data.name,
        specializations=hybrid_data.specializations,
        success_metrics=hybrid_data.success_metrics,
        reputation_score=hybrid_data.reputation_score,
        cases_won=hybrid_data.cases_won,
        cases_total=hybrid_data.cases_total,
        avg_case_duration_days=hybrid_data.avg_case_duration_days,
        data_transparency=transparency_responses,
        data_quality=data_quality,
        last_sync=lawyer.data_last_synced
    )


@router.get("/sync/status", response_model=SyncStatusResponse)
async def get_sync_status_endpoint():
    """
    Obtém status atual da sincronização de dados.
    
    Returns:
        Status de sincronização consolidado
    """
    try:
        # Usar task do Celery para obter status
        result = get_sync_status.delay()
        status_data = result.get(timeout=10)
        
        return SyncStatusResponse(**status_data)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter status de sincronização: {str(e)}"
        )


@router.get("/sync/report", response_model=List[SyncReportResponse])
async def get_sync_report(
    session: AsyncSession = Depends(get_async_session)
):
    """
    Obtém relatório detalhado de sincronização por tipo de entidade.
    
    Returns:
        Lista de relatórios por tipo de entidade
    """
    try:
        # Usar função SQL para obter estatísticas
        result = await session.execute(text("SELECT * FROM get_sync_statistics()"))
        stats = result.fetchall()
        
        reports = []
        for stat in stats:
            reports.append(SyncReportResponse(
                entity_type=stat.entity_type,
                total_entities=stat.total_entities,
                synced_entities=stat.synced_entities,
                sync_coverage=float(stat.sync_coverage),
                recently_synced=stat.recently_synced,
                avg_quality_score=float(stat.avg_quality_score),
                error_count=stat.error_count
            ))
        
        return reports
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter relatório de sincronização: {str(e)}"
        )


@router.post("/sync/trigger")
async def trigger_sync(
    lawyer_id: Optional[str] = Query(None, description="ID específico do advogado"),
    force_refresh: bool = Query(False, description="Forçar atualização completa")
):
    """
    Dispara sincronização de dados.
    
    Args:
        lawyer_id: ID específico do advogado (opcional)
        force_refresh: Se True, força atualização completa
        
    Returns:
        Confirmação de disparo
    """
    try:
        if lawyer_id:
            # Sincronizar advogado específico
            task = sync_single_lawyer_task.delay(lawyer_id)
            return {
                "message": f"Sincronização iniciada para advogado {lawyer_id}",
                "task_id": task.id,
                "type": "single_lawyer"
            }
        else:
            # Sincronizar todos os advogados
            from jobs.jusbrasil_sync_hybrid import sync_lawyers_task
            task = sync_lawyers_task.delay(force_refresh)
            return {
                "message": "Sincronização completa iniciada",
                "task_id": task.id,
                "type": "full_sync",
                "force_refresh": force_refresh
            }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao disparar sincronização: {str(e)}"
        )


@router.get("/data-sources")
async def get_available_data_sources():
    """
    Lista fontes de dados disponíveis e suas configurações.
    
    Returns:
        Lista de fontes de dados com metadados
    """
    sources = [
        {
            "name": "jusbrasil",
            "display_name": "JusBrasil",
            "description": "Base de dados jurídica com processos e advogados",
            "confidence_weight": 0.4,
            "cache_ttl_hours": 6,
            "api_version": "v1",
            "status": "active"
        },
        {
            "name": "cnj",
            "display_name": "CNJ",
            "description": "Conselho Nacional de Justiça - dados oficiais",
            "confidence_weight": 0.3,
            "cache_ttl_hours": 24,
            "api_version": "v1",
            "status": "active"
        },
        {
            "name": "oab",
            "display_name": "OAB",
            "description": "Ordem dos Advogados do Brasil - registro oficial",
            "confidence_weight": 0.2,
            "cache_ttl_hours": 12,
            "api_version": "v1",
            "status": "active"
        },
        {
            "name": "internal",
            "display_name": "Base Interna",
            "description": "Dados internos da plataforma",
            "confidence_weight": 0.1,
            "cache_ttl_hours": 2,
            "api_version": "internal",
            "status": "active"
        }
    ]
    
    return {
        "sources": sources,
        "total_sources": len(sources),
        "active_sources": len([s for s in sources if s["status"] == "active"]),
        "last_updated": datetime.now().isoformat()
    }


@router.get("/quality-metrics/{lawyer_id}")
async def get_lawyer_quality_metrics(
    lawyer_id: str,
    session: AsyncSession = Depends(get_async_session)
):
    """
    Obtém métricas detalhadas de qualidade dos dados de um advogado.
    
    Args:
        lawyer_id: ID do advogado
        
    Returns:
        Métricas de qualidade por fonte
    """
    try:
        # Buscar métricas de qualidade do banco
        query = text("""
            SELECT 
                metric_name,
                metric_value,
                source,
                measured_at
            FROM data_quality_metrics
            WHERE entity_type = 'lawyer' AND entity_id = :lawyer_id
            ORDER BY measured_at DESC
        """)
        
        result = await session.execute(query, {"lawyer_id": lawyer_id})
        metrics = result.fetchall()
        
        if not metrics:
            raise HTTPException(
                status_code=404,
                detail="Métricas de qualidade não encontradas para este advogado"
            )
        
        # Agrupar métricas por fonte
        metrics_by_source = {}
        for metric in metrics:
            source = metric.source
            if source not in metrics_by_source:
                metrics_by_source[source] = {}
            
            metrics_by_source[source][metric.metric_name] = {
                "value": float(metric.metric_value),
                "measured_at": metric.measured_at.isoformat()
            }
        
        return {
            "lawyer_id": lawyer_id,
            "metrics_by_source": metrics_by_source,
            "total_sources": len(metrics_by_source),
            "last_updated": max(m.measured_at for m in metrics).isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter métricas de qualidade: {str(e)}"
        )


@router.get("/sync/logs")
async def get_sync_logs(
    entity_type: Optional[str] = Query(None, description="Tipo de entidade (lawyer/law_firm)"),
    entity_id: Optional[str] = Query(None, description="ID da entidade"),
    status: Optional[str] = Query(None, description="Status da sincronização"),
    limit: int = Query(50, description="Limite de resultados"),
    session: AsyncSession = Depends(get_async_session)
):
    """
    Obtém logs de sincronização.
    
    Args:
        entity_type: Filtrar por tipo de entidade
        entity_id: Filtrar por ID específico
        status: Filtrar por status
        limit: Limite de resultados
        
    Returns:
        Lista de logs de sincronização
    """
    try:
        # Construir query dinâmica
        conditions = []
        params = {"limit": limit}
        
        if entity_type:
            conditions.append("entity_type = :entity_type")
            params["entity_type"] = entity_type
        
        if entity_id:
            conditions.append("entity_id = :entity_id")
            params["entity_id"] = entity_id
        
        if status:
            conditions.append("status = :status")
            params["status"] = status
        
        where_clause = " AND ".join(conditions) if conditions else "1=1"
        
        query = text(f"""
            SELECT 
                id,
                entity_type,
                entity_id,
                sync_type,
                status,
                sources_used,
                changes_detected,
                error_message,
                execution_time_ms,
                created_at
            FROM sync_logs
            WHERE {where_clause}
            ORDER BY created_at DESC
            LIMIT :limit
        """)
        
        result = await session.execute(query, params)
        logs = result.fetchall()
        
        # Converter para formato JSON
        logs_data = []
        for log in logs:
            logs_data.append({
                "id": str(log.id),
                "entity_type": log.entity_type,
                "entity_id": str(log.entity_id),
                "sync_type": log.sync_type,
                "status": log.status,
                "sources_used": log.sources_used,
                "changes_detected": log.changes_detected,
                "error_message": log.error_message,
                "execution_time_ms": log.execution_time_ms,
                "created_at": log.created_at.isoformat()
            })
        
        return {
            "logs": logs_data,
            "total_returned": len(logs_data),
            "filters_applied": {
                "entity_type": entity_type,
                "entity_id": entity_id,
                "status": status
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter logs de sincronização: {str(e)}"
        ) 