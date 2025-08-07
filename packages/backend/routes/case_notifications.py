"""
Rotas para notificações de casos com envio automático de emails.
"""
import logging
from typing import Dict, Any, Optional
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
from services.case_notification_email_service import case_notification_email_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/case-notifications", tags=["case-notifications"])

class CaseNotificationRequest(BaseModel):
    """
    Schema para requisição de notificação de caso.
    """
    notification_type: str
    user_email: EmailStr
    user_name: str
    case_data: Dict[str, Any]
    notification_data: Dict[str, Any] = {}
    send_email: bool = True  # Permite desabilitar email se necessário

class CaseNotificationResponse(BaseModel):
    """
    Schema para resposta de notificação.
    """
    success: bool
    message: str
    email_sent: bool = False

@router.post("/send", response_model=CaseNotificationResponse)
async def send_case_notification(
    request: CaseNotificationRequest,
    background_tasks: BackgroundTasks
):
    """
    Endpoint para envio de notificações de casos com email automático.
    """
    try:
        logger.info(f"Recebendo notificação de caso - Tipo: {request.notification_type}, "
                   f"Email: {request.user_email}")
        
        if not request.send_email:
            return CaseNotificationResponse(
                success=True,
                message="Notificação processada sem envio de email",
                email_sent=False
            )
        
        # Enviar email em background para não bloquear a resposta
        background_tasks.add_task(
            _send_notification_email,
            request.notification_type,
            request.user_email,
            request.user_name,
            request.case_data,
            request.notification_data
        )
        
        return CaseNotificationResponse(
            success=True,
            message="Notificação processada e email será enviado em breve",
            email_sent=True
        )
        
    except Exception as e:
        logger.error(f"Erro ao processar notificação de caso: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao processar notificação: {str(e)}"
        )

async def _send_notification_email(
    notification_type: str,
    user_email: str,
    user_name: str,
    case_data: Dict[str, Any],
    notification_data: Dict[str, Any]
):
    """
    Função auxiliar para envio de email em background.
    """
    try:
        success = await case_notification_email_service.send_case_notification_email(
            notification_type=notification_type,
            user_email=user_email,
            user_name=user_name,
            case_data=case_data,
            notification_data=notification_data
        )
        
        if success:
            logger.info(f"Email de notificação enviado com sucesso para {user_email}")
        else:
            logger.error(f"Falha ao enviar email de notificação para {user_email}")
            
    except Exception as e:
        logger.error(f"Erro no envio de email em background: {e}")

# Endpoint de teste
@router.post("/test")
async def test_case_notification():
    """
    Endpoint para testar o sistema de notificações (apenas desenvolvimento).
    """
    test_request = CaseNotificationRequest(
        notification_type="caseAssigned",
        user_email="test@litig.com",
        user_name="Advogado Teste",
        case_data={
            "id": "case_123",
            "title": "Caso de Teste",
            "client_name": "Cliente Teste"
        },
        notification_data={
            "assigned_date": "2024-01-01"
        }
    )
    
    try:
        success = await case_notification_email_service.send_case_notification_email(
            notification_type=test_request.notification_type,
            user_email=test_request.user_email,
            user_name=test_request.user_name,
            case_data=test_request.case_data,
            notification_data=test_request.notification_data
        )
        
        return {
            "success": success,
            "message": "Email de teste enviado" if success else "Falha no envio do email de teste"
        }
        
    except Exception as e:
        logger.error(f"Erro no teste de notificação: {e}")
        raise HTTPException(status_code=500, detail=str(e))