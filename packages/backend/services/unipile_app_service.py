# -*- coding: utf-8 -*-
"""
Unipile App Service - Serviço Principal da Aplicação
===================================================

Serviço principal que integra a camada de compatibilidade Unipile
com as configurações da aplicação, fornecendo interface unificada
para todo o sistema LITIG-1.

Funcionalidades:
- Integração com configurações da aplicação
- Cache de instâncias de serviço
- Monitoramento automático
- Rate limiting
- Logging estruturado
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from functools import lru_cache

# Configurações da aplicação
try:
    from config import (
        UNIPILE_PREFERRED_SERVICE,
        UNIPILE_API_TOKEN,
        UNIFIED_API_KEY,
        UNIPILE_SERVER_REGION,
        UNIPILE_ENABLE_FALLBACK,
        UNIPILE_HEALTH_CHECK_INTERVAL,
        UNIPILE_TIMEOUT_SECONDS,
        UNIPILE_RATE_LIMIT_REQUESTS,
        UNIPILE_RATE_LIMIT_WINDOW,
        UNIPILE_REGIONS,
        UNIPILE_LOG_LEVEL,
        UNIPILE_LOG_REQUESTS
    )
except ImportError:
    from config import (
        UNIPILE_PREFERRED_SERVICE,
        UNIPILE_API_TOKEN,
        UNIFIED_API_KEY,
        UNIPILE_SERVER_REGION,
        UNIPILE_ENABLE_FALLBACK,
        UNIPILE_HEALTH_CHECK_INTERVAL,
        UNIPILE_TIMEOUT_SECONDS,
        UNIPILE_RATE_LIMIT_REQUESTS,
        UNIPILE_RATE_LIMIT_WINDOW,
        UNIPILE_REGIONS,
        UNIPILE_LOG_LEVEL,
        UNIPILE_LOG_REQUESTS
    )

# Camada de compatibilidade
try:
    from services.unipile_compatibility_layer import (
        get_unipile_service,
        ServiceType,
        UnipileCompatibilityLayer
    )
except ImportError:
    from services.unipile_compatibility_layer import (
        get_unipile_service,
        ServiceType,
        UnipileCompatibilityLayer
    )

# Configurar logging específico
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, UNIPILE_LOG_LEVEL, logging.INFO))


class UnipileAppService:
    """
    Serviço principal da aplicação para integração Unipile.
    
    Fornece interface unificada, cache, monitoramento e configurações
    específicas da aplicação LITIG-1.
    """
    
    _instance: Optional['UnipileAppService'] = None
    _compatibility_service: Optional[UnipileCompatibilityLayer] = None
    _last_health_check: Optional[datetime] = None
    _health_status: Dict[str, Any] = {}
    _request_count: int = 0
    _rate_limit_reset: Optional[datetime] = None
    
    def __new__(cls):
        """Singleton pattern para garantir única instância."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        """Inicializar serviço com configurações da aplicação."""
        if not hasattr(self, '_initialized'):
            self._initialized = True
            self._setup_logging()
            self._validate_config()
            logger.info("✅ UnipileAppService inicializado com sucesso")
    
    def _setup_logging(self):
        """Configurar logging específico do Unipile."""
        if UNIPILE_LOG_REQUESTS:
            logging.getLogger("backend.services.unipile_compatibility_layer").setLevel(logging.DEBUG)
            logging.getLogger("backend.services.unipile_official_sdk").setLevel(logging.DEBUG)
    
    def _validate_config(self):
        """Validar configurações essenciais."""
        api_key = UNIPILE_API_TOKEN or UNIFIED_API_KEY
        if not api_key:
            logger.warning("⚠️ UNIPILE_API_TOKEN não configurado - algumas funcionalidades não estarão disponíveis")
        
        if UNIPILE_SERVER_REGION not in UNIPILE_REGIONS:
            logger.warning(f"⚠️ Região '{UNIPILE_SERVER_REGION}' não reconhecida, usando 'north-america'")
        
        logger.info(f"🌍 Região configurada: {UNIPILE_SERVER_REGION}")
        logger.info(f"🔧 Serviço preferido: {UNIPILE_PREFERRED_SERVICE}")
        logger.info(f"🔄 Fallback habilitado: {UNIPILE_ENABLE_FALLBACK}")
    
    @property
    def compatibility_service(self) -> UnipileCompatibilityLayer:
        """Obter instância da camada de compatibilidade."""
        if self._compatibility_service is None:
            # Determinar tipo de serviço preferido
            try:
                preferred_service = ServiceType(UNIPILE_PREFERRED_SERVICE)
            except ValueError:
                logger.warning(f"⚠️ Tipo de serviço inválido: {UNIPILE_PREFERRED_SERVICE}, usando AUTO_FALLBACK")
                preferred_service = ServiceType.AUTO_FALLBACK
            
            self._compatibility_service = get_unipile_service(preferred_service)
            logger.info(f"🚀 Camada de compatibilidade inicializada com: {preferred_service.value}")
        
        return self._compatibility_service
    
    async def _check_rate_limit(self) -> bool:
        """Verificar se não excedeu rate limit."""
        now = datetime.now()
        
        # Reset contador se janela de tempo passou
        if self._rate_limit_reset is None or now > self._rate_limit_reset:
            self._request_count = 0
            self._rate_limit_reset = now + timedelta(seconds=UNIPILE_RATE_LIMIT_WINDOW)
        
        # Verificar se excedeu limite
        if self._request_count >= UNIPILE_RATE_LIMIT_REQUESTS:
            logger.warning(f"⚠️ Rate limit excedido: {self._request_count}/{UNIPILE_RATE_LIMIT_REQUESTS}")
            return False
        
        self._request_count += 1
        return True
    
    async def _periodic_health_check(self) -> Dict[str, Any]:
        """Executar health check periódico."""
        now = datetime.now()
        
        # Verificar se precisa fazer health check
        if (self._last_health_check is None or 
            (now - self._last_health_check).total_seconds() > UNIPILE_HEALTH_CHECK_INTERVAL):
            
            try:
                self._health_status = await self.compatibility_service.health_check()
                self._last_health_check = now
                logger.debug(f"🏥 Health check executado: {self._health_status.get('status')}")
            except Exception as e:
                logger.error(f"❌ Erro no health check: {e}")
                self._health_status = {"status": "error", "error": str(e)}
        
        return self._health_status
    
    # ===== MÉTODOS PÚBLICOS =====
    
    async def health_check(self) -> Dict[str, Any]:
        """Health check com configurações da aplicação."""
        health = await self._periodic_health_check()
        
        return {
            **health,
            "app_config": {
                "preferred_service": UNIPILE_PREFERRED_SERVICE,
                "region": UNIPILE_SERVER_REGION,
                "fallback_enabled": UNIPILE_ENABLE_FALLBACK,
                "api_key_configured": bool(UNIPILE_API_TOKEN or UNIFIED_API_KEY)
            },
            "rate_limit": {
                "requests_made": self._request_count,
                "limit": UNIPILE_RATE_LIMIT_REQUESTS,
                "window_seconds": UNIPILE_RATE_LIMIT_WINDOW,
                "reset_at": self._rate_limit_reset.isoformat() if self._rate_limit_reset else None
            },
            "timestamp": datetime.now().isoformat()
        }
    
    async def list_accounts(self) -> List[Dict[str, Any]]:
        """Listar contas com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        accounts = await self.compatibility_service.list_accounts()
        
        # Converter para formato consistente
        result = []
        for account in accounts:
            if hasattr(account, '__dict__'):
                result.append({
                    "id": account.id,
                    "provider": account.provider,
                    "email": account.email,
                    "status": account.status,
                    "last_sync": account.last_sync.isoformat() if account.last_sync else None
                })
            else:
                result.append(account)
        
        logger.info(f"📋 Listadas {len(result)} contas")
        return result
    
    async def create_calendar_event(self, connection_id: str, event_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Criar evento de calendário com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        result = await self.compatibility_service.create_calendar_event(connection_id, event_data)
        
        if result:
            logger.info(f"📅 Evento criado: {result.get('id', 'N/A')}")
        
        return result
    
    async def list_calendar_events(self, connection_id: str, calendar_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Listar eventos de calendário com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        events = await self.compatibility_service.list_calendar_events(connection_id, calendar_id)
        
        logger.info(f"📅 Listados {len(events)} eventos")
        return events
    
    async def send_email(self, connection_id: str, message_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Enviar email com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        result = await self.compatibility_service.send_email(connection_id, message_data)
        
        if result:
            logger.info(f"📧 Email enviado: {result.get('id', 'N/A')}")
        
        return result
    
    async def list_emails(self, connection_id: str, channel_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Listar emails com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        emails = await self.compatibility_service.list_emails(connection_id, channel_id)
        
        logger.info(f"📧 Listados {len(emails)} emails")
        return emails
    
    async def create_webhook(self, connection_id: str, webhook_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Criar webhook com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        result = await self.compatibility_service.create_webhook(connection_id, webhook_data)
        
        if result:
            logger.info(f"🔔 Webhook criado: {result.get('id', 'N/A')}")
        
        return result
    
    async def get_communication_data(self, oab_number: str, email: Optional[str] = None):
        """Buscar dados de comunicação com rate limiting."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        result = await self.compatibility_service.get_communication_data(oab_number, email)
        
        logger.info(f"🔍 Dados de comunicação obtidos para OAB: {oab_number}")
        return result
    
    async def switch_service(self, service_type: str) -> Dict[str, Any]:
        """Alternar serviço manualmente."""
        try:
            new_service = ServiceType(service_type)
        except ValueError:
            raise ValueError(f"Tipo de serviço inválido: {service_type}")
        
        result = await self.compatibility_service.switch_service(new_service)
        logger.info(f"🔄 Serviço alterado para: {service_type}")
        
        return result
    
    async def get_service_metrics(self) -> Dict[str, Any]:
        """Obter métricas detalhadas do serviço."""
        metrics = await self.compatibility_service.get_service_metrics()
        
        return {
            **metrics,
            "app_metrics": {
                "requests_made": self._request_count,
                "rate_limit": UNIPILE_RATE_LIMIT_REQUESTS,
                "health_check_interval": UNIPILE_HEALTH_CHECK_INTERVAL,
                "last_health_check": self._last_health_check.isoformat() if self._last_health_check else None
            }
        }
    
    # ===== MÉTODOS LINKEDIN ESPECÍFICOS =====
    
    async def send_inmail(self, account_id: str, recipient_id: str, subject: str, body: str, attachments: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Envia InMail no LinkedIn.
        
        Args:
            account_id: ID da conta LinkedIn
            recipient_id: ID do usuário destinatário
            subject: Assunto do InMail
            body: Corpo da mensagem
            attachments: Lista de URLs de anexos (opcional)
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.send_linkedin_inmail(
                account_id=account_id,
                recipient_id=recipient_id,
                subject=subject,
                body=body,
                attachments=attachments
            )
            
            if result:
                logger.info(f"💼 InMail enviado no LinkedIn: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "InMail enviado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao enviar InMail: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao enviar InMail"
            }
    
    async def send_invitation(self, account_id: str, user_id: str, message: Optional[str] = None) -> Dict[str, Any]:
        """
        Envia convite de conexão no LinkedIn.
        
        Args:
            account_id: ID da conta LinkedIn
            user_id: ID do usuário para convidar
            message: Mensagem personalizada (opcional)
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.send_linkedin_invitation(
                account_id=account_id,
                user_id=user_id,
                message=message
            )
            
            if result:
                logger.info(f"🤝 Convite LinkedIn enviado: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "Convite enviado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao enviar convite: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao enviar convite"
            }
    
    async def send_voice_note(self, account_id: str, chat_id: str, audio_url: str) -> Dict[str, Any]:
        """
        Envia nota de voz no LinkedIn.
        
        Args:
            account_id: ID da conta LinkedIn
            chat_id: ID do chat/conversa
            audio_url: URL do arquivo de áudio
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.send_voice_note(
                account_id=account_id,
                chat_id=chat_id,
                audio_url=audio_url
            )
            
            if result:
                logger.info(f"🎵 Nota de voz enviada: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "Nota de voz enviada com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao enviar nota de voz: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao enviar nota de voz"
            }
    
    async def comment_on_post(self, account_id: str, post_id: str, comment: str) -> Dict[str, Any]:
        """
        Comenta em uma postagem do LinkedIn.
        
        Args:
            account_id: ID da conta LinkedIn
            post_id: ID da postagem
            comment: Texto do comentário
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.comment_on_linkedin_post(
                account_id=account_id,
                post_id=post_id,
                comment=comment
            )
            
            if result:
                logger.info(f"💬 Comentário postado: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "Comentário postado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao comentar: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao postar comentário"
            }
    
    # ===== GESTÃO COMPLETA DE EMAIL =====
    
    async def reply_email(self, account_id: str, email_id: str, reply_body: str, reply_all: bool = False) -> Dict[str, Any]:
        """
        Responde a um email.
        
        Args:
            account_id: ID da conta de email
            email_id: ID do email original
            reply_body: Corpo da resposta
            reply_all: Se deve responder a todos (opcional)
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.reply_to_email(
                account_id=account_id,
                email_id=email_id,
                reply_body=reply_body,
                reply_all=reply_all
            )
            
            if result:
                logger.info(f"↩️ Email respondido: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "Email respondido com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao responder email: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao responder email"
            }
    
    async def delete_email(self, account_id: str, email_id: str, permanent: bool = False) -> Dict[str, Any]:
        """
        Deleta um email.
        
        Args:
            account_id: ID da conta de email
            email_id: ID do email
            permanent: Se deve deletar permanentemente ou mover para lixeira
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.delete_email(
                account_id=account_id,
                email_id=email_id,
                permanent=permanent
            )
            
            if result:
                action = "deletado permanentemente" if permanent else "movido para lixeira"
                logger.info(f"🗑️ Email {action}: {email_id}")
            
            return {
                "success": True,
                "data": result,
                "message": f"Email {'deletado permanentemente' if permanent else 'movido para lixeira'} com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao deletar email: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao deletar email"
            }
    
    async def archive_email(self, account_id: str, email_id: str) -> Dict[str, Any]:
        """
        Arquiva um email.
        
        Args:
            account_id: ID da conta de email
            email_id: ID do email
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.archive_email(
                account_id=account_id,
                email_id=email_id
            )
            
            if result:
                logger.info(f"📥 Email arquivado: {email_id}")
            
            return {
                "success": True,
                "data": result,
                "message": "Email arquivado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao arquivar email: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao arquivar email"
            }
    
    async def create_draft(self, account_id: str, draft_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Cria um rascunho de email.
        
        Args:
            account_id: ID da conta de email
            draft_data: Dados do rascunho (to, subject, body, etc.)
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.create_email_draft(
                account_id=account_id,
                draft_data=draft_data
            )
            
            if result:
                logger.info(f"📝 Rascunho criado: {result.get('id', 'N/A')}")
            
            return {
                "success": True,
                "data": result,
                "message": "Rascunho criado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao criar rascunho: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao criar rascunho"
            }
    
    async def move_email(self, account_id: str, email_id: str, folder_id: str) -> Dict[str, Any]:
        """
        Move um email entre pastas.
        
        Args:
            account_id: ID da conta de email
            email_id: ID do email
            folder_id: ID da pasta de destino
        """
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.move_email(
                account_id=account_id,
                email_id=email_id,
                folder_id=folder_id
            )
            
            if result:
                logger.info(f"📁 Email movido: {email_id} -> {folder_id}")
            
            return {
                "success": True,
                "data": result,
                "message": "Email movido com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao mover email: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao mover email"
            }
    
    # ===== MÉTODOS DE CONEXÃO OAUTH2 =====
    
    async def connect_gmail(self, email: str) -> Dict[str, Any]:
        """Conecta conta Gmail usando OAuth2 via SDK oficial."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.connect_gmail_oauth(email)
            
            if result:
                logger.info(f"📧 Gmail conectado: {email}")
            
            return {
                "success": True,
                "data": result,  
                "message": "Gmail conectado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao conectar Gmail: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao conectar Gmail"
            }
    
    async def connect_whatsapp(self) -> Dict[str, Any]:
        """Conecta WhatsApp via QR Code."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.connect_whatsapp_qr()
            
            if result:
                logger.info("📱 WhatsApp conectado via QR")
            
            return {
                "success": True,
                "data": result,
                "message": "WhatsApp conectado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao conectar WhatsApp: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao conectar WhatsApp"
            }
    
    async def connect_telegram(self, phone_number: str) -> Dict[str, Any]:
        """Conecta Telegram usando número de telefone."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.connect_telegram_phone(phone_number)
            
            if result:
                logger.info(f"📞 Telegram conectado: {phone_number}")
            
            return {
                "success": True,
                "data": result,
                "message": "Telegram conectado com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao conectar Telegram: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao conectar Telegram"
            }
    
    # ===== MÉTODOS DE MENSAGENS UNIFICADAS =====
    
    async def get_all_chats(self, account_id: Optional[str] = None) -> Dict[str, Any]:
        """Lista todas as conversas de todas as contas ou de uma conta específica."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            chats = await self.compatibility_service.list_unified_chats(account_id)
            
            logger.info(f"💬 Listados {len(chats)} chats")
            
            return {
                "success": True,
                "chats": chats,
                "total": len(chats),
                "account_id": account_id
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao listar chats: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao listar chats"
            }
    
    async def get_all_messages(self, chat_id: str, limit: int = 50) -> Dict[str, Any]:
        """Busca mensagens de um chat específico."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            messages = await self.compatibility_service.list_chat_messages(chat_id, limit)
            
            logger.info(f"💬 Listadas {len(messages)} mensagens do chat {chat_id}")
            
            return {
                "success": True,
                "messages": messages,
                "total": len(messages),
                "chat_id": chat_id
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao listar mensagens: {e}")
            return {
                "success": False,
                "error": str(e), 
                "message": "Falha ao listar mensagens"
            }
    
    async def send_message(self, chat_id: str, content: str, attachments: Optional[List[str]] = None) -> Dict[str, Any]:
        """Envia mensagem em um chat."""
        if not await self._check_rate_limit():
            raise Exception("Rate limit excedido")
        
        await self._periodic_health_check()
        
        try:
            result = await self.compatibility_service.send_chat_message(
                chat_id=chat_id,
                content=content,
                attachments=attachments
            )
            
            if result:
                logger.info(f"💬 Mensagem enviada no chat {chat_id}")
            
            return {
                "success": True,
                "data": result,
                "message": "Mensagem enviada com sucesso"
            }
            
        except Exception as e:
            logger.error(f"❌ Erro ao enviar mensagem: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "Falha ao enviar mensagem"
            }


# ===== INSTÂNCIA GLOBAL =====

# Instância singleton do serviço da aplicação
_app_service: Optional[UnipileAppService] = None


def get_unipile_app_service() -> UnipileAppService:
    """
    Obter instância singleton do serviço da aplicação.
    
    Returns:
        Instância configurada do UnipileAppService
    """
    global _app_service
    
    if _app_service is None:
        _app_service = UnipileAppService()
    
    return _app_service


# ===== FUNÇÕES DE CONVENIÊNCIA =====

async def health_check() -> Dict[str, Any]:
    """Health check de conveniência."""
    service = get_unipile_app_service()
    return await service.health_check()


async def list_accounts() -> List[Dict[str, Any]]:
    """Listar contas de conveniência."""
    service = get_unipile_app_service()
    return await service.list_accounts()


async def create_calendar_event(connection_id: str, event_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Criar evento de calendário de conveniência."""
    service = get_unipile_app_service()
    return await service.create_calendar_event(connection_id, event_data)


async def send_email(connection_id: str, message_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Enviar email de conveniência."""
    service = get_unipile_app_service()
    return await service.send_email(connection_id, message_data) 