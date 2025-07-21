# -*- coding: utf-8 -*-
"""
Webhooks para Sistema de Mensagens Unificadas
=============================================

Endpoints para receber webhooks do Unipile e sincronizar mensagens
em tempo real de todas as plataformas conectadas.
"""

from fastapi import APIRouter, Request, HTTPException, BackgroundTasks
from typing import Dict, Any
import json
import logging
from datetime import datetime

from ..services.unified_messaging_service import UnifiedMessagingService
from ..services.notification_service import NotificationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/webhooks", tags=["Messaging Webhooks"])


# ===============================
# WEBHOOK HANDLERS PRINCIPAIS
# ===============================

@router.post("/unipile/messages")
async def handle_unipile_message_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """
    Recebe webhooks da Unipile para eventos de mensagens.
    
    Tipos de eventos suportados:
    - message_received: Nova mensagem recebida
    - message_sent: Mensagem enviada
    - message_read: Mensagem marcada como lida
    - message_deleted: Mensagem deletada
    - chat_created: Novo chat criado
    - chat_updated: Chat atualizado
    """
    try:
        # Obtém payload do webhook
        payload = await request.json()
        
        # Valida estrutura básica
        if not _validate_webhook_payload(payload):
            raise HTTPException(status_code=400, detail="Payload inválido")
        
        event_type = payload.get("type")
        event_data = payload.get("data", {})
        
        logger.info(f"Webhook recebido: {event_type} para {event_data.get('account_id')}")
        
        # Processa evento em background para resposta rápida
        background_tasks.add_task(
            _process_webhook_event,
            event_type,
            event_data,
            payload.get("timestamp")
        )
        
        return {
            "success": True,
            "message": f"Evento {event_type} processado",
            "timestamp": datetime.now().isoformat()
        }
        
    except json.JSONDecodeError:
        logger.error("Erro ao decodificar JSON do webhook")
        raise HTTPException(status_code=400, detail="JSON inválido")
    except Exception as e:
        logger.error(f"Erro no webhook handler: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/unipile/calendar")
