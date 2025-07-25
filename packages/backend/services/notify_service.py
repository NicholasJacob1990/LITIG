"""
Serviço para enviar notificações aos advogados (Push e E-mail).
v2.3: Migrado de OneSignal para Expo Push Notifications para unificar com o frontend.
"""
import asyncio
import json
import logging
import os
from typing import Any, Dict, List

import httpx
from dotenv import load_dotenv
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from exponent_server_sdk import (
    DeviceNotRegisteredError,
    PushClient,
    PushMessage,
    PushServerError,
    PushTicketError,
)

from services.cache_service_simple import simple_cache_service as cache_service
from redis import Redis
from supabase import Client, create_client

# --- Configuração ---
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")
FROM_EMAIL = os.getenv("FROM_EMAIL", "noreply@litgo.com")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
EXPO_TIMEOUT = int(os.getenv("EXPO_TIMEOUT", "15"))
SENDGRID_TIMEOUT = int(os.getenv("SENDGRID_TIMEOUT", "15"))

# Configurar logging
logger = logging.getLogger(__name__)

redis_client = Redis.from_url(REDIS_URL)


def get_supabase_client() -> Client:
    """Cria e retorna um cliente Supabase."""
    if not all([SUPABASE_URL, SUPABASE_SERVICE_KEY]):
        raise ValueError("Variáveis de ambiente do Supabase não configuradas.")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


async def send_notifications_to_lawyers(lawyer_ids: List[str], payload: Dict[str, Any]):
    """
    Envia notificações push para uma lista de advogados usando Expo.
    v2.2: Adiciona guard-rail para evitar spam de notificações.
    v2.3: Adaptado para Expo Push Notifications.
    """
    if not lawyer_ids:
        return

    # 1. Filtrar advogados que já foram notificados recentemente
    eligible_lawyer_ids = []
    for lawyer_id in lawyer_ids:
        cache_key = f"notification_cooldown:{lawyer_id}"
        is_on_cooldown = await cache_service.get(cache_key)
        if not is_on_cooldown:
            eligible_lawyer_ids.append(lawyer_id)

    if not eligible_lawyer_ids:
        logger.info("Nenhum advogado elegível para notificação (todos em cooldown).")
        return

    # 2. Buscar dados dos advogados elegíveis
    supabase = get_supabase_client()
    try:
        lawyers_response = supabase.table("profiles") \
            .select("id, expo_push_token, email") \
            .in_("id", eligible_lawyer_ids) \
            .execute()

        lawyers_data = lawyers_response.data
        if not lawyers_data:
            return

        # 3. Preparar e enviar notificações
        tasks = []
        for lawyer in lawyers_data:
            push_token = lawyer.get("expo_push_token")
            email = lawyer.get("email")
            
            title = payload.get("headline", "Novo Caso Disponível")
            message = payload.get("summary", "Um novo caso compatível com seu perfil está disponível.")
            extra_data = payload.get("data", {})

            if push_token:
                tasks.append(send_push_notification(push_token, title, message, extra_data))
            elif email:
                tasks.append(send_email_notification(email, title, message))

        if tasks:
            await asyncio.gather(*tasks)

        # 4. Marcar advogados notificados no cache
        for lawyer_id in eligible_lawyer_ids:
            cache_key = f"notification_cooldown:{lawyer_id}"
            # 5 minutos de cooldown
            await cache_service.set(cache_key, {"notified": True}, ttl=300)

        logger.info(f"Notificações enviadas para {len(eligible_lawyer_ids)} advogados.")

    except Exception as e:
        logger.error(f"Erro ao buscar dados dos advogados para notificação: {e}")


async def send_notification_to_client(client_id: str, notification_type: str, payload: Dict[str, Any]):
    """
    Envia notificação push para um cliente específico.
    
    Args:
        client_id: ID do cliente
        notification_type: Tipo da notificação (caseUpdate, matchesFound, etc.)
        payload: Dados da notificação
    """
    if not client_id:
        logger.warning("Client ID não fornecido para notificação")
        return False

    # 1. Verificar cooldown para evitar spam
    cache_key = f"client_notification_cooldown:{client_id}:{notification_type}"
    is_on_cooldown = await cache_service.get(cache_key)
    if is_on_cooldown:
        logger.info(f"Cliente {client_id} em cooldown para notificação {notification_type}")
        return False

    # 2. Buscar dados do cliente
    supabase = get_supabase_client()
    try:
        client_response = supabase.table("profiles") \
            .select("id, expo_push_token, email, full_name") \
            .eq("id", client_id) \
            .single() \
            .execute()

        client_data = client_response.data
        if not client_data:
            logger.warning(f"Cliente {client_id} não encontrado")
            return False

        push_token = client_data.get("expo_push_token")
        email = client_data.get("email")
        
        title = payload.get("title", "Nova Atualização")
        message = payload.get("body", "Temos novidades sobre seu caso.")
        extra_data = payload.get("data", {})

        # 3. Enviar notificação
        success = False
        if push_token:
            success = await send_push_notification(push_token, title, message, extra_data)
        elif email:
            success = await send_email_notification(email, title, message)

        # 4. Marcar cooldown se enviado com sucesso
        if success:
            # Cooldown de 2 minutos para clientes (menos que advogados)
            await cache_service.set(cache_key, {"notified": True}, ttl=120)
            logger.info(f"Notificação {notification_type} enviada para cliente {client_id}")

        return success

    except Exception as e:
        logger.error(f"Erro ao enviar notificação para cliente {client_id}: {e}")
        return False


