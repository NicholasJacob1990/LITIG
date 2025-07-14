#!/usr/bin/env python3
"""
Job para envio de notificações semanais de performance para prestadores.
Executa toda segunda-feira às 9:00 AM.
"""

import asyncio
import logging
from datetime import datetime

from celery import shared_task

from backend.metrics import job_executions_total
from backend.services.provider_notifications_service import provider_notifications_service

logger = logging.getLogger(__name__)


@shared_task(name="provider_notifications.send_weekly_notifications")
def send_weekly_notifications():
    """
    Job para enviar notificações semanais de performance.
    Configurado para executar toda segunda-feira às 9:00 AM.
    """
    logger.info("Iniciando job de notificações semanais de performance")
    
    try:
        # Executar o serviço de notificações
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        result = loop.run_until_complete(
            provider_notifications_service.send_weekly_performance_notifications()
        )
        
        # Registrar métrica de sucesso
        job_executions_total.labels(
            job_name="send_weekly_notifications",
            status="success"
        ).inc()
        
        logger.info(f"Notificações semanais enviadas com sucesso: {result}")
        
        return {
            "status": "success",
            "timestamp": datetime.now().isoformat(),
            "stats": result
        }
        
    except Exception as e:
        # Registrar métrica de falha
        job_executions_total.labels(
            job_name="send_weekly_notifications", 
            status="failure"
        ).inc()
        
        logger.error(f"Erro ao enviar notificações semanais: {e}")
        raise
        
    finally:
        loop.close()


@shared_task(name="provider_notifications.send_notification_to_provider")
def send_notification_to_provider(provider_id: str, notification_type: str = "performance_change"):
    """
    Job para enviar notificação específica para um prestador.
    Usado para notificações imediatas quando há mudanças significativas.
    
    Args:
        provider_id: ID do prestador
        notification_type: Tipo de notificação (performance_change, milestone, etc.)
    """
    logger.info(f"Enviando notificação {notification_type} para prestador {provider_id}")
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        # Buscar dados do prestador
        provider_data = loop.run_until_complete(
            provider_notifications_service._get_provider_data(provider_id)
        )
        
        if not provider_data:
            logger.warning(f"Prestador {provider_id} não encontrado")
            return {"status": "error", "message": "Provider not found"}
        
        # Analisar mudanças
        changes = loop.run_until_complete(
            provider_notifications_service._analyze_weekly_changes(provider_id)
        )
        
        # Enviar notificação se houver mudanças significativas
        if changes["has_significant_changes"]:
            success = loop.run_until_complete(
                provider_notifications_service._send_provider_notification(
                    provider_data, changes
                )
            )
            
            if success:
                logger.info(f"Notificação enviada para {provider_data['email']}")
                return {"status": "success", "provider_id": provider_id}
            else:
                logger.error(f"Falha ao enviar notificação para {provider_data['email']}")
                return {"status": "error", "message": "Failed to send notification"}
        else:
            logger.info(f"Sem mudanças significativas para {provider_id}")
            return {"status": "skipped", "message": "No significant changes"}
            
    except Exception as e:
        logger.error(f"Erro ao enviar notificação para prestador {provider_id}: {e}")
        raise
        
    finally:
        loop.close()


@shared_task(name="provider_notifications.cleanup_old_notifications")
def cleanup_old_notifications():
    """
    Job para limpeza de logs antigos de notificações.
    Executa mensalmente para manter o banco limpo.
    """
    logger.info("Iniciando limpeza de notificações antigas")
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        # Implementar limpeza de logs antigos (>90 dias)
        # Em produção, isso removeria registros da tabela de logs
        cleanup_count = 0  # Placeholder
        
        logger.info(f"Limpeza concluída: {cleanup_count} registros removidos")
        
        return {
            "status": "success",
            "cleaned_records": cleanup_count,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro na limpeza de notificações: {e}")
        raise
        
    finally:
        loop.close()


if __name__ == "__main__":
    # Executar como script standalone para testes
    print("Executando notificações semanais...")
    result = send_weekly_notifications()
    print(f"Resultado: {result}") 