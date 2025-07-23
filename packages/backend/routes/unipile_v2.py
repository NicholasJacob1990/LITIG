# -*- coding: utf-8 -*-
"""
Unipile Routes V2 - Endpoints usando Camada de Compatibilidade
==============================================================

Novos endpoints que usam a camada de compatibilidade, permitindo
migração gradual do wrapper Node.js para o SDK oficial Python.

Funcionalidades:
- Auto-fallback entre SDK oficial e wrapper Node.js
- Monitoramento de performance
- Controle manual de serviços
- Interface unificada
"""

from fastapi import APIRouter, HTTPException, Depends, Query, Body
from fastapi.responses import JSONResponse
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging

# Camada de compatibilidade
from backend.services.unipile_compatibility_layer import (
    get_unipile_service, 
    ServiceType,
    UnipileCompatibilityLayer
)

# App Service com métodos novos
from backend.services.unipile_app_service import get_unipile_app_service

# Autenticação
from backend.auth import get_current_user

router = APIRouter(prefix="/api/v2/unipile", tags=["unipile-v2"])
logger = logging.getLogger(__name__)


# ===== ENDPOINTS DE MENSAGENS UNIFICADAS =====

@router.get("/chats")
async def get_all_chats(
    account_id: Optional[str] = Query(None, description="ID da conta específica (opcional)"),
    current_user = Depends(get_current_user)
):
    """
    Lista todas as conversas de todas as contas conectadas ou de uma conta específica.
    
    Retorna chats do WhatsApp, Telegram, LinkedIn Messages, etc.
    """
    try:
        service = get_unipile_app_service()
        result = await service.get_all_chats(account_id)
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao buscar chats")
            )
            
    except Exception as e:
        logger.error(f"Erro ao buscar chats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chats/{chat_id}/messages")
async def get_chat_messages(
    chat_id: str,
    limit: int = Query(50, description="Número máximo de mensagens"),
    current_user = Depends(get_current_user)
):
    """
    Busca mensagens de um chat específico com paginação.
    """
    try:
        service = get_unipile_app_service()
        result = await service.get_all_messages(chat_id, limit)
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao buscar mensagens")
            )
            
    except Exception as e:
        logger.error(f"Erro ao buscar mensagens do chat {chat_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chats/{chat_id}/messages")
