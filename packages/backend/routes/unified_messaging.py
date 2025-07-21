# -*- coding: utf-8 -*-
"""
Rotas FastAPI para Sistema de Mensagens Unificadas
=================================================

Endpoints para gerenciar mensagens consolidadas de múltiplas plataformas
(LinkedIn, Instagram, WhatsApp, Gmail, Outlook) via Unipile SDK.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Body
from typing import List, Dict, Optional, Any
from datetime import datetime
import logging

from ..services.unified_messaging_service import (
    UnifiedMessagingService,
    UnifiedAccount,
    UnifiedChat,
    UnifiedMessage,
    UnifiedContact
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/messaging", tags=["Unified Messaging"])


# ===============================
# MODELOS DE REQUEST/RESPONSE
# ===============================

class ConnectAccountRequest:
    """Request para conectar uma conta."""
    def __init__(self, provider: str, credentials: Dict[str, str]):
        self.provider = provider
        self.credentials = credentials


class SendMessageRequest:
    """Request para enviar mensagem."""
    def __init__(
        self,
        content: str,
        message_type: str = "text",
        attachments: Optional[List[Dict]] = None
    ):
        self.content = content
        self.message_type = message_type
        self.attachments = attachments or []


class SendEmailRequest:
    """Request para enviar e-mail."""
    def __init__(
        self,
        to: List[str],
        subject: str,
        content: str,
        cc: Optional[List[str]] = None,
        bcc: Optional[List[str]] = None,
        attachments: Optional[List[Dict]] = None
    ):
        self.to = to
        self.subject = subject
        self.content = content
        self.cc = cc or []
        self.bcc = bcc or []
        self.attachments = attachments or []


# ===============================
# DEPENDÊNCIAS
# ===============================

def get_unified_messaging_service() -> UnifiedMessagingService:
    """Retorna instância do serviço de mensagens unificadas."""
    return UnifiedMessagingService()


def get_current_user():
    """Mock do usuário atual - substituir pela autenticação real."""
    return {"id": "user_123", "email": "user@example.com"}


# ===============================
# ENDPOINTS DE CONTAS
# ===============================

@router.post("/connect/{provider}")
async def connect_account(
    provider: str,
    credentials: Dict[str, str] = Body(...),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """
    Conecta uma conta de mensagens de qualquer provedor.
    
    Provedores suportados: linkedin, instagram, whatsapp, gmail, outlook
    """
    try:
        result = await service.connect_account(provider, credentials)
        
        if result.get("success"):
            return {
                "success": True,
                "message": f"Conta {provider} conectada com sucesso",
                "account_id": result.get("account_id"),
                "data": result
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", f"Falha ao conectar {provider}")
            )
            
    except Exception as e:
        logger.error(f"Erro ao conectar conta {provider}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/accounts")
async def list_connected_accounts(
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Lista todas as contas conectadas do usuário."""
    try:
        accounts = await service.list_connected_accounts()
        
        return {
            "success": True,
            "accounts": [
                {
                    "id": account.id,
                    "provider": account.provider,
                    "account_name": account.account_name,
                    "account_email": account.account_email,
                    "status": account.status,
                    "last_sync": account.last_sync.isoformat() if account.last_sync else None
                }
                for account in accounts
            ],
            "total": len(accounts)
        }
        
    except Exception as e:
        logger.error(f"Erro ao listar contas: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/accounts/{account_id}")
