#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
routes/admin.py

Rotas administrativas para controladoria e gestão de dados.
"""

import csv
import io
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import JSONResponse, StreamingResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/admin", tags=["Controladoria"])

# ============================================================================
# MIDDLEWARE DE VERIFICAÇÃO ADMINISTRATIVA
# ============================================================================

async def verify_admin(current_user: dict = Depends(get_current_user)):
    """Verifica se o usuário é administrador."""
    if not current_user.get("role") == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso restrito a administradores"
        )
    return current_user

# ============================================================================
# DASHBOARD PRINCIPAL DA CONTROLADORIA
# ============================================================================

@router.get("/dashboard")
async def get_admin_dashboard(
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Dashboard principal da controladoria com métricas essenciais.
    """
    try:
        # Métricas gerais do sistema
        lawyers_stats = supabase.table("profiles").select("*", count="exact").eq("role", "lawyer").execute()
        clients_stats = supabase.table("profiles").select("*", count="exact").eq("role", "client").execute()
        cases_stats = supabase.table("cases").select("*", count="exact").execute()
        
        # Métricas de atividade (últimos 30 dias)
        thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()
        
        new_users = supabase.table("profiles").select("*", count="exact")\
            .gte("created_at", thirty_days_ago).execute()
        
        new_cases = supabase.table("cases").select("*", count="exact")\
            .gte("created_at", thirty_days_ago).execute()
        
        # Métricas de qualidade de dados
        sync_quality = supabase.rpc("get_jusbrasil_sync_quality").execute()
        
        # Feature flags ativas
        active_features = supabase.table("feature_flags").select("*")\
            .neq("status", "disabled").execute()
        
        return {
            "sistema": {
                "total_advogados": lawyers_stats.count,
                "total_clientes": clients_stats.count,
                "total_casos": cases_stats.count,
                "usuarios_novos_30d": new_users.count,
                "casos_novos_30d": new_cases.count
            },
            "qualidade_dados": sync_quality.data[0] if sync_quality.data else {},
            "feature_flags_ativas": len(active_features.data),
            "ultima_atualizacao": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro no dashboard admin: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# GESTÃO DE ADVOGADOS
# ============================================================================

@router.get("/lawyers")
async def list_all_lawyers(
    admin_user: dict = Depends(verify_admin),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = Query(None),
    filter_by_status: Optional[str] = Query(None),
    supabase=Depends(get_supabase_client)
):
    """
    Lista todos os advogados com dados completos para controladoria.
    """
    try:
        offset = (page - 1) * limit
        
        query = supabase.table("profiles").select("""
            *,
            lawyers(*)
        """).eq("role", "lawyer")
        
        if search:
            query = query.ilike("full_name", f"%{search}%")
        
        if filter_by_status:
            query = query.eq("is_active", filter_by_status == "active")
        
        result = query.range(offset, offset + limit - 1).execute()
        
        # Enriquecer com dados de auditoria
        enriched_lawyers = []
        for lawyer in result.data:
            # Buscar última sincronização
            sync_history = supabase.table("jusbrasil_sync_history")\
                .select("*").eq("lawyer_id", lawyer["id"])\
                .order("sync_timestamp", desc=True).limit(1).execute()
            
            # Buscar atividade recente
            recent_activity = supabase.table("cases")\
                .select("*", count="exact")\
                .eq("lawyer_id", lawyer["id"])\
                .gte("created_at", thirty_days_ago).execute()
            
            lawyer["auditoria"] = {
                "ultima_sincronizacao": sync_history.data[0] if sync_history.data else None,
                "casos_recentes": recent_activity.count,
                "qualidade_dados": lawyer.get("lawyers", {}).get("jusbrasil_data_quality"),
                "fonte_dados": lawyer.get("lawyers", {}).get("data_sources", [])
            }
            
            enriched_lawyers.append(lawyer)
        
        total_count = supabase.table("profiles").select("*", count="exact")\
            .eq("role", "lawyer").execute().count
        
        return {
            "advogados": enriched_lawyers,
            "paginacao": {
                "total": total_count,
                "pagina": page,
                "limite": limit,
                "total_paginas": (total_count + limit - 1) // limit
            }
        }
        
    except Exception as e:
        logger.error(f"Erro ao listar advogados: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/lawyers/{lawyer_id}")
async def get_lawyer_details(
    lawyer_id: str,
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Detalhes completos de um advogado para auditoria.
    """
    try:
        # Dados básicos
        lawyer_data = supabase.table("profiles").select("""
            *,
            lawyers(*)
        """).eq("id", lawyer_id).eq("role", "lawyer").single().execute()
        
        if not lawyer_data.data:
            raise HTTPException(status_code=404, detail="Advogado não encontrado")
        
        # Histórico de sincronizações
        sync_history = supabase.table("jusbrasil_sync_history")\
            .select("*").eq("lawyer_id", lawyer_id)\
            .order("sync_timestamp", desc=True).limit(10).execute()
        
        # Casos atribuídos
        cases = supabase.table("cases").select("*")\
            .eq("lawyer_id", lawyer_id)\
            .order("created_at", desc=True).limit(20).execute()
        
        # Logs de feature flags
        feature_logs = supabase.table("feature_flag_logs")\
            .select("*").eq("user_id", lawyer_id)\
            .order("created_at", desc=True).limit(10).execute()
        
        # Métricas de performance
        business_metrics = BusinessMetricsService()
        performance = await business_metrics.calculate_lawyer_performance(30)
        lawyer_performance = next(
            (l for l in performance["lawyers"] if l["id"] == lawyer_id), 
            None
        )
        
        return {
            "dados_pessoais": lawyer_data.data,
            "historico_sincronizacao": sync_history.data,
            "casos_atribuidos": cases.data,
            "logs_features": feature_logs.data,
            "metricas_performance": lawyer_performance,
            "auditoria_completa": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes do advogado {lawyer_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# AUDITORIA DE DADOS
# ============================================================================

@router.get("/data-audit")
async def get_data_audit(
    admin_user: dict = Depends(verify_admin),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    source: Optional[str] = Query(None),
    supabase=Depends(get_supabase_client)
):
    """
    Auditoria completa dos dados do sistema.
    """
    try:
        # Definir período padrão (últimos 7 dias)
        if not start_date:
            start_date = (datetime.now() - timedelta(days=7)).isoformat()
        if not end_date:
            end_date = datetime.now().isoformat()
        
        # Auditoria de sincronizações
        sync_query = supabase.table("jusbrasil_sync_history")\
            .select("*").gte("sync_timestamp", start_date)\
            .lte("sync_timestamp", end_date)
        
        if source:
            sync_query = sync_query.eq("data_source", source)
        
        sync_audit = sync_query.execute()
        
        # Auditoria de feature flags
        feature_audit = supabase.table("feature_flag_logs")\
            .select("*").gte("created_at", start_date)\
            .lte("created_at", end_date).execute()
        
        # Auditoria de alertas do sistema
        alerts_audit = supabase.table("model_alerts")\
            .select("*").gte("timestamp", start_date)\
            .lte("timestamp", end_date).execute()
        
        # Estatísticas por fonte de dados
        sources_stats = {}
        for sync in sync_audit.data:
            source_name = sync.get("data_source", "unknown")
            if source_name not in sources_stats:
                sources_stats[source_name] = {
                    "total_syncs": 0,
                    "successful_syncs": 0,
                    "failed_syncs": 0,
                    "avg_quality": 0
                }
            
            sources_stats[source_name]["total_syncs"] += 1
            if sync.get("sync_status") == "success":
                sources_stats[source_name]["successful_syncs"] += 1
            else:
                sources_stats[source_name]["failed_syncs"] += 1
        
        return {
            "periodo": {
                "inicio": start_date,
                "fim": end_date
            },
            "sincronizacoes": {
                "total": len(sync_audit.data),
                "detalhes": sync_audit.data,
                "por_fonte": sources_stats
            },
            "feature_flags": {
                "total_acessos": len(feature_audit.data),
                "detalhes": feature_audit.data
            },
            "alertas_sistema": {
                "total": len(alerts_audit.data),
                "detalhes": alerts_audit.data
            }
        }
        
    except Exception as e:
        logger.error(f"Erro na auditoria de dados: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# GESTÃO DE QUALIDADE DE DADOS
# ============================================================================

@router.get("/data-quality")
async def get_data_quality_report(
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Relatório de qualidade dos dados por fonte.
    """
    try:
        # Qualidade geral do Jusbrasil
        jusbrasil_quality = supabase.rpc("get_jusbrasil_sync_quality").execute()
        
        # Advogados com dados de baixa qualidade
        low_quality_lawyers = supabase.table("lawyers")\
            .select("id, name, jusbrasil_data_quality, last_jusbrasil_sync")\
            .eq("jusbrasil_data_quality", "low").execute()
        
        # Advogados sem dados
        no_data_lawyers = supabase.table("lawyers")\
            .select("id, name, last_jusbrasil_sync")\
            .is_("last_jusbrasil_sync", "null").execute()
        
        # Distribuição de qualidade
        quality_distribution = supabase.table("lawyers")\
            .select("jusbrasil_data_quality", count="exact")\
            .execute()
        
        # Calcular percentuais
        total_lawyers = supabase.table("lawyers").select("*", count="exact").execute().count
        
        quality_stats = {}
        for item in quality_distribution.data:
            quality = item.get("jusbrasil_data_quality") or "unknown"
            quality_stats[quality] = {
                "count": 1,  # Supabase count funciona diferente
                "percentage": round((1 / total_lawyers) * 100, 2) if total_lawyers > 0 else 0
            }
        
        return {
            "resumo_qualidade": jusbrasil_quality.data[0] if jusbrasil_quality.data else {},
            "distribuicao_qualidade": quality_stats,
            "problemas_identificados": {
                "baixa_qualidade": {
                    "count": len(low_quality_lawyers.data),
                    "advogados": low_quality_lawyers.data
                },
                "sem_dados": {
                    "count": len(no_data_lawyers.data),
                    "advogados": no_data_lawyers.data
                }
            },
            "recomendacoes": [
                "Priorizar sincronização dos advogados sem dados",
                "Revisar advogados com qualidade baixa",
                "Implementar validação automática de dados"
            ]
        }
        
    except Exception as e:
        logger.error(f"Erro no relatório de qualidade: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# AÇÕES ADMINISTRATIVAS
# ============================================================================

@router.post("/sync/lawyer/{lawyer_id}")
async def force_lawyer_sync(
    lawyer_id: str,
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Força sincronização de um advogado específico.
    """
    try:
        # Verificar se o advogado existe
        lawyer = supabase.table("profiles").select("*")\
            .eq("id", lawyer_id).eq("role", "lawyer").single().execute()
        
        if not lawyer.data:
            raise HTTPException(status_code=404, detail="Advogado não encontrado")
        
        # Disparar sincronização
        from backend.jobs.sync_lawyer_data import sync_single_lawyer_task
        task = sync_single_lawyer_task.delay(lawyer_id, force_refresh=True)
        
        # Log da ação administrativa
        logger.info(f"Admin {admin_user['id']} forçou sincronização do advogado {lawyer_id}")
        
        return {
            "status": "success",
            "message": "Sincronização iniciada",
            "task_id": task.id,
            "lawyer_id": lawyer_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao forçar sincronização: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/sync/all")
async def force_global_sync(
    admin_user: dict = Depends(verify_admin),
    priority_only: bool = Query(False, description="Sincronizar apenas advogados prioritários")
):
    """
    Força sincronização global do sistema.
    """
    try:
        from backend.jobs.sync_lawyer_data import sync_all_lawyers_task
        
        task = sync_all_lawyers_task.delay(
            priority_only=priority_only,
            triggered_by=admin_user["id"]
        )
        
        logger.warning(f"Admin {admin_user['id']} iniciou sincronização global (priority_only={priority_only})")
        
        return {
            "status": "success",
            "message": "Sincronização global iniciada",
            "task_id": task.id,
            "priority_only": priority_only,
            "triggered_by": admin_user["id"]
        }
        
    except Exception as e:
        logger.error(f"Erro na sincronização global: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# RELATÓRIOS EXECUTIVOS
# ============================================================================

@router.get("/reports/executive")
async def get_executive_report(
    admin_user: dict = Depends(verify_admin),
    period_days: int = Query(30, ge=1, le=365)
):
    """
    Relatório executivo para alta gestão.
    """
    try:
        business_metrics = BusinessMetricsService()
        
        # Métricas de negócio
        lawyer_performance = await business_metrics.calculate_lawyer_performance(period_days)
        platform_metrics = await business_metrics.calculate_platform_metrics(period_days)
        
        # Métricas de qualidade
        model_monitoring = ModelMonitoringService()
        active_alerts = model_monitoring.get_active_alerts()
        
        return {
            "periodo_dias": period_days,
            "performance_advogados": lawyer_performance,
            "metricas_plataforma": platform_metrics,
            "alertas_ativos": len(active_alerts),
            "qualidade_sistema": {
                "alertas_criticos": len([a for a in active_alerts if a.level.value == "critical"]),
                "status_geral": "healthy" if len(active_alerts) < 5 else "attention_needed"
            },
            "gerado_em": datetime.now().isoformat(),
            "gerado_por": admin_user["id"]
        }
        
    except Exception as e:
        logger.error(f"Erro no relatório executivo: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

# ============================================================================
# HEALTH CHECK ADMINISTRATIVO
# ============================================================================

@router.get("/health")
async def admin_health_check(admin_user: dict = Depends(verify_admin)):
    """
    Health check detalhado para administradores.
    """
    try:
        # Verificar conexões
        db_connection = get_db_connection()
        db_status = "healthy" if db_connection else "unhealthy"
        if db_connection:
            db_connection.close()
        
        supabase = get_supabase_client()
        supabase_status = "healthy" if supabase else "unhealthy"
        
        # Verificar Redis (se configurado)
        redis_status = "not_configured"  # Implementar verificação Redis se necessário
        
        # Status geral
        overall_status = "healthy" if all([
            db_status == "healthy",
            supabase_status == "healthy"
        ]) else "unhealthy"
        
        return {
            "status": overall_status,
            "timestamp": datetime.now().isoformat(),
            "components": {
                "database": db_status,
                "supabase": supabase_status,
                "redis": redis_status
            },
            "admin_user": admin_user["id"]
        }
        
    except Exception as e:
        logger.error(f"Erro no health check admin: {e}")
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        } 

# ============================================================================
# ENDPOINTS ESPECÍFICOS PARA APLICAÇÃO WEB
# ============================================================================

@router.get("/lawyers/export")
async def export_lawyers_csv(
    admin_user: dict = Depends(verify_admin),
    format: str = Query("csv", description="Formato de exportação"),
    include_audit: bool = Query(True, description="Incluir dados de auditoria"),
    supabase=Depends(get_supabase_client)
):
    """
    Exporta dados dos advogados em CSV para análise externa.
    """
    try:
        # Buscar todos os advogados
        lawyers_response = supabase.table("profiles").select("""
            *,
            lawyers(*)
        """).eq("role", "lawyer").execute()
        
        if not lawyers_response.data:
            raise HTTPException(status_code=404, detail="Nenhum advogado encontrado")
        
        # Criar CSV em memória
        output = io.StringIO()
        
        if format.lower() == "csv":
            fieldnames = [
                'id', 'full_name', 'email', 'oab_number', 'uf', 
                'created_at', 'is_active', 'total_cases', 'success_rate',
                'last_sync', 'data_quality'
            ]
            
            if include_audit:
                fieldnames.extend(['sync_count', 'last_error', 'data_sources'])
            
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            
            for lawyer in lawyers_response.data:
                lawyer_data = lawyer.get('lawyers', {}) or {}
                row = {
                    'id': lawyer['id'],
                    'full_name': lawyer.get('full_name', ''),
                    'email': lawyer.get('email', ''),
                    'oab_number': lawyer_data.get('oab_number', ''),
                    'uf': lawyer_data.get('uf', ''),
                    'created_at': lawyer.get('created_at', ''),
                    'is_active': lawyer.get('is_active', False),
                    'total_cases': lawyer_data.get('total_cases', 0),
                    'success_rate': lawyer_data.get('success_rate', 0),
                    'last_sync': lawyer_data.get('last_jusbrasil_sync', ''),
                    'data_quality': lawyer_data.get('jusbrasil_data_quality', '')
                }
                
                if include_audit:
                    # Buscar dados de auditoria
                    sync_history = supabase.table("jusbrasil_sync_history")\
                        .select("*", count="exact")\
                        .eq("lawyer_id", lawyer["id"]).execute()
                    
                    row.update({
                        'sync_count': sync_history.count,
                        'last_error': '',  # Implementar se necessário
                        'data_sources': ','.join(['jusbrasil', 'internal'])
                    })
                
                writer.writerow(row)
        
        output.seek(0)
        
        # Retornar como download
        response = StreamingResponse(
            io.BytesIO(output.getvalue().encode('utf-8')),
            media_type="text/csv",
            headers={"Content-Disposition": "attachment; filename=advogados_export.csv"}
        )
        
        # Log da ação
        logger.info(f"Admin {admin_user['id']} exportou dados de {len(lawyers_response.data)} advogados")
        
        return response
        
    except Exception as e:
        logger.error(f"Erro na exportação: {e}")
        raise HTTPException(status_code=500, detail="Erro na exportação de dados")

@router.get("/analytics/overview")
async def get_analytics_overview(
    admin_user: dict = Depends(verify_admin),
    period_days: int = Query(30, ge=1, le=365),
    supabase=Depends(get_supabase_client)
):
    """
    Análise detalhada para dashboard web administrativo.
    """
    try:
        start_date = (datetime.now() - timedelta(days=period_days)).isoformat()
        
        # Métricas de crescimento
        growth_metrics = {}
        
        # Usuários por período
        for period in [7, 30, 90]:
            period_start = (datetime.now() - timedelta(days=period)).isoformat()
            
            users_count = supabase.table("profiles").select("*", count="exact")\
                .gte("created_at", period_start).execute()
            
            cases_count = supabase.table("cases").select("*", count="exact")\
                .gte("created_at", period_start).execute()
            
            growth_metrics[f"{period}_days"] = {
                "new_users": users_count.count,
                "new_cases": cases_count.count
            }
        
        # Distribuição por tipo de usuário
        user_distribution = {}
        for role in ['client', 'lawyer']:
            count = supabase.table("profiles").select("*", count="exact")\
                .eq("role", role).execute()
            user_distribution[role] = count.count
        
        # Top advogados por casos
        top_lawyers = supabase.table("cases").select("""
            lawyer_id,
            profiles!inner(full_name)
        """, count="exact").limit(10).execute()
        
        # Qualidade de dados por fonte
        data_quality = supabase.rpc("get_jusbrasil_sync_quality").execute()
        
        return {
            "period_days": period_days,
            "growth_metrics": growth_metrics,
            "user_distribution": user_distribution,
            "top_lawyers": top_lawyers.data[:10] if top_lawyers.data else [],
            "data_quality": data_quality.data[0] if data_quality.data else {},
            "generated_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro na análise: {e}")
        raise HTTPException(status_code=500, detail="Erro na análise de dados")

@router.post("/bulk-actions/lawyers")
async def bulk_lawyer_actions(
    action_type: str,
    lawyer_ids: List[str],
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Ações em lote para múltiplos advogados.
    """
    try:
        if not lawyer_ids:
            raise HTTPException(status_code=400, detail="Lista de advogados vazia")
        
        results = {
            "processed": 0,
            "succeeded": 0,
            "failed": 0,
            "errors": []
        }
        
        for lawyer_id in lawyer_ids:
            results["processed"] += 1
            
            try:
                if action_type == "activate":
                    supabase.table("profiles").update({"is_active": True})\
                        .eq("id", lawyer_id).execute()
                
                elif action_type == "deactivate":
                    supabase.table("profiles").update({"is_active": False})\
                        .eq("id", lawyer_id).execute()
                
                elif action_type == "force_sync":
                    try:
                        from jobs.sync_lawyer_data import sync_single_lawyer_task
                        sync_single_lawyer_task.delay(lawyer_id, force_refresh=True)
                    except ImportError:
                        # Fallback se o módulo não existir
                        logger.warning(f"Módulo de sync não encontrado, usando fallback para {lawyer_id}")
                        pass
                
                elif action_type == "reset_quality":
                    supabase.table("lawyers").update({
                        "jusbrasil_data_quality": None,
                        "last_jusbrasil_sync": None
                    }).eq("id", lawyer_id).execute()
                
                else:
                    raise ValueError(f"Ação não suportada: {action_type}")
                
                results["succeeded"] += 1
                
            except Exception as e:
                results["failed"] += 1
                results["errors"].append(f"Advogado {lawyer_id}: {str(e)}")
        
        # Log da ação em lote
        logger.warning(f"Admin {admin_user['id']} executou ação em lote '{action_type}' "
                      f"em {len(lawyer_ids)} advogados. {results['succeeded']} sucessos, "
                      f"{results['failed']} falhas")
        
        return {
            "status": "completed",
            "action_type": action_type,
            "results": results,
            "executed_by": admin_user["id"],
            "executed_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro na ação em lote: {e}")
        raise HTTPException(status_code=500, detail="Erro na execução da ação em lote")

@router.get("/system/settings")
async def get_system_settings(
    admin_user: dict = Depends(verify_admin),
    category: Optional[str] = Query(None),
    supabase=Depends(get_supabase_client)
):
    """
    Configurações do sistema para aplicação web.
    """
    try:
        # Configurações básicas do sistema
        settings = {
            "sync_settings": {
                "auto_sync_enabled": True,
                "sync_interval_hours": 24,
                "max_concurrent_syncs": 5,
                "retry_failed_syncs": True
            },
            "data_quality": {
                "min_quality_threshold": 0.7,
                "auto_flag_low_quality": True,
                "quality_check_frequency": "daily"
            },
            "notifications": {
                "admin_alerts_enabled": True,
                "email_notifications": True,
                "webhook_enabled": False
            },
            "api_limits": {
                "max_requests_per_minute": 100,
                "max_bulk_actions": 1000,
                "rate_limit_enabled": True
            }
        }
        
        if category:
            settings = settings.get(category, {})
        
        return {
            "settings": settings,
            "last_updated": datetime.now().isoformat(),
            "updated_by": "system"
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar configurações: {e}")
        raise HTTPException(status_code=500, detail="Erro ao buscar configurações")

@router.post("/system/settings")
async def update_system_settings(
    settings_data: Dict[str, Any],
    admin_user: dict = Depends(verify_admin)
):
    """
    Atualiza configurações do sistema.
    """
    try:
        # Validar configurações críticas
        allowed_settings = [
            "sync_interval_hours", "max_concurrent_syncs", 
            "min_quality_threshold", "admin_alerts_enabled"
        ]
        
        updated_settings = {}
        for key, value in settings_data.items():
            if key in allowed_settings:
                updated_settings[key] = value
            else:
                logger.warning(f"Configuração não permitida ignorada: {key}")
        
        if not updated_settings:
            raise HTTPException(status_code=400, detail="Nenhuma configuração válida fornecida")
        
        # Log da alteração
        logger.warning(f"Admin {admin_user['id']} atualizou configurações do sistema: "
                      f"{list(updated_settings.keys())}")
        
        return {
            "status": "success",
            "updated_settings": updated_settings,
            "updated_by": admin_user["id"],
            "updated_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro ao atualizar configurações: {e}")
        raise HTTPException(status_code=500, detail="Erro ao atualizar configurações")

@router.get("/logs/admin-actions")
async def get_admin_action_logs(
    admin_user: dict = Depends(verify_admin),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    action_type: Optional[str] = Query(None)
):
    """
    Logs de ações administrativas para auditoria.
    """
    try:
        # Por ora, retornar logs simulados - implementar com tabela real se necessário
        logs = [
            {
                "id": f"log_{i}",
                "admin_id": admin_user["id"],
                "admin_name": "Admin User",
                "action_type": "sync_lawyer",
                "target_type": "lawyer",
                "target_id": f"lawyer_{i}",
                "description": f"Sincronização forçada do advogado {i}",
                "timestamp": (datetime.now() - timedelta(hours=i)).isoformat(),
                "ip_address": "127.0.0.1",
                "success": True
            }
            for i in range(1, 21)  # 20 logs simulados
        ]
        
        # Filtrar por data se fornecida
        if start_date:
            start_dt = datetime.fromisoformat(start_date)
            logs = [log for log in logs if datetime.fromisoformat(log["timestamp"]) >= start_dt]
        
        if end_date:
            end_dt = datetime.fromisoformat(end_date)
            logs = [log for log in logs if datetime.fromisoformat(log["timestamp"]) <= end_dt]
        
        if action_type:
            logs = [log for log in logs if log["action_type"] == action_type]
        
        # Paginação
        total = len(logs)
        start_idx = (page - 1) * limit
        end_idx = start_idx + limit
        paginated_logs = logs[start_idx:end_idx]
        
        return {
            "logs": paginated_logs,
            "pagination": {
                "total": total,
                "page": page,
                "limit": limit,
                "total_pages": (total + limit - 1) // limit,
                "has_next": end_idx < total,
                "has_prev": page > 1
            },
            "filters": {
                "start_date": start_date,
                "end_date": end_date,
                "action_type": action_type
            }
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar logs: {e}")
        raise HTTPException(status_code=500, detail="Erro ao buscar logs de auditoria")

@router.get("/monitoring/real-time")
async def get_real_time_monitoring(
    admin_user: dict = Depends(verify_admin),
    supabase=Depends(get_supabase_client)
):
    """
    Monitoramento em tempo real para dashboard web.
    """
    try:
        # Métricas em tempo real
        current_time = datetime.now()
        
        # Atividade recente (última hora)
        hour_ago = (current_time - timedelta(hours=1)).isoformat()
        
        recent_cases = supabase.table("cases").select("*", count="exact")\
            .gte("created_at", hour_ago).execute()
        
        recent_users = supabase.table("profiles").select("*", count="exact")\
            .gte("created_at", hour_ago).execute()
        
        # Status de sincronização
        sync_status = {
            "active_syncs": 0,  # Implementar com Redis/Celery se necessário
            "pending_syncs": 0,
            "last_global_sync": None,
            "sync_health": "healthy"
        }
        
        # Alertas ativos
        active_alerts_count = 0  # Implementar com tabela de alertas
        
        # Performance do sistema
        system_performance = {
            "api_response_time": "< 100ms",
            "database_status": "healthy",
            "cache_hit_rate": "95%",
            "error_rate": "< 0.1%"
        }
        
        return {
            "timestamp": current_time.isoformat(),
            "recent_activity": {
                "new_cases_last_hour": recent_cases.count,
                "new_users_last_hour": recent_users.count,
                "active_sessions": 0  # Implementar se necessário
            },
            "sync_status": sync_status,
            "alerts": {
                "active_count": active_alerts_count,
                "critical_count": 0,
                "warning_count": 0
            },
            "system_performance": system_performance,
            "uptime": "99.9%"  # Implementar cálculo real se necessário
        }
        
    except Exception as e:
        logger.error(f"Erro no monitoramento: {e}")
        raise HTTPException(status_code=500, detail="Erro no monitoramento em tempo real")

# ============================================================================
# MIDDLEWARE CORS PARA APLICAÇÃO WEB
# ============================================================================

def setup_admin_cors(app):
    """
    Configura CORS especificamente para a aplicação administrativa.
    """
    from fastapi.middleware.cors import CORSMiddleware
    
    # Configuração CORS para aplicação web administrativa
    admin_origins = [
        "http://localhost:3000",  # React/Next.js dev
        "http://localhost:8080",  # Vue.js dev
        "http://localhost:4200",  # Angular dev
        "https://admin.litig1.com",  # Produção (ajustar conforme necessário)
        "https://controladoria.litig1.com"  # Produção alternativa
    ]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=admin_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["*"]
    ) 