async def send_push_notification(token: str, title: str, message: str, data: dict = None) -> bool:
    """Envia uma notificação push via Expo."""
    try:
        # Verifica se o token é válido para Expo
        if not PushClient.is_exponent_push_token(token):
            logger.warning(f"Token '{token}' não é um token válido do Expo. Notificação não enviada.")
            return False

        push_client = PushClient()
        push_message = PushMessage(
            to=token,
            title=title,
            body=message,
            data=data or {},
            sound="default",
            priority="high",
            channel_id="default"
        )
        
        response = push_client.publish(push_message)
        response.validate_response()
        logger.info(f"Push notification sent to token {token[:10]}... Ticket: {response.id}")
        return True

    except DeviceNotRegisteredError:
        logger.warning(f"Dispositivo com token {token[:10]}... não está mais registrado. É preciso remover o token do banco.")
        # TODO: Implementar lógica para remover o token do banco de dados.
        return False
    except PushServerError as e:
        logger.error(f"Erro no servidor do Expo: {e}")
        return False
    except PushTicketError as e:
        logger.error(f"Erro no ticket de push do Expo: {e}")
        return False
    except Exception as e:
        logger.error(f"Erro inesperado ao enviar notificação push via Expo: {e}")
        return False


async def _send_email_notification(
        supabase: Client, email: str, payload: Dict[str, Any]):
    """Envia e-mail usando SendGrid como fallback quando Push não está disponível."""
    sendgrid_api_key = os.getenv("SENDGRID_API_KEY")
    from_email = os.getenv("SENDGRID_FROM_EMAIL", "no-reply@litgo.com")

    if not sendgrid_api_key:
        logger.error("SENDGRID_API_KEY não configurada – e-mail não enviado.")
        return

    subject = payload.get("headline", "Novo caso disponível na LITGO")
    content_text = payload.get("summary", "Um novo caso está disponível para você.")

    message = Mail(
        from_email=from_email,
        to_emails=email,
        subject=subject,
        plain_text_content=content_text,
    )

    try:
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(None, SendGridAPIClient(sendgrid_api_key).send, message)
        logger.info(f"E-mail enviado para {email}")
    except Exception as e:
        logger.error(f"Erro ao enviar e-mail para {email}: {e}")


# Funções públicas para compatibilidade com o código existente
async def send_push_notification_legacy(
        user_id: str, title: str, message: str, data: dict = None) -> bool:
    """Função legada do OneSignal, mantida para referência e eventual remoção."""
    logger.warning("A função 'send_push_notification_legacy' (OneSignal) foi chamada, mas está desativada. Use a nova implementação Expo.")
    return False

async def send_email_notification(email: str, subject: str, content: str) -> bool:
    """Envia notificação por email via SendGrid"""
    try:
        async with httpx.AsyncClient(timeout=SENDGRID_TIMEOUT) as client:
            headers = {
                "Authorization": f"Bearer {SENDGRID_API_KEY}",
                "Content-Type": "application/json"
            }

            message = {
                "personalizations": [{
                    "to": [{"email": email}]
                }],
                "from": {"email": FROM_EMAIL, "name": "LITGO"},
                "subject": subject,
                "content": [{
                    "type": "text/html",
                    "value": content
                }]
            }

            response = await client.post(
                "https://api.sendgrid.com/v3/mail/send",
                headers=headers,
                json=message
            )

            if response.status_code in [200, 202]:
                logger.info(f"Email sent to {email}")
                return True
            else:
                logger.error(
                    f"Failed to send email: {response.status_code} - {response.text}")
                return False

    except Exception as e:
        logger.error(f"Error sending email: {e}")
        return False