async def send_message(
    chat_id: str,
    message_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Envia mensagem em um chat.
    
    Body:
    {
        "content": "Texto da mensagem",
        "attachments": ["url1", "url2"] // opcional
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.send_message(
            chat_id,
            message_data.get("content", ""),
            message_data.get("attachments")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao enviar mensagem")
            )
            
    except Exception as e:
        logger.error(f"Erro ao enviar mensagem: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE CONEXÕES OAUTH2 =====

@router.post("/connect/gmail")
async def connect_gmail(
    email_data: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Conecta conta Gmail usando OAuth2.
    
    Body:
    {
        "email": "usuario@gmail.com"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.connect_gmail(email_data.get("email", ""))
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao conectar Gmail")
            )
            
    except Exception as e:
        logger.error(f"Erro ao conectar Gmail: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/connect/whatsapp")
async def connect_whatsapp(
    current_user = Depends(get_current_user)
):
    """
    Conecta WhatsApp via QR Code.
    
    Retorna URL do QR Code para escaneamento.
    """
    try:
        service = get_unipile_app_service()
        result = await service.connect_whatsapp()
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao conectar WhatsApp")
            )
            
    except Exception as e:
        logger.error(f"Erro ao conectar WhatsApp: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/connect/telegram")
async def connect_telegram(
    phone_data: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Conecta Telegram usando número de telefone.
    
    Body:
    {
        "phone_number": "+5511999999999"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.connect_telegram(phone_data.get("phone_number", ""))
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao conectar Telegram")
            )
            
    except Exception as e:
        logger.error(f"Erro ao conectar Telegram: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE SISTEMA =====

@router.get("/health")
async def health_check_v2():
    """
    Health check avançado usando camada de compatibilidade.
    
    Returns:
        Status detalhado de todos os serviços disponíveis
    """
    try:
        service = get_unipile_service()
        health_data = await service.health_check()
        
        status_code = 200 if health_data.get("status") in ["healthy", "ok"] else 503
        
        return JSONResponse(
            status_code=status_code,
            content={
                **health_data,
                "version": "v2",
                "migration_status": "compatibility_layer_active"
            }
        )
        
    except Exception as e:
        logger.error(f"Erro no health check v2: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(e),
                "version": "v2",
                "timestamp": datetime.now().isoformat()
            }
        )


@router.get("/service/metrics")
async def get_service_metrics(current_user = Depends(get_current_user)):
    """
    Retorna métricas detalhadas dos serviços.
    """
    try:
        service = get_unipile_service()
        metrics = await service.get_service_metrics()
        
        return JSONResponse(content=metrics)
        
    except Exception as e:
        logger.error(f"Erro ao obter métricas: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/service/switch")
async def switch_service(
    service_type: str = Body(..., embed=True),
    current_user = Depends(get_current_user)
):
    """
    Permite alternar manualmente entre serviços.
    
    Args:
        service_type: "sdk_official", "wrapper_nodejs", ou "auto_fallback"
    """
    try:
        # Validar tipo de serviço
        try:
            new_service = ServiceType(service_type)
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail=f"Tipo de serviço inválido: {service_type}"
            )
        
        service = get_unipile_service()
        result = await service.switch_service(new_service)
        
        return JSONResponse(content=result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao alternar serviço: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE CONTAS =====

@router.get("/accounts")
async def list_accounts_v2(current_user = Depends(get_current_user)):
    """
    Lista todas as contas conectadas usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        accounts = await service.list_accounts()
        
        # Converter para formato consistente
        accounts_data = []
        for account in accounts:
            if hasattr(account, '__dict__'):  # UnipileAccount object
                accounts_data.append({
                    "id": account.id,
                    "provider": account.provider,
                    "email": account.email,
                    "status": account.status,
                    "last_sync": account.last_sync.isoformat() if account.last_sync else None
                })
            else:  # Dictionary
                accounts_data.append(account)
        
        return JSONResponse(content={
            "accounts": accounts_data,
            "total": len(accounts_data),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Erro ao listar contas v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE CALENDÁRIO =====

@router.post("/calendar/events")
async def create_calendar_event_v2(
    connection_id: str = Query(..., description="ID da conexão"),
    event_data: Dict[str, Any] = Body(..., description="Dados do evento"),
    current_user = Depends(get_current_user)
):
    """
    Cria evento de calendário usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        result = await service.create_calendar_event(connection_id, event_data)
        
        if result:
            return JSONResponse(content={
                "success": True,
                "event": result,
                "timestamp": datetime.now().isoformat()
            })
        else:
            raise HTTPException(status_code=400, detail="Falha ao criar evento")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar evento v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/calendar/events")
async def list_calendar_events_v2(
    connection_id: str = Query(..., description="ID da conexão"),
    calendar_id: Optional[str] = Query(None, description="ID do calendário específico"),
    current_user = Depends(get_current_user)
):
    """
    Lista eventos de calendário usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        events = await service.list_calendar_events(connection_id, calendar_id)
        
        return JSONResponse(content={
            "events": events,
            "total": len(events),
            "connection_id": connection_id,
            "calendar_id": calendar_id,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Erro ao listar eventos v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE EMAIL/MESSAGING =====

@router.post("/messaging/send")
async def send_email_v2(
    connection_id: str = Query(..., description="ID da conexão"),
    message_data: Dict[str, Any] = Body(..., description="Dados da mensagem"),
    current_user = Depends(get_current_user)
):
    """
    Envia email/mensagem usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        result = await service.send_email(connection_id, message_data)
        
        if result:
            return JSONResponse(content={
                "success": True,
                "message": result,
                "timestamp": datetime.now().isoformat()
            })
        else:
            raise HTTPException(status_code=400, detail="Falha ao enviar mensagem")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao enviar email v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/messaging/emails")
async def list_emails_v2(
    connection_id: str = Query(..., description="ID da conexão"),
    channel_id: Optional[str] = Query(None, description="ID do canal específico"),
    limit: int = Query(50, ge=1, le=1000, description="Limite de mensagens"),
    current_user = Depends(get_current_user)
):
    """
    Lista emails/mensagens usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        emails = await service.list_emails(connection_id, channel_id)
        
        # Aplicar limite
        emails = emails[:limit]
        
        return JSONResponse(content={
            "emails": emails,
            "total": len(emails),
            "connection_id": connection_id,
            "channel_id": channel_id,
            "limit": limit,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Erro ao listar emails v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE WEBHOOKS =====

@router.post("/webhooks")
async def create_webhook_v2(
    connection_id: str = Query(..., description="ID da conexão"),
    webhook_data: Dict[str, Any] = Body(..., description="Dados do webhook"),
    current_user = Depends(get_current_user)
):
    """
    Cria webhook usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        result = await service.create_webhook(connection_id, webhook_data)
        
        if result:
            return JSONResponse(content={
                "success": True,
                "webhook": result,
                "timestamp": datetime.now().isoformat()
            })
        else:
            raise HTTPException(status_code=400, detail="Falha ao criar webhook")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar webhook v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE INTEGRAÇÃO HÍBRIDA =====

@router.get("/communication-data")
async def get_communication_data_v2(
    oab_number: str = Query(..., description="Número da OAB"),
    email: Optional[str] = Query(None, description="Email opcional"),
    current_user = Depends(get_current_user)
):
    """
    Busca dados de comunicação para advogado usando camada de compatibilidade.
    """
    try:
        service = get_unipile_service()
        comm_data, transparency = await service.get_communication_data(oab_number, email)
        
        return JSONResponse(content={
            "success": comm_data is not None,
            "communication_data": comm_data,
            "transparency": transparency.to_dict() if transparency else None,
            "oab_number": oab_number,
            "email": email,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Erro ao buscar dados de comunicação v2: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS LINKEDIN ESPECÍFICOS =====

@router.post("/linkedin/send-inmail")
async def send_linkedin_inmail(
    message_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Envia InMail no LinkedIn.
    
    Body:
    {
        "account_id": "id_conta_linkedin",
        "recipient_id": "id_usuario_destinatario",
        "subject": "Assunto do InMail",
        "body": "Corpo da mensagem",
        "attachments": ["url1", "url2"] // opcional
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.send_inmail(
            account_id=message_data.get("account_id", ""),
            recipient_id=message_data.get("recipient_id", ""),
            subject=message_data.get("subject", ""),
            body=message_data.get("body", ""),
            attachments=message_data.get("attachments")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao enviar InMail")
            )
            
    except Exception as e:
        logger.error(f"Erro ao enviar InMail: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/linkedin/send-invitation")
async def send_linkedin_invitation(
    invitation_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Envia convite de conexão no LinkedIn.
    
    Body:
    {
        "account_id": "id_conta_linkedin",
        "user_id": "id_usuario_para_convidar",
        "message": "Mensagem personalizada" // opcional
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.send_invitation(
            account_id=invitation_data.get("account_id", ""),
            user_id=invitation_data.get("user_id", ""),
            message=invitation_data.get("message")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao enviar convite")
            )
            
    except Exception as e:
        logger.error(f"Erro ao enviar convite LinkedIn: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/linkedin/send-voice-note")
async def send_linkedin_voice_note(
    voice_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Envia nota de voz no LinkedIn.
    
    Body:
    {
        "account_id": "id_conta_linkedin",
        "chat_id": "id_chat_conversa",
        "audio_url": "url_arquivo_audio"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.send_voice_note(
            account_id=voice_data.get("account_id", ""),
            chat_id=voice_data.get("chat_id", ""),
            audio_url=voice_data.get("audio_url", "")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao enviar nota de voz")
            )
            
    except Exception as e:
        logger.error(f"Erro ao enviar nota de voz: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/linkedin/comment-post")
async def comment_linkedin_post(
    comment_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Comenta em uma postagem do LinkedIn.
    
    Body:
    {
        "account_id": "id_conta_linkedin",
        "post_id": "id_postagem",
        "comment": "Texto do comentário"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.comment_on_post(
            account_id=comment_data.get("account_id", ""),
            post_id=comment_data.get("post_id", ""),
            comment=comment_data.get("comment", "")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao comentar postagem")
            )
            
    except Exception as e:
        logger.error(f"Erro ao comentar postagem: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS GESTÃO COMPLETA DE EMAIL =====

@router.post("/emails/{email_id}/reply")
async def reply_to_email(
    email_id: str,
    reply_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Responde a um email.
    
    Body:
    {
        "account_id": "id_conta_email",
        "reply_body": "Corpo da resposta",
        "reply_all": false // opcional, default false
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.reply_email(
            account_id=reply_data.get("account_id", ""),
            email_id=email_id,
            reply_body=reply_data.get("reply_body", ""),
            reply_all=reply_data.get("reply_all", False)
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao responder email")
            )
            
    except Exception as e:
        logger.error(f"Erro ao responder email {email_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/emails/{email_id}")
async def delete_email(
    email_id: str,
    account_id: str = Query(..., description="ID da conta de email"),
    permanent: bool = Query(False, description="Deletar permanentemente"),
    current_user = Depends(get_current_user)
):
    """
    Deleta um email (move para lixeira ou delete permanente).
    """
    try:
        service = get_unipile_app_service()
        result = await service.delete_email(
            account_id=account_id,
            email_id=email_id,
            permanent=permanent
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao deletar email")
            )
            
    except Exception as e:
        logger.error(f"Erro ao deletar email {email_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/emails/{email_id}/archive")
async def archive_email(
    email_id: str,
    account_data: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Arquiva um email.
    
    Body:
    {
        "account_id": "id_conta_email"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.archive_email(
            account_id=account_data.get("account_id", ""),
            email_id=email_id
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao arquivar email")
            )
            
    except Exception as e:
        logger.error(f"Erro ao arquivar email {email_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/emails/drafts")
async def create_email_draft(
    draft_data: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Cria um rascunho de email.
    
    Body:
    {
        "account_id": "id_conta_email",
        "to": "destinatario@email.com",
        "subject": "Assunto do email",
        "body": "Corpo do email",
        "attachments": ["url1", "url2"] // opcional
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.create_draft(
            account_id=draft_data.get("account_id", ""),
            draft_data=draft_data
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=201,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao criar rascunho")
            )
            
    except Exception as e:
        logger.error(f"Erro ao criar rascunho: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/emails/{email_id}/move")
async def move_email(
    email_id: str,
    move_data: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Move um email entre pastas.
    
    Body:
    {
        "account_id": "id_conta_email",
        "folder_id": "id_pasta_destino"
    }
    """
    try:
        service = get_unipile_app_service()
        result = await service.move_email(
            account_id=move_data.get("account_id", ""),
            email_id=email_id,
            folder_id=move_data.get("folder_id", "")
        )
        
        if result.get("success"):
            return JSONResponse(
                status_code=200,
                content=result
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=result.get("error", "Erro ao mover email")
            )
            
    except Exception as e:
        logger.error(f"Erro ao mover email {email_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== ENDPOINTS DE TESTE E MIGRAÇÃO =====

@router.post("/test/migration")
async def test_migration_compatibility(
    test_case: str = Body(..., embed=True, description="Caso de teste: 'calendar', 'email', 'webhook'"),
    current_user = Depends(get_current_user)
):
    """
    Testa compatibilidade entre serviços para casos específicos.
    """
    try:
        service = get_unipile_service()
        
        # Executar teste baseado no caso
        if test_case == "calendar":
            # Testar listagem de eventos
            connections = await service.list_accounts()
            if connections:
                events = await service.list_calendar_events(connections[0].id if hasattr(connections[0], 'id') else connections[0]["id"])
                test_result = {"events_count": len(events), "success": True}
            else:
                test_result = {"error": "Nenhuma conexão disponível", "success": False}
                
        elif test_case == "email":
            # Testar listagem de emails
            connections = await service.list_accounts()
            if connections:
                emails = await service.list_emails(connections[0].id if hasattr(connections[0], 'id') else connections[0]["id"])
                test_result = {"emails_count": len(emails), "success": True}
            else:
                test_result = {"error": "Nenhuma conexão disponível", "success": False}
                
        elif test_case == "webhook":
            # Testar health check (mais seguro)
            health = await service.health_check()
            test_result = {"health_status": health.get("status"), "success": health.get("status") in ["healthy", "ok"]}
            
        else:
            raise HTTPException(status_code=400, detail=f"Caso de teste inválido: {test_case}")
        
        return JSONResponse(content={
            "test_case": test_case,
            "result": test_result,
            "timestamp": datetime.now().isoformat()
        })
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no teste de migração: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/migration/status")
async def get_migration_status(current_user = Depends(get_current_user)):
    """
    Retorna status detalhado da migração.
    """
    try:
        service = get_unipile_service()
        health = await service.health_check()
        metrics = await service.get_service_metrics()
        
        # Determinar status da migração
        services_available = health.get("services_available", {})
        sdk_available = services_available.get("sdk_official", False)
        wrapper_available = services_available.get("wrapper_nodejs", False)
        
        if sdk_available and wrapper_available:
            migration_phase = "compatibility_active"
        elif sdk_available:
            migration_phase = "sdk_only"
        elif wrapper_available:
            migration_phase = "wrapper_only"
        else:
            migration_phase = "no_services"
        
        return JSONResponse(content={
            "migration_phase": migration_phase,
            "services_status": services_available,
            "current_service": health.get("service_used"),
            "health": health,
            "metrics": metrics,
            "recommendations": {
                "next_step": "Migração gradual em progresso" if migration_phase == "compatibility_active" else "Verificar configuração",
                "can_migrate": sdk_available,
                "fallback_available": wrapper_available
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Erro ao obter status da migração: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 