async def disconnect_account(
    account_id: str,
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Desconecta uma conta específica."""
    try:
        # TODO: Implementar desconexão na API Unipile
        return {
            "success": True,
            "message": f"Conta {account_id} desconectada com sucesso"
        }
        
    except Exception as e:
        logger.error(f"Erro ao desconectar conta {account_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINTS DE CHATS
# ===============================

@router.get("/chats")
async def list_unified_chats(
    account_id: Optional[str] = Query(None, description="ID da conta específica"),
    provider: Optional[str] = Query(None, description="Filtrar por provedor"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Lista todos os chats unificados do usuário."""
    try:
        chats = await service.list_all_chats(account_id)
        
        # Filtra por provedor se especificado
        if provider:
            chats = [chat for chat in chats if chat.provider.lower() == provider.lower()]
        
        return {
            "success": True,
            "chats": [
                {
                    "id": chat.id,
                    "provider": chat.provider,
                    "chat_name": chat.chat_name,
                    "chat_type": chat.chat_type,
                    "avatar_url": chat.avatar_url,
                    "last_message": chat.last_message,
                    "last_message_at": chat.last_message_at.isoformat() if chat.last_message_at else None,
                    "unread_count": chat.unread_count,
                    "is_archived": chat.is_archived
                }
                for chat in chats
            ],
            "total": len(chats)
        }
        
    except Exception as e:
        logger.error(f"Erro ao listar chats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chats/{chat_id}")
async def get_chat_details(
    chat_id: str,
    account_id: str = Query(..., description="ID da conta"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Obtém detalhes de um chat específico."""
    try:
        chat = await service.get_chat_details(chat_id, account_id)
        
        if not chat:
            raise HTTPException(status_code=404, detail="Chat não encontrado")
        
        return {
            "success": True,
            "chat": {
                "id": chat.id,
                "provider": chat.provider,
                "chat_name": chat.chat_name,
                "chat_type": chat.chat_type,
                "avatar_url": chat.avatar_url,
                "last_message": chat.last_message,
                "last_message_at": chat.last_message_at.isoformat() if chat.last_message_at else None,
                "unread_count": chat.unread_count,
                "is_archived": chat.is_archived
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao obter chat {chat_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chats")
async def start_new_chat(
    account_id: str = Body(..., description="ID da conta"),
    participant_ids: List[str] = Body(..., description="IDs dos participantes"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Inicia um novo chat com participantes especificados."""
    try:
        chat = await service.start_new_chat(account_id, participant_ids)
        
        if not chat:
            raise HTTPException(status_code=400, detail="Falha ao criar chat")
        
        return {
            "success": True,
            "message": "Chat criado com sucesso",
            "chat": {
                "id": chat.id,
                "provider": chat.provider,
                "chat_name": chat.chat_name,
                "chat_type": chat.chat_type
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINTS DE MENSAGENS
# ===============================

@router.get("/chats/{chat_id}/messages")
async def get_chat_messages(
    chat_id: str,
    account_id: str = Query(..., description="ID da conta"),
    limit: int = Query(50, ge=1, le=100, description="Número de mensagens"),
    cursor: Optional[str] = Query(None, description="Cursor para paginação"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Recupera mensagens de um chat específico."""
    try:
        messages = await service.get_chat_messages(chat_id, account_id, limit, cursor)
        
        return {
            "success": True,
            "messages": [
                {
                    "id": msg.id,
                    "provider_message_id": msg.provider_message_id,
                    "sender_id": msg.sender_id,
                    "sender_name": msg.sender_name,
                    "sender_email": msg.sender_email,
                    "message_type": msg.message_type,
                    "content": msg.content,
                    "attachments": msg.attachments,
                    "is_outgoing": msg.is_outgoing,
                    "is_read": msg.is_read,
                    "sent_at": msg.sent_at.isoformat() if msg.sent_at else None,
                    "received_at": msg.received_at.isoformat() if msg.received_at else None
                }
                for msg in messages
            ],
            "total": len(messages),
            "has_more": len(messages) == limit
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar mensagens do chat {chat_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chats/{chat_id}/messages")
async def send_message(
    chat_id: str,
    account_id: str = Query(..., description="ID da conta"),
    message_data: Dict[str, Any] = Body(...),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Envia uma mensagem para um chat específico."""
    try:
        content = message_data.get("content", "")
        message_type = message_data.get("message_type", "text")
        attachments = message_data.get("attachments", [])
        
        if not content.strip() and not attachments:
            raise HTTPException(status_code=400, detail="Conteúdo ou anexos são obrigatórios")
        
        message = await service.send_message(
            chat_id=chat_id,
            account_id=account_id,
            content=content,
            message_type=message_type,
            attachments=attachments
        )
        
        if not message:
            raise HTTPException(status_code=400, detail="Falha ao enviar mensagem")
        
        return {
            "success": True,
            "message": "Mensagem enviada com sucesso",
            "data": {
                "id": message.id,
                "provider_message_id": message.provider_message_id,
                "content": message.content,
                "message_type": message.message_type,
                "sent_at": message.sent_at.isoformat() if message.sent_at else None
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao enviar mensagem: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/messages/{message_id}/read")
async def mark_message_as_read(
    message_id: str,
    chat_id: str = Body(..., description="ID do chat"),
    account_id: str = Body(..., description="ID da conta"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Marca uma mensagem como lida."""
    try:
        success = await service.mark_message_as_read(message_id, chat_id, account_id)
        
        if success:
            return {
                "success": True,
                "message": "Mensagem marcada como lida"
            }
        else:
            raise HTTPException(status_code=400, detail="Falha ao marcar mensagem como lida")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao marcar mensagem como lida: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINTS DE E-MAIL
# ===============================

@router.get("/emails")
async def list_emails(
    account_id: str = Query(..., description="ID da conta de e-mail"),
    folder: str = Query("INBOX", description="Pasta do e-mail"),
    limit: int = Query(50, ge=1, le=100, description="Número de e-mails"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Lista e-mails de uma conta específica."""
    try:
        emails = await service.list_emails(account_id, folder, limit)
        
        return {
            "success": True,
            "emails": [
                {
                    "id": email.id,
                    "provider_message_id": email.provider_message_id,
                    "sender_name": email.sender_name,
                    "sender_email": email.sender_email,
                    "content": email.content,
                    "attachments": email.attachments,
                    "is_read": email.is_read,
                    "sent_at": email.sent_at.isoformat() if email.sent_at else None
                }
                for email in emails
            ],
            "total": len(emails),
            "folder": folder
        }
        
    except Exception as e:
        logger.error(f"Erro ao listar e-mails: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/emails/send")
async def send_email(
    account_id: str = Query(..., description="ID da conta de e-mail"),
    email_data: Dict[str, Any] = Body(...),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Envia um e-mail."""
    try:
        to = email_data.get("to", [])
        subject = email_data.get("subject", "")
        content = email_data.get("content", "")
        cc = email_data.get("cc", [])
        bcc = email_data.get("bcc", [])
        attachments = email_data.get("attachments", [])
        
        if not to or not content.strip():
            raise HTTPException(status_code=400, detail="Destinatário e conteúdo são obrigatórios")
        
        success = await service.send_email(
            account_id=account_id,
            to=to,
            subject=subject,
            content=content,
            cc=cc,
            bcc=bcc,
            attachments=attachments
        )
        
        if success:
            return {
                "success": True,
                "message": "E-mail enviado com sucesso"
            }
        else:
            raise HTTPException(status_code=400, detail="Falha ao enviar e-mail")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao enviar e-mail: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINTS DE CONTATOS
# ===============================

@router.get("/contacts/profile")
async def get_profile_by_email(
    email: str = Query(..., description="E-mail do perfil"),
    provider: str = Query("linkedin", description="Provedor do perfil"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Busca perfil de usuário por e-mail."""
    try:
        contact = await service.get_profile_by_email(email, provider)
        
        if not contact:
            raise HTTPException(status_code=404, detail="Perfil não encontrado")
        
        return {
            "success": True,
            "profile": {
                "id": contact.id,
                "provider": contact.provider,
                "name": contact.name,
                "email": contact.email,
                "phone": contact.phone,
                "avatar_url": contact.avatar_url,
                "company": contact.company,
                "position": contact.position,
                "profile_url": contact.profile_url
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil {email}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/contacts/company/{company_id}")
async def get_company_profile(
    company_id: str,
    account_id: str = Query(..., description="ID da conta LinkedIn"),
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Busca perfil de empresa no LinkedIn."""
    try:
        company = await service.get_company_profile(company_id, account_id)
        
        if not company:
            raise HTTPException(status_code=404, detail="Empresa não encontrada")
        
        return {
            "success": True,
            "company": company
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar empresa {company_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINTS DE SINCRONIZAÇÃO
# ===============================

@router.post("/sync")
async def sync_all_messages(
    current_user: dict = Depends(get_current_user),
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Sincroniza todas as mensagens de todas as contas do usuário."""
    try:
        result = await service.sync_all_messages(current_user["id"])
        
        return {
            "success": result.get("success", False),
            "message": "Sincronização concluída" if result.get("success") else "Falha na sincronização",
            "data": result
        }
        
    except Exception as e:
        logger.error(f"Erro na sincronização: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# ENDPOINT DE HEALTH CHECK
# ===============================

@router.get("/health")
async def health_check(
    service: UnifiedMessagingService = Depends(get_unified_messaging_service)
):
    """Verifica saúde da integração com Unipile."""
    try:
        health_data = await service.health_check()
        
        status_code = 200 if health_data.get("status") == "healthy" else 503
        
        return health_data
        
    except Exception as e:
        logger.error(f"Erro no health check: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }