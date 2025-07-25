# -*- coding: utf-8 -*-
"""
Notification Service - Sistema de Notificações Push
==================================================

Serviço para envio de notificações push para mensagens unificadas,
lembretes de calendário e eventos importantes do sistema LITIG-1.
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import json
import os

import aiohttp
from dataclasses import dataclass, field

import sendgrid
from sendgrid.helpers.mail import Mail, Email, To, Content
from twilio.rest import Client as TwilioClient
from jinja2 import Environment, BaseLoader

from config import get_supabase_client

logger = logging.getLogger(__name__)


@dataclass
class PushToken:
    """Representação de um token push."""
    user_id: str
    device_type: str  # ios, android, web
    push_token: str
    is_active: bool = True
    last_used_at: Optional[datetime] = None


@dataclass
class NotificationPreferences:
    """Preferências de notificação do usuário."""
    user_id: str
    email_notifications: bool = True
    push_notifications: bool = True
    linkedin_notifications: bool = True
    instagram_notifications: bool = True
    whatsapp_notifications: bool = True
    gmail_notifications: bool = True
    outlook_notifications: bool = True
    calendar_reminders: bool = True
    quiet_hours_start: Optional[str] = None  # HH:MM
    quiet_hours_end: Optional[str] = None    # HH:MM
    timezone: str = "America/Sao_Paulo"


class NotificationService:
    """Serviço para envio de notificações push e por email."""
    
    def __init__(self):
        self.expo_api_url = "https://exp.host/--/api/v2/push/send"
        self.fcm_api_url = "https://fcm.googleapis.com/fcm/send"
        self.expo_access_token = os.getenv("EXPO_ACCESS_TOKEN")
        self.fcm_server_key = os.getenv("FCM_SERVER_KEY")
        self.logger = logging.getLogger(__name__)
    
    # ===============================
    # NOTIFICAÇÕES DE MENSAGENS
    # ===============================
    
    async def send_message_notification(self, user_id: str, message_data: Dict[str, Any]) -> bool:
        """
        Envia notificação de nova mensagem unificada.
        
        Args:
            user_id: ID do usuário destinatário
            message_data: Dados da mensagem (sender_name, content, provider, etc.)
        """
        try:
            # Verifica preferências do usuário
            preferences = await self._get_user_preferences(user_id)
            if not preferences.push_notifications:
                return False
            
            # Verifica se deve notificar para este provedor
            if not self._should_notify_for_provider(preferences, message_data.get("provider")):
                return False
            
            # Verifica horário silencioso
            if self._is_quiet_hours(preferences):
                return False
            
            # Busca tokens do usuário
            tokens = await self._get_user_push_tokens(user_id)
            if not tokens:
                return False
            
            # Cria notificação
            notification = {
                "title": self._format_message_title(message_data),
                "body": self._format_message_body(message_data),
                "data": {
                    "type": "new_message",
                    "chat_id": message_data.get("chat_id"),
                    "provider": message_data.get("provider"),
                    "sender_id": message_data.get("sender_id"),
                    "message_id": message_data.get("message_id")
                },
                "sound": "default",
                "badge": await self._get_total_unread_count(user_id)
            }
            
            # Envia para todos os dispositivos
            success_count = 0
            for token in tokens:
                if await self._send_push_notification(token, notification):
                    success_count += 1
            
            self.logger.info(f"Notificação de mensagem enviada para {success_count}/{len(tokens)} dispositivos")
            return success_count > 0
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar notificação de mensagem: {e}")
            return False
    
    async def send_calendar_reminder(self, user_id: str, event_data: Dict[str, Any]) -> bool:
        """
        Envia lembrete de evento de calendário.
        
        Args:
            user_id: ID do usuário
            event_data: Dados do evento (title, start_time, location, etc.)
        """
        try:
            # Verifica preferências
            preferences = await self._get_user_preferences(user_id)
            if not preferences.calendar_reminders:
                return False
            
            # Verifica horário silencioso (lembretes ignoram horário silencioso)
            
            # Busca tokens
            tokens = await self._get_user_push_tokens(user_id)
            if not tokens:
                return False
            
            # Cria notificação de lembrete
            notification = {
                "title": "📅 Lembrete de Evento",
                "body": self._format_calendar_reminder(event_data),
                "data": {
                    "type": "calendar_reminder",
                    "event_id": event_data.get("id"),
                    "start_time": event_data.get("start_time").isoformat() if event_data.get("start_time") else None
                },
                "sound": "default",
                "priority": "high",
                "category": "calendar_reminder"
            }
            
            # Envia para todos os dispositivos
            success_count = 0
            for token in tokens:
                if await self._send_push_notification(token, notification):
                    success_count += 1
            
            self.logger.info(f"Lembrete de calendário enviado para {success_count}/{len(tokens)} dispositivos")
            return success_count > 0
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar lembrete de calendário: {e}")
            return False
    
    async def send_legal_deadline_reminder(self, user_id: str, deadline_data: Dict[str, Any]) -> bool:
        """
        Envia lembrete de prazo jurídico crítico.
        
        Args:
            user_id: ID do usuário
            deadline_data: Dados do prazo (case_number, deadline_type, due_date, etc.)
        """
        try:
            # Busca tokens (prazos jurídicos sempre são enviados)
            tokens = await self._get_user_push_tokens(user_id)
            if not tokens:
                return False
            
            urgency = deadline_data.get("urgency", "media")
            
            # Cria notificação crítica
            notification = {
                "title": f"⚖️ Prazo Jurídico - {urgency.upper()}",
                "body": self._format_legal_deadline(deadline_data),
                "data": {
                    "type": "legal_deadline",
                    "case_id": deadline_data.get("case_id"),
                    "deadline_type": deadline_data.get("deadline_type"),
                    "due_date": deadline_data.get("due_date").isoformat() if deadline_data.get("due_date") else None,
                    "urgency": urgency
                },
                "sound": "default",
                "priority": "high",
                "category": "legal_deadline",
                "color": self._get_urgency_color(urgency)
            }
            
            # Envia para todos os dispositivos
            success_count = 0
            for token in tokens:
                if await self._send_push_notification(token, notification):
                    success_count += 1
            
            self.logger.info(f"Lembrete de prazo jurídico enviado para {success_count}/{len(tokens)} dispositivos")
            return success_count > 0
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar lembrete de prazo: {e}")
            return False
    
    async def send_case_update_notification(self, user_id: str, case_data: Dict[str, Any]) -> bool:
        """
        Envia notificação de atualização de caso.
        
        Args:
            user_id: ID do usuário
            case_data: Dados da atualização (case_number, update_type, description, etc.)
        """
        try:
            preferences = await self._get_user_preferences(user_id)
            if not preferences.push_notifications:
                return False
            
            tokens = await self._get_user_push_tokens(user_id)
            if not tokens:
                return False
            
            notification = {
                "title": f"📋 Atualização - Caso {case_data.get('case_number')}",
                "body": self._format_case_update(case_data),
                "data": {
                    "type": "case_update",
                    "case_id": case_data.get("case_id"),
                    "update_type": case_data.get("update_type"),
                    "case_number": case_data.get("case_number")
                },
                "sound": "default",
                "category": "case_update"
            }
            
            success_count = 0
            for token in tokens:
                if await self._send_push_notification(token, notification):
                    success_count += 1
            
            self.logger.info(f"Notificação de caso enviada para {success_count}/{len(tokens)} dispositivos")
            return success_count > 0
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar notificação de caso: {e}")
            return False
    
    # ===============================
    # GERENCIAMENTO DE TOKENS
    # ===============================
    
    async def register_push_token(self, user_id: str, device_type: str, push_token: str) -> bool:
        """
        Registra novo token push para um usuário.
        
        Args:
            user_id: ID do usuário
            device_type: Tipo do dispositivo (ios, android, web)
            push_token: Token push do dispositivo
        """
        try:
            # TODO: Salvar token no banco de dados
            token_data = {
                "user_id": user_id,
                "device_type": device_type,
                "push_token": push_token,
                "is_active": True,
                "last_used_at": datetime.now(),
                "created_at": datetime.now()
            }
            
            await self._save_push_token(token_data)
            
            self.logger.info(f"Token push registrado para usuário {user_id}: {device_type}")
            return True
            
        except Exception as e:
            self.logger.error(f"Erro ao registrar token push: {e}")
            return False
    
    async def remove_push_token(self, user_id: str, push_token: str) -> bool:
        """Remove token push específico."""
        try:
            # TODO: Marcar token como inativo no banco
            await self._deactivate_push_token(user_id, push_token)
            
            self.logger.info(f"Token push removido para usuário {user_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Erro ao remover token push: {e}")
            return False
    
    async def update_notification_preferences(self, user_id: str, preferences: Dict[str, Any]) -> bool:
        """
        Atualiza preferências de notificação do usuário.
        
        Args:
            user_id: ID do usuário
            preferences: Novas preferências
        """
        try:
            # TODO: Salvar preferências no banco
            preferences_data = {
                "user_id": user_id,
                "email_notifications": preferences.get("email_notifications", True),
                "push_notifications": preferences.get("push_notifications", True),
                "linkedin_notifications": preferences.get("linkedin_notifications", True),
                "instagram_notifications": preferences.get("instagram_notifications", True),
                "whatsapp_notifications": preferences.get("whatsapp_notifications", True),
                "gmail_notifications": preferences.get("gmail_notifications", True),
                "outlook_notifications": preferences.get("outlook_notifications", True),
                "calendar_reminders": preferences.get("calendar_reminders", True),
                "quiet_hours_start": preferences.get("quiet_hours_start"),
                "quiet_hours_end": preferences.get("quiet_hours_end"),
                "timezone": preferences.get("timezone", "America/Sao_Paulo"),
                "updated_at": datetime.now()
            }
            
            await self._save_notification_preferences(preferences_data)
            
            self.logger.info(f"Preferências de notificação atualizadas para usuário {user_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Erro ao atualizar preferências: {e}")
            return False
    
    # ===============================
    # ENVIO DE NOTIFICAÇÕES
    # ===============================
    
    async def _send_push_notification(self, token: PushToken, notification: Dict[str, Any]) -> bool:
        """Envia notificação push para um token específico."""
        try:
            if token.device_type in ["ios", "android"]:
                # Usa Expo Push Notifications
                return await self._send_expo_notification(token, notification)
            elif token.device_type == "web":
                # Usa FCM para web
                return await self._send_fcm_notification(token, notification)
            else:
                self.logger.warning(f"Tipo de dispositivo não suportado: {token.device_type}")
                return False
                
        except Exception as e:
            self.logger.error(f"Erro ao enviar notificação para {token.push_token}: {e}")
            return False
    
    async def _send_expo_notification(self, token: PushToken, notification: Dict[str, Any]) -> bool:
        """Envia notificação via Expo Push Notifications."""
        try:
            if not self.expo_access_token:
                self.logger.warning("Expo access token não configurado")
                return False
            
            payload = {
                "to": token.push_token,
                "title": notification["title"],
                "body": notification["body"],
                "data": notification.get("data", {}),
                "sound": notification.get("sound", "default"),
                "badge": notification.get("badge"),
                "priority": notification.get("priority", "normal"),
                "categoryId": notification.get("category")
            }
            
            headers = {
                "Accept": "application/json",
                "Accept-encoding": "gzip, deflate",
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.expo_access_token}"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.expo_api_url,
                    json=payload,
                    headers=headers,
                    timeout=10
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        if result.get("data", {}).get("status") == "ok":
                            return True
                        else:
                            self.logger.error(f"Erro na resposta Expo: {result}")
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro HTTP Expo {response.status}: {error_text}")
            
            return False
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar notificação Expo: {e}")
            return False
    
    async def _send_fcm_notification(self, token: PushToken, notification: Dict[str, Any]) -> bool:
        """Envia notificação via Firebase Cloud Messaging."""
        try:
            if not self.fcm_server_key:
                self.logger.warning("FCM server key não configurado")
                return False
            
            payload = {
                "to": token.push_token,
                "notification": {
                    "title": notification["title"],
                    "body": notification["body"],
                    "icon": "/icon-192x192.png",
                    "badge": "/badge-72x72.png",
                    "tag": notification.get("category", "default")
                },
                "data": notification.get("data", {}),
                "webpush": {
                    "headers": {
                        "Urgency": notification.get("priority", "normal")
                    },
                    "notification": {
                        "title": notification["title"],
                        "body": notification["body"],
                        "icon": "/icon-192x192.png",
                        "badge": "/badge-72x72.png",
                        "tag": notification.get("category", "default"),
                        "requireInteraction": notification.get("priority") == "high"
                    }
                }
            }
            
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"key={self.fcm_server_key}"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.fcm_api_url,
                    json=payload,
                    headers=headers,
                    timeout=10
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        if result.get("success", 0) > 0:
                            return True
                        else:
                            self.logger.error(f"Erro na resposta FCM: {result}")
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro HTTP FCM {response.status}: {error_text}")
            
            return False
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar notificação FCM: {e}")
            return False
    
    # ===============================
    # FORMATAÇÃO DE MENSAGENS
    # ===============================
    
    def _format_message_title(self, message_data: Dict[str, Any]) -> str:
        """Formata título da notificação de mensagem."""
        sender_name = message_data.get("sender_name", "Alguém")
        provider = message_data.get("provider", "").lower()
        
        provider_emojis = {
            "linkedin": "💼",
            "instagram": "📸",
            "whatsapp": "📱",
            "gmail": "📧",
            "outlook": "📩"
        }
        
        emoji = provider_emojis.get(provider, "💬")
        return f"{emoji} {sender_name}"
    
    def _format_message_body(self, message_data: Dict[str, Any]) -> str:
        """Formata corpo da notificação de mensagem."""
        content = message_data.get("content", "")
        
        # Limita tamanho da mensagem
        if len(content) > 100:
            content = content[:97] + "..."
        
        return content
    
    def _format_calendar_reminder(self, event_data: Dict[str, Any]) -> str:
        """Formata lembrete de calendário."""
        title = event_data.get("title", "Evento")
        start_time = event_data.get("start_time")
        
        if start_time:
            time_str = start_time.strftime("%H:%M")
            return f"{title} às {time_str}"
        
        return title
    
    def _format_legal_deadline(self, deadline_data: Dict[str, Any]) -> str:
        """Formata lembrete de prazo jurídico."""
        case_number = deadline_data.get("case_number", "")
        deadline_type = deadline_data.get("deadline_type", "Prazo")
        due_date = deadline_data.get("due_date")
        
        if due_date:
            days_left = (due_date.date() - datetime.now().date()).days
            if days_left == 0:
                time_info = "hoje"
            elif days_left == 1:
                time_info = "amanhã"
            else:
                time_info = f"em {days_left} dias"
            
            return f"{deadline_type} - Processo {case_number} vence {time_info}"
        
        return f"{deadline_type} - Processo {case_number}"
    
    def _format_case_update(self, case_data: Dict[str, Any]) -> str:
        """Formata notificação de atualização de caso."""
        update_type = case_data.get("update_type", "Atualização")
        description = case_data.get("description", "")
        
        if description and len(description) > 80:
            description = description[:77] + "..."
        
        return f"{update_type}: {description}" if description else update_type
    
    def _get_urgency_color(self, urgency: str) -> str:
        """Retorna cor baseada na urgência."""
        colors = {
            "baixa": "#4CAF50",    # Verde
            "media": "#FF9800",    # Laranja
            "alta": "#F44336",     # Vermelho
            "critica": "#9C27B0"   # Roxo
        }
        return colors.get(urgency.lower(), "#2196F3")  # Azul padrão
    
    # ===============================
    # VERIFICAÇÕES E VALIDAÇÕES
    # ===============================
    
    def _should_notify_for_provider(self, preferences: NotificationPreferences, provider: str) -> bool:
        """Verifica se deve notificar para o provedor específico."""
        if not provider:
            return True
        
        provider_map = {
            "linkedin": preferences.linkedin_notifications,
            "instagram": preferences.instagram_notifications,
            "whatsapp": preferences.whatsapp_notifications,
            "gmail": preferences.gmail_notifications,
            "outlook": preferences.outlook_notifications
        }
        
        return provider_map.get(provider.lower(), True)
    
    def _is_quiet_hours(self, preferences: NotificationPreferences) -> bool:
        """Verifica se está no horário silencioso."""
        if not preferences.quiet_hours_start or not preferences.quiet_hours_end:
            return False
        
        try:
            from datetime import time
            
            now = datetime.now().time()
            start = datetime.strptime(preferences.quiet_hours_start, "%H:%M").time()
            end = datetime.strptime(preferences.quiet_hours_end, "%H:%M").time()
            
            if start <= end:
                return start <= now <= end
            else:
                # Horário que cruza meia-noite
                return now >= start or now <= end
                
        except:
            return False
    
    # ===============================
    # FUNÇÕES DE BANCO DE DADOS (TODO)
    # ===============================
    
    async def _get_user_push_tokens(self, user_id: str) -> List[PushToken]:
        """Busca tokens push ativos do usuário."""
        # TODO: Implementar busca no banco
        return [
            PushToken(
                user_id=user_id,
                device_type="ios",
                push_token="ExponentPushToken[mock_token_123]",
                is_active=True,
                last_used_at=datetime.now()
            )
        ]
    
    async def _get_user_preferences(self, user_id: str) -> NotificationPreferences:
        """Busca preferências de notificação do usuário."""
        # TODO: Implementar busca no banco
        return NotificationPreferences(user_id=user_id)
    
    async def _get_total_unread_count(self, user_id: str) -> int:
        """Busca total de mensagens não lidas."""
        # TODO: Implementar busca no banco
        return 5
    
    async def _save_push_token(self, token_data: Dict[str, Any]):
        """Salva token push no banco."""
        # TODO: Implementar
        pass
    
    async def _deactivate_push_token(self, user_id: str, push_token: str):
        """Desativa token push no banco."""
        # TODO: Implementar
        pass
    
    async def _save_notification_preferences(self, preferences_data: Dict[str, Any]):
        """Salva preferências no banco."""
        # TODO: Implementar
        pass
    
    # ===============================
    # HEALTH CHECK
    # ===============================
    
    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde do serviço de notificações."""
        try:
            return {
                "status": "healthy",
                "expo_configured": bool(self.expo_access_token),
                "fcm_configured": bool(self.fcm_server_key),
                "supported_platforms": ["ios", "android", "web"],
                "features": [
                    "message_notifications",
                    "calendar_reminders", 
                    "legal_deadlines",
                    "case_updates",
                    "quiet_hours",
                    "provider_filtering"
                ],
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

"""
Notification Service for Billing Events
Serviço de notificações para eventos de billing (upgrade/downgrade)
"""
import os
import logging
from typing import Dict, Any, Optional
from datetime import datetime
import asyncio
from dataclasses import dataclass

import sendgrid
from sendgrid.helpers.mail import Mail, Email, To, Content
from twilio.rest import Client as TwilioClient
from jinja2 import Environment, BaseLoader

from config import get_supabase_client

logger = logging.getLogger(__name__)


@dataclass
class NotificationData:
    """Dados para notificação."""
    user_id: str
    user_name: str
    user_email: str
    user_phone: Optional[str]
    entity_type: str
    entity_id: str
    old_plan: str
    new_plan: str
    action: str  # 'upgrade', 'downgrade', 'cancellation'
    amount_cents: Optional[int] = None
    billing_date: Optional[datetime] = None


class NotificationService:
    """Serviço para envio de notificações de billing."""
    
    def __init__(self):
        self.supabase = get_supabase_client()
        
        # Configuração SendGrid
        self.sendgrid_client = sendgrid.SendGridAPIClient(
            api_key=os.getenv("SENDGRID_API_KEY")
        )
        self.from_email = os.getenv("FROM_EMAIL", "billing@litig.com.br")
        
        # Configuração Twilio
        self.twilio_client = TwilioClient(
            os.getenv("TWILIO_ACCOUNT_SID"),
            os.getenv("TWILIO_AUTH_TOKEN")
        )
        self.twilio_phone = os.getenv("TWILIO_PHONE_NUMBER", "+5511999999999")
        
        # Templates de email
        self.jinja_env = Environment(loader=BaseLoader())
    
    async def send_plan_change_notification(self, notification_data: NotificationData) -> bool:
        """Envia notificação completa (email + SMS) para mudança de plano."""
        try:
            # Enviar email e SMS em paralelo
            email_task = self._send_email_notification(notification_data)
            sms_task = self._send_sms_notification(notification_data)
            
            # Analytics tracking
            analytics_task = self._track_billing_event(notification_data)
            
            # Executar todas as tarefas
            results = await asyncio.gather(
                email_task, 
                sms_task, 
                analytics_task,
                return_exceptions=True
            )
            
            # Log resultados
            email_success, sms_success, analytics_success = results
            
            logger.info(f"Notification sent for {notification_data.user_id}: "
                       f"email={email_success}, sms={sms_success}, analytics={analytics_success}")
            
            return email_success or sms_success  # Sucesso se pelo menos um foi enviado
            
        except Exception as e:
            logger.error(f"Error sending plan change notification: {e}")
            return False
    
    async def _send_email_notification(self, data: NotificationData) -> bool:
        """Envia notificação por email."""
        try:
            # Selecionar template baseado na ação
            template_data = self._get_email_template_data(data)
            
            # Renderizar template
            html_content = self._render_email_template(template_data)
            
            # Criar email
            from_email = Email(self.from_email, "LITIG - Plataforma Jurídica")
            to_email = To(data.user_email, data.user_name)
            subject = template_data["subject"]
            content = Content("text/html", html_content)
            
            mail = Mail(from_email, to_email, subject, content)
            
            # Enviar via SendGrid
            response = self.sendgrid_client.send(message=mail)
            
            if response.status_code in [200, 202]:
                logger.info(f"Email sent successfully to {data.user_email}")
                return True
            else:
                logger.error(f"Failed to send email: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending email notification: {e}")
            return False
    
    async def _send_sms_notification(self, data: NotificationData) -> bool:
        """Envia notificação por SMS."""
        try:
            if not data.user_phone:
                logger.info(f"No phone number for user {data.user_id}, skipping SMS")
                return True  # Não é erro se não tem telefone
            
            # Gerar mensagem SMS
            sms_message = self._generate_sms_message(data)
            
            # Enviar via Twilio
            message = self.twilio_client.messages.create(
                body=sms_message,
                from_=self.twilio_phone,
                to=data.user_phone
            )
            
            if message.status in ['queued', 'sent', 'delivered']:
                logger.info(f"SMS sent successfully to {data.user_phone}")
                return True
            else:
                logger.error(f"Failed to send SMS: {message.status}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending SMS notification: {e}")
            return False
    
    async def _track_billing_event(self, data: NotificationData) -> bool:
        """Registra evento de billing para analytics."""
        try:
            # Registrar no banco para analytics
            analytics_data = {
                "user_id": data.user_id,
                "event_type": "plan_change",
                "event_action": data.action,
                "entity_type": data.entity_type,
                "entity_id": data.entity_id,
                "old_plan": data.old_plan,
                "new_plan": data.new_plan,
                "amount_cents": data.amount_cents,
                "timestamp": datetime.now().isoformat(),
                "metadata": {
                    "notification_sent": True,
                    "billing_date": data.billing_date.isoformat() if data.billing_date else None
                }
            }
            
            # Salvar no Supabase
            self.supabase.table("billing_analytics").insert(analytics_data).execute()
            
            logger.info(f"Analytics event tracked for {data.user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error tracking analytics: {e}")
            return False
    
    def _get_email_template_data(self, data: NotificationData) -> Dict[str, Any]:
        """Gera dados do template de email baseado na ação."""
        entity_name = self._get_entity_display_name(data.entity_type)
        
        if data.action == 'upgrade':
            return {
                "subject": f"🎉 Upgrade realizado com sucesso - Plano {data.new_plan}",
                "title": "Parabéns pelo seu upgrade!",
                "message": f"Seu {entity_name} foi upgradeado para o plano {data.new_plan}.",
                "features": self._get_plan_features(data.entity_type, data.new_plan),
                "action_color": "#10B981",  # Green
                "action_icon": "🚀",
                "cta_text": "Explorar novos recursos",
                "cta_url": self._get_dashboard_url(data.entity_type, data.entity_id)
            }
        elif data.action == 'downgrade':
            return {
                "subject": f"Plano alterado para {data.new_plan}",
                "title": "Plano alterado",
                "message": f"Seu {entity_name} foi alterado para o plano {data.new_plan}.",
                "features": self._get_plan_features(data.entity_type, data.new_plan),
                "action_color": "#F59E0B",  # Amber
                "action_icon": "📋",
                "cta_text": "Ver plano atual",
                "cta_url": self._get_billing_url(data.entity_type, data.entity_id)
            }
        else:  # cancellation
            return {
                "subject": f"Plano cancelado - {data.old_plan}",
                "title": "Plano cancelado",
                "message": f"Seu plano {data.old_plan} foi cancelado. Você ainda tem acesso até o final do período de cobrança.",
                "features": ["Acesso mantido até o fim do período", "Dados preservados", "Reativação disponível"],
                "action_color": "#EF4444",  # Red
                "action_icon": "⏸️",
                "cta_text": "Reativar plano",
                "cta_url": self._get_billing_url(data.entity_type, data.entity_id)
            }
    
    def _render_email_template(self, template_data: Dict[str, Any]) -> str:
        """Renderiza template de email HTML."""
        template_html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{{ title }}</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: #f8fafc; }
                .container { max-width: 600px; margin: 0 auto; background: white; }
                .header { background: {{ action_color }}; color: white; padding: 32px; text-align: center; }
                .content { padding: 32px; }
                .features { margin: 24px 0; }
                .feature { padding: 8px 0; border-left: 3px solid {{ action_color }}; padding-left: 16px; margin: 8px 0; }
                .cta { text-align: center; margin: 32px 0; }
                .button { display: inline-block; background: {{ action_color }}; color: white; padding: 16px 32px; text-decoration: none; border-radius: 8px; font-weight: bold; }
                .footer { background: #f1f5f9; padding: 24px; text-align: center; font-size: 14px; color: #64748b; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>{{ action_icon }} {{ title }}</h1>
                </div>
                <div class="content">
                    <p>{{ message }}</p>
                    
                    <div class="features">
                        <h3>Recursos inclusos:</h3>
                        {% for feature in features %}
                        <div class="feature">{{ feature }}</div>
                        {% endfor %}
                    </div>
                    
                    <div class="cta">
                        <a href="{{ cta_url }}" class="button">{{ cta_text }}</a>
                    </div>
                </div>
                <div class="footer">
                    <p>LITIG - Plataforma Jurídica<br>
                    Dúvidas? Entre em contato: suporte@litig.com.br</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        template = self.jinja_env.from_string(template_html)
        return template.render(**template_data)
    
    def _generate_sms_message(self, data: NotificationData) -> str:
        """Gera mensagem SMS concisa."""
        if data.action == 'upgrade':
            return f"🎉 LITIG: Upgrade realizado! Seu plano {data.new_plan} está ativo. Acesse: litig.com.br"
        elif data.action == 'downgrade':
            return f"📋 LITIG: Plano alterado para {data.new_plan}. Acesse sua conta: litig.com.br"
        else:
            return f"⏸️ LITIG: Plano {data.old_plan} cancelado. Acesso mantido até fim do período. litig.com.br"
    
    def _get_entity_display_name(self, entity_type: str) -> str:
        """Retorna nome amigável para tipo de entidade."""
        names = {
            "client": "perfil",
            "lawyer": "perfil profissional", 
            "firm": "escritório"
        }
        return names.get(entity_type, "conta")
    
    def _get_plan_features(self, entity_type: str, plan: str) -> list:
        """Retorna features do plano para exibição."""
        # Importar do billing service para manter consistência
        from services.stripe_billing_service import StripeBillingService
        billing_service = StripeBillingService()
        return billing_service.get_plan_features(plan, entity_type)
    
    def _get_dashboard_url(self, entity_type: str, entity_id: str) -> str:
        """Retorna URL do dashboard apropriado."""
        base_url = os.getenv("FRONTEND_URL", "https://app.litig.com.br")
        if entity_type == "client":
            return f"{base_url}/client-home"
        elif entity_type == "lawyer":
            return f"{base_url}/dashboard"
        elif entity_type == "firm":
            return f"{base_url}/firm-dashboard"
        return f"{base_url}/dashboard"
    
    def _get_billing_url(self, entity_type: str, entity_id: str) -> str:
        """Retorna URL da página de billing."""
        base_url = os.getenv("FRONTEND_URL", "https://app.litig.com.br")
        return f"{base_url}/billing/plans"


# Helper function para uso nos webhooks
async def send_plan_change_notification(
    user_id: str,
    entity_type: str,
    entity_id: str,
    old_plan: str,
    new_plan: str,
    action: str,
    amount_cents: Optional[int] = None
) -> bool:
    """
    Função helper para enviar notificação de mudança de plano.
    Usada pelos webhooks do Stripe.
    """
    try:
        # Buscar dados do usuário
        supabase = get_supabase_client()
        user_data = supabase.table("profiles").select("*").eq("user_id", user_id).single().execute()
        
        if not user_data.data:
            logger.error(f"User {user_id} not found")
            return False
        
        user = user_data.data
        
        # Criar dados de notificação
        notification_data = NotificationData(
            user_id=user_id,
            user_name=user.get("full_name", "Usuário"),
            user_email=user.get("email", ""),
            user_phone=user.get("phone"),
            entity_type=entity_type,
            entity_id=entity_id,
            old_plan=old_plan,
            new_plan=new_plan,
            action=action,
            amount_cents=amount_cents,
            billing_date=datetime.now()
        )
        
        # Enviar notificação
        notification_service = NotificationService()
        return await notification_service.send_plan_change_notification(notification_data)
        
    except Exception as e:
        logger.error(f"Error in send_plan_change_notification: {e}")
        return False