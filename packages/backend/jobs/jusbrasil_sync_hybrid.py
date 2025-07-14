# -*- coding: utf-8 -*-
"""
Job de Sincronização Híbrida - Escavador, Unipile, JusBrasil e outras fontes
===========================================================================

Este job sincroniza dados de advogados de múltiplas fontes legais
de forma automatizada, mantendo a base de dados atualizada com
informações consolidadas e transparentes.

Fontes suportadas (ordem de prioridade):
- Escavador (peso 0.30) - Primeira posição
- Unipile (peso 0.20) - Dados de comunicação/email
- JusBrasil (peso 0.25)
- CNJ (peso 0.15)
- OAB (peso 0.07)
- Sistema interno (peso 0.03)

Execução:
- Programado via Celery para execução periódica
- Processamento em lotes para otimização
- Retry automático em caso de falhas
- Logs detalhados para auditoria
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import json

from celery import Celery
from celery.schedules import crontab

try:
    from sqlalchemy.ext.asyncio import AsyncSession
    from sqlalchemy import select, update, text
    from sqlalchemy.orm import selectinload
except ImportError:
    # Fallback para desenvolvimento
    pass

try:
    from backend.database import get_async_session
    from backend.models.lawyer import Lawyer
    from backend.models.law_firm import LawFirm
    from backend.services.hybrid_legal_data_service import HybridLegalDataService, DataSource
    from backend.services.notification_service import NotificationService
except ImportError:
    # Mock para desenvolvimento
    class MockService:
        async def close(self):
            pass
    
    HybridLegalDataService = MockService
    NotificationService = MockService


# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurar Celery
celery_app = Celery('jusbrasil_sync_hybrid')
celery_app.config_from_object('backend.celery_config')


class JusBrasilSyncHybridJob:
    """Job de sincronização híbrida de dados legais."""
    
    def __init__(self):
        self.hybrid_service = HybridLegalDataService()
        self.notification_service = NotificationService()
        self.batch_size = 50
        self.max_retries = 3
        
    async def sync_all_lawyers(self, force_refresh: bool = False) -> Dict[str, Any]:
        """
        Sincroniza todos os advogados da base de dados.
        
        Args:
            force_refresh: Se True, ignora cache e força atualização
            
        Returns:
            Relatório de sincronização
        """
        start_time = datetime.now()
        report = {
            "started_at": start_time.isoformat(),
            "total_lawyers": 0,
            "processed": 0,
            "updated": 0,
            "errors": 0,
            "skipped": 0,
            "sources_used": {},
            "execution_time_minutes": 0,
            "error_details": []
        }
        
        try:
            # Buscar advogados que precisam de atualização
            lawyers_to_sync = await self._get_lawyers_to_sync(force_refresh)
            report["total_lawyers"] = len(lawyers_to_sync)
            
            logger.info(f"Iniciando sincronização de {len(lawyers_to_sync)} advogados")
            
            # Processar em lotes
            for i in range(0, len(lawyers_to_sync), self.batch_size):
                batch = lawyers_to_sync[i:i + self.batch_size]
                batch_report = await self._process_batch(batch)
                
                # Consolidar relatório
                report["processed"] += batch_report["processed"]
                report["updated"] += batch_report["updated"]
                report["errors"] += batch_report["errors"]
                report["skipped"] += batch_report["skipped"]
                report["error_details"].extend(batch_report["error_details"])
                
                # Consolidar fontes usadas
                for source, count in batch_report["sources_used"].items():
                    report["sources_used"][source] = report["sources_used"].get(source, 0) + count
                
                logger.info(f"Lote {i//self.batch_size + 1} processado: {batch_report}")
                
                # Pequena pausa entre lotes para não sobrecarregar APIs
                await asyncio.sleep(2)
            
            # Calcular tempo total
            end_time = datetime.now()
            report["execution_time_minutes"] = (end_time - start_time).total_seconds() / 60
            report["completed_at"] = end_time.isoformat()
            
            # Enviar notificação de conclusão
            await self._send_completion_notification(report)
            
            logger.info(f"Sincronização concluída: {report}")
            
        except Exception as e:
            report["fatal_error"] = str(e)
            logger.error(f"Erro fatal na sincronização: {e}")
            await self._send_error_notification(str(e))
        
        return report
    
    async def _get_lawyers_to_sync(self, force_refresh: bool = False) -> List[Lawyer]:
        """Obtém lista de advogados que precisam de sincronização."""
        async with get_async_session() as session:
            query = select(Lawyer).options(selectinload(Lawyer.firm))
            
            if not force_refresh:
                # Sincronizar apenas advogados não atualizados nas últimas 24h
                cutoff_time = datetime.now() - timedelta(hours=24)
                query = query.where(
                    (Lawyer.data_last_synced.is_(None)) |
                    (Lawyer.data_last_synced < cutoff_time)
                )
            
            result = await session.execute(query)
            return result.scalars().all()
    
    async def _process_batch(self, lawyers: List[Lawyer]) -> Dict[str, Any]:
        """Processa um lote de advogados."""
        batch_report = {
            "processed": 0,
            "updated": 0,
            "errors": 0,
            "skipped": 0,
            "sources_used": {},
            "error_details": []
        }
        
        for lawyer in lawyers:
            try:
                result = await self._sync_single_lawyer(lawyer)
                batch_report["processed"] += 1
                
                if result["updated"]:
                    batch_report["updated"] += 1
                    
                    # Contar fontes usadas
                    for source in result["sources_used"]:
                        batch_report["sources_used"][source] = batch_report["sources_used"].get(source, 0) + 1
                else:
                    batch_report["skipped"] += 1
                    
            except Exception as e:
                batch_report["errors"] += 1
                batch_report["error_details"].append({
                    "lawyer_id": lawyer.id,
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                })
                logger.error(f"Erro ao sincronizar advogado {lawyer.id}: {e}")
        
        return batch_report
    
    async def _sync_single_lawyer(self, lawyer: Lawyer) -> Dict[str, Any]:
        """Sincroniza um único advogado."""
        result = {
            "updated": False,
            "sources_used": [],
            "data_quality": {},
            "changes": []
        }
        
        # Buscar dados híbridos
        hybrid_data = await self.hybrid_service.get_lawyer_data(lawyer.id, lawyer.oab_number)
        
        if not hybrid_data:
            logger.warning(f"Nenhum dado encontrado para advogado {lawyer.id}")
            return result
        
        # Verificar se houve mudanças significativas
        changes = self._detect_changes(lawyer, hybrid_data)
        
        if changes:
            # Atualizar dados do advogado
            await self._update_lawyer_data(lawyer, hybrid_data, changes)
            result["updated"] = True
            result["changes"] = changes
        
        # Registrar fontes usadas
        result["sources_used"] = [t.source.value for t in hybrid_data.data_transparency]
        
        # Métricas de qualidade
        result["data_quality"] = await self.hybrid_service.get_data_quality_metrics(lawyer.id)
        
        return result
    
    def _detect_changes(self, lawyer: Lawyer, hybrid_data) -> List[Dict[str, Any]]:
        """Detecta mudanças significativas nos dados."""
        changes = []
        
        # Verificar nome
        if lawyer.name != hybrid_data.name and hybrid_data.name:
            changes.append({
                "field": "name",
                "old_value": lawyer.name,
                "new_value": hybrid_data.name
            })
        
        # Verificar especializações
        current_specs = set(lawyer.specializations or [])
        new_specs = set(hybrid_data.specializations)
        if current_specs != new_specs:
            changes.append({
                "field": "specializations",
                "old_value": list(current_specs),
                "new_value": list(new_specs)
            })
        
        # Verificar métricas de sucesso
        if abs(lawyer.success_rate - hybrid_data.success_metrics.get("success_rate", 0)) > 0.05:
            changes.append({
                "field": "success_rate",
                "old_value": lawyer.success_rate,
                "new_value": hybrid_data.success_metrics.get("success_rate", 0)
            })
        
        # Verificar reputação
        if abs(lawyer.reputation_score - hybrid_data.reputation_score) > 0.1:
            changes.append({
                "field": "reputation_score",
                "old_value": lawyer.reputation_score,
                "new_value": hybrid_data.reputation_score
            })
        
        return changes
    
    async def _update_lawyer_data(self, lawyer: Lawyer, hybrid_data, changes: List[Dict]):
        """Atualiza dados do advogado no banco."""
        async with get_async_session() as session:
            # Preparar dados de atualização
            update_data = {
                "data_last_synced": datetime.now(),
                "data_transparency": json.dumps([t.to_dict() for t in hybrid_data.data_transparency]),
                "updated_at": datetime.now()
            }
            
            # Aplicar mudanças
            for change in changes:
                field = change["field"]
                new_value = change["new_value"]
                
                if field == "name":
                    update_data["name"] = new_value
                elif field == "specializations":
                    update_data["specializations"] = new_value
                elif field == "success_rate":
                    update_data["success_rate"] = new_value
                elif field == "reputation_score":
                    update_data["reputation_score"] = new_value
            
            # Executar atualização
            await session.execute(
                update(Lawyer).where(Lawyer.id == lawyer.id).values(**update_data)
            )
            await session.commit()
            
            logger.info(f"Advogado {lawyer.id} atualizado com {len(changes)} mudanças")
    
    async def _send_completion_notification(self, report: Dict[str, Any]):
        """Envia notificação de conclusão."""
        try:
            message = f"""
            🔄 Sincronização Híbrida Concluída
            
            📊 Resumo:
            • Total de advogados: {report['total_lawyers']}
            • Processados: {report['processed']}
            • Atualizados: {report['updated']}
            • Erros: {report['errors']}
            • Tempo: {report['execution_time_minutes']:.1f} min
            
            🔗 Fontes utilizadas:
            {json.dumps(report['sources_used'], indent=2)}
            """
            
            await self.notification_service.send_admin_notification(
                title="Sincronização Híbrida Concluída",
                message=message,
                priority="info"
            )
        except Exception as e:
            logger.error(f"Erro ao enviar notificação: {e}")
    
    async def _send_error_notification(self, error_message: str):
        """Envia notificação de erro."""
        try:
            await self.notification_service.send_admin_notification(
                title="Erro na Sincronização Híbrida",
                message=f"❌ Erro fatal: {error_message}",
                priority="critical"
            )
        except Exception as e:
            logger.error(f"Erro ao enviar notificação de erro: {e}")
    
    async def close(self):
        """Fecha conexões."""
        await self.hybrid_service.close()


# Tasks do Celery
@celery_app.task(bind=True, max_retries=3)
def sync_lawyers_task(self, force_refresh: bool = False):
    """Task do Celery para sincronização de advogados."""
    
    async def run_sync():
        job = JusBrasilSyncHybridJob()
        try:
            return await job.sync_all_lawyers(force_refresh)
        finally:
            await job.close()
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        return loop.run_until_complete(run_sync())
    except Exception as e:
        logger.error(f"Erro na task de sincronização: {e}")
        raise self.retry(exc=e, countdown=60 * (self.request.retries + 1))


@celery_app.task
def sync_single_lawyer_task(lawyer_id: str):
    """Task para sincronizar um único advogado."""
    
    async def run_single_sync():
        job = JusBrasilSyncHybridJob()
        try:
            async with get_async_session() as session:
                result = await session.execute(
                    select(Lawyer).where(Lawyer.id == lawyer_id)
                )
                lawyer = result.scalar_one_or_none()
                
                if lawyer:
                    return await job._sync_single_lawyer(lawyer)
                else:
                    return {"error": "Advogado não encontrado"}
        finally:
            await job.close()
    
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    return loop.run_until_complete(run_single_sync())


@celery_app.task
def get_sync_status():
    """Task para obter status da sincronização."""
    
    async def get_status():
        async with get_async_session() as session:
            # Estatísticas de sincronização
            stats_query = text("""
                SELECT 
                    COUNT(*) as total_lawyers,
                    COUNT(CASE WHEN data_last_synced IS NOT NULL THEN 1 END) as synced_lawyers,
                    COUNT(CASE WHEN data_last_synced > NOW() - INTERVAL '24 hours' THEN 1 END) as recently_synced,
                    AVG(CASE WHEN data_transparency IS NOT NULL THEN 
                        (data_transparency::json->0->>'confidence_score')::float 
                        ELSE 0 END) as avg_confidence
                FROM lawyers
            """)
            
            result = await session.execute(stats_query)
            stats = result.fetchone()
            
            return {
                "total_lawyers": stats.total_lawyers,
                "synced_lawyers": stats.synced_lawyers,
                "recently_synced": stats.recently_synced,
                "sync_coverage": (stats.synced_lawyers / stats.total_lawyers * 100) if stats.total_lawyers > 0 else 0,
                "avg_confidence": round(stats.avg_confidence or 0, 3),
                "last_check": datetime.now().isoformat()
            }
    
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    return loop.run_until_complete(get_status())


# Configuração de agendamento
@celery_app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """Configura tasks periódicas."""
    
    # Sincronização completa diária às 2:00 AM
    sender.add_periodic_task(
        crontab(hour=2, minute=0),
        sync_lawyers_task.s(force_refresh=False),
        name='sync_lawyers_daily'
    )
    
    # Sincronização incremental a cada 6 horas
    sender.add_periodic_task(
        crontab(minute=0, hour='*/6'),
        sync_lawyers_task.s(force_refresh=False),
        name='sync_lawyers_incremental'
    )
    
    # Status check a cada hora
    sender.add_periodic_task(
        crontab(minute=0),
        get_sync_status.s(),
        name='sync_status_check'
    )


if __name__ == "__main__":
    # Teste local
    async def test_sync():
        job = JusBrasilSyncHybridJob()
        try:
            report = await job.sync_all_lawyers(force_refresh=False)
            print(f"Relatório de sincronização: {json.dumps(report, indent=2)}")
        finally:
            await job.close()
    
    asyncio.run(test_sync()) 