async def handle_unipile_calendar_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """
    Recebe webhooks da Unipile para eventos de calendário.
    
    Tipos de eventos suportados:
    - event_created: Novo evento criado
    - event_updated: Evento atualizado
    - event_deleted: Evento deletado
    - reminder_triggered: Lembrete acionado
    """
    try:
        payload = await request.json()
        
        if not _validate_webhook_payload(payload):
            raise HTTPException(status_code=400, detail="Payload inválido")
        
        event_type = payload.get("type")
        event_data = payload.get("data", {})
        
        logger.info(f"Webhook calendário recebido: {event_type}")
        
        # Processa evento de calendário
        background_tasks.add_task(
            _process_calendar_webhook_event,
            event_type,
            event_data,
            payload.get("timestamp")
        )
        
        return {
            "success": True,
            "message": f"Evento de calendário {event_type} processado",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro no webhook de calendário: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/unipile/accounts")
async def handle_unipile_account_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """
    Recebe webhooks da Unipile para eventos de contas.
    
    Tipos de eventos suportados:
    - account_connected: Conta conectada
    - account_disconnected: Conta desconectada
    - account_error: Erro na conta
    - sync_completed: Sincronização concluída
    - sync_failed: Sincronização falhou
    """
    try:
        payload = await request.json()
        
        if not _validate_webhook_payload(payload):
            raise HTTPException(status_code=400, detail="Payload inválido")
        
        event_type = payload.get("type")
        event_data = payload.get("data", {})
        
        logger.info(f"Webhook conta recebido: {event_type} para {event_data.get('account_id')}")
        
        # Processa evento de conta
        background_tasks.add_task(
            _process_account_webhook_event,
            event_type,
            event_data,
            payload.get("timestamp")
        )
        
        return {
            "success": True,
            "message": f"Evento de conta {event_type} processado",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro no webhook de conta: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# PROCESSADORES DE EVENTOS
# ===============================

async def _process_webhook_event(event_type: str, event_data: Dict[str, Any], timestamp: str):
    """Processa eventos de mensagens em background."""
    try:
        if event_type == "message_received":
            await _process_message_received(event_data, timestamp)
        elif event_type == "message_sent":
            await _process_message_sent(event_data, timestamp)
        elif event_type == "message_read":
            await _process_message_read(event_data, timestamp)
        elif event_type == "message_deleted":
            await _process_message_deleted(event_data, timestamp)
        elif event_type == "chat_created":
            await _process_chat_created(event_data, timestamp)
        elif event_type == "chat_updated":
            await _process_chat_updated(event_data, timestamp)
        else:
            logger.warning(f"Tipo de evento não suportado: {event_type}")
            
    except Exception as e:
        logger.error(f"Erro ao processar evento {event_type}: {e}")


async def _process_message_received(event_data: Dict[str, Any], timestamp: str):
    """Processa nova mensagem recebida."""
    try:
        message_data = {
            "provider_message_id": event_data.get("message_id"),
            "chat_id": event_data.get("chat_id"),
            "sender_id": event_data.get("sender_id"),
            "sender_name": event_data.get("sender_name"),
            "sender_email": event_data.get("sender_email"),
            "content": event_data.get("content"),
            "message_type": event_data.get("type", "text"),
            "attachments": event_data.get("attachments", []),
            "is_outgoing": False,
            "is_read": False,
            "sent_at": _parse_timestamp(event_data.get("timestamp", timestamp)),
            "received_at": datetime.now()
        }
        
        # TODO: Salvar mensagem no banco de dados
        await _save_unified_message(message_data)
        
        # Atualiza chat com última mensagem
        await _update_chat_last_message(
            event_data.get("chat_id"),
            event_data.get("content"),
            message_data["sent_at"]
        )
        
        # Incrementa contador de não lidas
        await _increment_unread_count(event_data.get("chat_id"))
        
        # Envia notificação push
        user_id = await _get_user_id_from_chat(event_data.get("chat_id"))
        if user_id:
            notification_service = NotificationService()
            await notification_service.send_message_notification(user_id, {
                "sender_name": event_data.get("sender_name"),
                "content": event_data.get("content"),
                "chat_id": event_data.get("chat_id"),
                "provider": event_data.get("provider")
            })
        
        logger.info(f"Mensagem recebida processada: {event_data.get('message_id')}")
        
    except Exception as e:
        logger.error(f"Erro ao processar mensagem recebida: {e}")


async def _process_message_sent(event_data: Dict[str, Any], timestamp: str):
    """Processa mensagem enviada."""
    try:
        message_data = {
            "provider_message_id": event_data.get("message_id"),
            "chat_id": event_data.get("chat_id"),
            "content": event_data.get("content"),
            "message_type": event_data.get("type", "text"),
            "attachments": event_data.get("attachments", []),
            "is_outgoing": True,
            "is_read": False,
            "sent_at": _parse_timestamp(event_data.get("timestamp", timestamp)),
            "received_at": datetime.now()
        }
        
        # TODO: Salvar mensagem no banco de dados
        await _save_unified_message(message_data)
        
        # Atualiza chat com última mensagem
        await _update_chat_last_message(
            event_data.get("chat_id"),
            event_data.get("content"),
            message_data["sent_at"]
        )
        
        logger.info(f"Mensagem enviada processada: {event_data.get('message_id')}")
        
    except Exception as e:
        logger.error(f"Erro ao processar mensagem enviada: {e}")


async def _process_message_read(event_data: Dict[str, Any], timestamp: str):
    """Processa mensagem marcada como lida."""
    try:
        message_id = event_data.get("message_id")
        chat_id = event_data.get("chat_id")
        
        # TODO: Atualizar status de lida no banco
        await _mark_message_as_read(message_id)
        
        # Se todas as mensagens foram lidas, zera contador
        if event_data.get("all_messages_read"):
            await _reset_unread_count(chat_id)
        
        logger.info(f"Mensagem marcada como lida: {message_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar mensagem lida: {e}")


async def _process_message_deleted(event_data: Dict[str, Any], timestamp: str):
    """Processa mensagem deletada."""
    try:
        message_id = event_data.get("message_id")
        
        # TODO: Marcar mensagem como deletada no banco
        await _mark_message_as_deleted(message_id)
        
        logger.info(f"Mensagem deletada: {message_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar mensagem deletada: {e}")


async def _process_chat_created(event_data: Dict[str, Any], timestamp: str):
    """Processa novo chat criado."""
    try:
        chat_data = {
            "provider_chat_id": event_data.get("chat_id"),
            "provider": event_data.get("provider"),
            "chat_name": event_data.get("name"),
            "chat_type": event_data.get("type", "direct"),
            "chat_avatar_url": event_data.get("avatar"),
            "created_at": _parse_timestamp(event_data.get("timestamp", timestamp))
        }
        
        # TODO: Salvar novo chat no banco
        user_id = event_data.get("user_id")
        if user_id:
            await _save_unified_chat(user_id, chat_data)
        
        logger.info(f"Novo chat criado: {event_data.get('chat_id')}")
        
    except Exception as e:
        logger.error(f"Erro ao processar chat criado: {e}")


async def _process_chat_updated(event_data: Dict[str, Any], timestamp: str):
    """Processa chat atualizado."""
    try:
        chat_id = event_data.get("chat_id")
        updates = {
            "chat_name": event_data.get("name"),
            "chat_avatar_url": event_data.get("avatar"),
            "updated_at": datetime.now()
        }
        
        # TODO: Atualizar chat no banco
        await _update_unified_chat(chat_id, updates)
        
        logger.info(f"Chat atualizado: {chat_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar chat atualizado: {e}")


async def _process_calendar_webhook_event(event_type: str, event_data: Dict[str, Any], timestamp: str):
    """Processa eventos de calendário."""
    try:
        if event_type == "event_created":
            await _process_calendar_event_created(event_data, timestamp)
        elif event_type == "event_updated":
            await _process_calendar_event_updated(event_data, timestamp)
        elif event_type == "event_deleted":
            await _process_calendar_event_deleted(event_data, timestamp)
        elif event_type == "reminder_triggered":
            await _process_calendar_reminder(event_data, timestamp)
        else:
            logger.warning(f"Tipo de evento de calendário não suportado: {event_type}")
            
    except Exception as e:
        logger.error(f"Erro ao processar evento de calendário {event_type}: {e}")


async def _process_calendar_event_created(event_data: Dict[str, Any], timestamp: str):
    """Processa novo evento de calendário criado."""
    try:
        event_info = {
            "provider_event_id": event_data.get("event_id"),
            "calendar_id": event_data.get("calendar_id"),
            "title": event_data.get("title"),
            "description": event_data.get("description"),
            "location": event_data.get("location"),
            "start_time": _parse_timestamp(event_data.get("start_time")),
            "end_time": _parse_timestamp(event_data.get("end_time")),
            "all_day": event_data.get("all_day", False),
            "attendees": event_data.get("attendees", []),
            "reminders": event_data.get("reminders", []),
            "created_at": datetime.now()
        }
        
        # TODO: Salvar evento no banco
        await _save_calendar_event(event_info)
        
        logger.info(f"Evento de calendário criado: {event_data.get('event_id')}")
        
    except Exception as e:
        logger.error(f"Erro ao processar evento criado: {e}")


async def _process_calendar_event_updated(event_data: Dict[str, Any], timestamp: str):
    """Processa evento de calendário atualizado."""
    try:
        event_id = event_data.get("event_id")
        updates = {
            "title": event_data.get("title"),
            "description": event_data.get("description"),
            "location": event_data.get("location"),
            "start_time": _parse_timestamp(event_data.get("start_time")),
            "end_time": _parse_timestamp(event_data.get("end_time")),
            "updated_at": datetime.now()
        }
        
        # TODO: Atualizar evento no banco
        await _update_calendar_event(event_id, updates)
        
        logger.info(f"Evento de calendário atualizado: {event_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar evento atualizado: {e}")


async def _process_calendar_event_deleted(event_data: Dict[str, Any], timestamp: str):
    """Processa evento de calendário deletado."""
    try:
        event_id = event_data.get("event_id")
        
        # TODO: Marcar evento como deletado no banco
        await _mark_calendar_event_as_deleted(event_id)
        
        logger.info(f"Evento de calendário deletado: {event_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar evento deletado: {e}")


async def _process_calendar_reminder(event_data: Dict[str, Any], timestamp: str):
    """Processa lembrete de calendário."""
    try:
        user_id = await _get_user_id_from_calendar(event_data.get("calendar_id"))
        if user_id:
            notification_service = NotificationService()
            await notification_service.send_calendar_reminder(user_id, {
                "id": event_data.get("event_id"),
                "title": event_data.get("title"),
                "start_time": _parse_timestamp(event_data.get("start_time"))
            })
        
        logger.info(f"Lembrete de calendário enviado: {event_data.get('event_id')}")
        
    except Exception as e:
        logger.error(f"Erro ao processar lembrete: {e}")


async def _process_account_webhook_event(event_type: str, event_data: Dict[str, Any], timestamp: str):
    """Processa eventos de contas."""
    try:
        if event_type == "account_connected":
            await _process_account_connected(event_data, timestamp)
        elif event_type == "account_disconnected":
            await _process_account_disconnected(event_data, timestamp)
        elif event_type == "account_error":
            await _process_account_error(event_data, timestamp)
        elif event_type == "sync_completed":
            await _process_sync_completed(event_data, timestamp)
        elif event_type == "sync_failed":
            await _process_sync_failed(event_data, timestamp)
        else:
            logger.warning(f"Tipo de evento de conta não suportado: {event_type}")
            
    except Exception as e:
        logger.error(f"Erro ao processar evento de conta {event_type}: {e}")


async def _process_account_connected(event_data: Dict[str, Any], timestamp: str):
    """Processa conta conectada."""
    try:
        account_id = event_data.get("account_id")
        provider = event_data.get("provider")
        
        # TODO: Atualizar status da conta no banco
        await _update_account_status(account_id, "active", None)
        
        logger.info(f"Conta {provider} conectada: {account_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar conta conectada: {e}")


async def _process_account_disconnected(event_data: Dict[str, Any], timestamp: str):
    """Processa conta desconectada."""
    try:
        account_id = event_data.get("account_id")
        provider = event_data.get("provider")
        
        # TODO: Atualizar status da conta no banco
        await _update_account_status(account_id, "disconnected", None)
        
        logger.info(f"Conta {provider} desconectada: {account_id}")
        
    except Exception as e:
        logger.error(f"Erro ao processar conta desconectada: {e}")


async def _process_account_error(event_data: Dict[str, Any], timestamp: str):
    """Processa erro na conta."""
    try:
        account_id = event_data.get("account_id")
        error_message = event_data.get("error")
        
        # TODO: Atualizar status da conta no banco
        await _update_account_status(account_id, "error", error_message)
        
        logger.error(f"Erro na conta {account_id}: {error_message}")
        
    except Exception as e:
        logger.error(f"Erro ao processar erro de conta: {e}")


async def _process_sync_completed(event_data: Dict[str, Any], timestamp: str):
    """Processa sincronização concluída."""
    try:
        account_id = event_data.get("account_id")
        sync_stats = event_data.get("stats", {})
        
        # TODO: Atualizar última sincronização no banco
        await _update_last_sync(account_id, datetime.now(), sync_stats)
        
        logger.info(f"Sincronização concluída para {account_id}: {sync_stats}")
        
    except Exception as e:
        logger.error(f"Erro ao processar sincronização concluída: {e}")


async def _process_sync_failed(event_data: Dict[str, Any], timestamp: str):
    """Processa falha na sincronização."""
    try:
        account_id = event_data.get("account_id")
        error_message = event_data.get("error")
        
        # TODO: Registrar falha de sincronização
        await _log_sync_failure(account_id, error_message)
        
        logger.error(f"Sincronização falhou para {account_id}: {error_message}")
        
    except Exception as e:
        logger.error(f"Erro ao processar falha de sincronização: {e}")


# ===============================
# FUNÇÕES AUXILIARES
# ===============================

def _validate_webhook_payload(payload: Dict[str, Any]) -> bool:
    """Valida estrutura básica do payload do webhook."""
    required_fields = ["type", "data"]
    return all(field in payload for field in required_fields)


def _parse_timestamp(timestamp_str: str) -> datetime:
    """Converte string de timestamp para datetime."""
    if not timestamp_str:
        return datetime.now()
    
    try:
        # Tenta ISO format primeiro
        return datetime.fromisoformat(timestamp_str.replace('Z', '+00:00')).replace(tzinfo=None)
    except:
        try:
            # Tenta formato timestamp
            return datetime.fromtimestamp(float(timestamp_str))
        except:
            return datetime.now()


# TODO: Implementar funções de banco de dados
async def _save_unified_message(message_data: Dict[str, Any]):
    """Salva mensagem unificada no banco de dados."""
    pass


async def _update_chat_last_message(chat_id: str, content: str, timestamp: datetime):
    """Atualiza última mensagem do chat."""
    pass


async def _increment_unread_count(chat_id: str):
    """Incrementa contador de mensagens não lidas."""
    pass


async def _reset_unread_count(chat_id: str):
    """Zera contador de mensagens não lidas."""
    pass


async def _mark_message_as_read(message_id: str):
    """Marca mensagem como lida."""
    pass


async def _mark_message_as_deleted(message_id: str):
    """Marca mensagem como deletada."""
    pass


async def _save_unified_chat(user_id: str, chat_data: Dict[str, Any]):
    """Salva novo chat unificado."""
    pass


async def _update_unified_chat(chat_id: str, updates: Dict[str, Any]):
    """Atualiza chat unificado."""
    pass


async def _save_calendar_event(event_data: Dict[str, Any]):
    """Salva evento de calendário."""
    pass


async def _update_calendar_event(event_id: str, updates: Dict[str, Any]):
    """Atualiza evento de calendário."""
    pass


async def _mark_calendar_event_as_deleted(event_id: str):
    """Marca evento de calendário como deletado."""
    pass


async def _update_account_status(account_id: str, status: str, error_message: str):
    """Atualiza status da conta."""
    pass


async def _update_last_sync(account_id: str, sync_time: datetime, stats: Dict[str, Any]):
    """Atualiza última sincronização."""
    pass


async def _log_sync_failure(account_id: str, error_message: str):
    """Registra falha de sincronização."""
    pass


async def _get_user_id_from_chat(chat_id: str) -> str:
    """Obtém ID do usuário a partir do chat."""
    # TODO: Implementar busca no banco
    return "user_123"


async def _get_user_id_from_calendar(calendar_id: str) -> str:
    """Obtém ID do usuário a partir do calendário."""
    # TODO: Implementar busca no banco
    return "user_123"


# ===============================
# ENDPOINT DE TESTE
# ===============================

@router.get("/test")
async def test_webhook_endpoint():
    """Endpoint para testar configuração de webhooks."""
    return {
        "success": True,
        "message": "Webhooks configurados e funcionando",
        "supported_events": {
            "messages": [
                "message_received",
                "message_sent", 
                "message_read",
                "message_deleted",
                "chat_created",
                "chat_updated"
            ],
            "calendar": [
                "event_created",
                "event_updated",
                "event_deleted",
                "reminder_triggered"
            ],
            "accounts": [
                "account_connected",
                "account_disconnected",
                "account_error",
                "sync_completed",
                "sync_failed"
            ]
        },
        "timestamp": datetime.now().isoformat()
    }


# ===============================
# SERVIÇO DE NOTIFICAÇÕES
# ===============================

class NotificationService:
    """Serviço mock para notificações - substituir pela implementação real."""
    
    async def send_message_notification(self, user_id: str, message_data: Dict[str, Any]):
        """Envia notificação de nova mensagem."""
        logger.info(f"Notificação enviada para {user_id}: Nova mensagem de {message_data.get('sender_name')}")
    
    async def send_calendar_reminder(self, user_id: str, event_data: Dict[str, Any]):
        """Envia lembrete de calendário."""
        logger.info(f"Lembrete enviado para {user_id}: {event_data.get('title')}")