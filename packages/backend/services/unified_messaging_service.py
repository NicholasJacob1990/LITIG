# -*- coding: utf-8 -*-
"""
Unified Messaging Service - Integração com Unipile SDK
=====================================================

Serviço para consolidar mensagens de múltiplas plataformas (LinkedIn, Instagram, 
WhatsApp, Gmail, Outlook) em uma única interface através da API Unipile.

Baseado na documentação oficial:
- https://developer.unipile.com/reference/chatscontroller_listallchats
- https://developer.unipile.com/reference/mailscontroller_listmails
- https://developer.unipile.com/reference/linkedincontroller_getcompanyprofile
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
import json
import os
import subprocess

import aiohttp
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class UnifiedAccount:
    """Representação de uma conta conectada."""
    id: str
    provider: str  # linkedin, instagram, whatsapp, gmail, outlook
    account_name: Optional[str] = None
    account_email: Optional[str] = None
    status: str = "active"
    last_sync: Optional[datetime] = None


@dataclass
class UnifiedChat:
    """Representação de um chat unificado."""
    id: str
    provider: str
    chat_name: str
    chat_type: str = "direct"  # direct, group, channel
    avatar_url: Optional[str] = None
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: int = 0
    is_archived: bool = False


@dataclass
class UnifiedMessage:
    """Representação de uma mensagem unificada."""
    id: str
    chat_id: str
    provider_message_id: str
    sender_id: Optional[str] = None
    sender_name: Optional[str] = None
    sender_email: Optional[str] = None
    message_type: str = "text"  # text, image, video, file, audio
    content: Optional[str] = None
    attachments: List[Dict] = field(default_factory=list)
    is_outgoing: bool = False
    is_read: bool = False
    sent_at: Optional[datetime] = None
    received_at: Optional[datetime] = None


@dataclass
class UnifiedContact:
    """Representação de um contato unificado."""
    id: str
    provider: str
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    company: Optional[str] = None
    position: Optional[str] = None
    profile_url: Optional[str] = None


class UnifiedMessagingService:
    """Serviço para integração com mensagens unificadas via Unipile."""
    
    def __init__(self, api_token: Optional[str] = None, dsn: Optional[str] = None):
        self.api_token = api_token or os.getenv("UNIPILE_API_TOKEN")
        self.dsn = dsn or os.getenv("UNIPILE_DSN")
        self.base_url = f"https://{self.dsn}" if self.dsn else "https://api.unipile.com"
        self.logger = logging.getLogger(__name__)
        
        # Path para o serviço Node.js
        self.sdk_service_path = "/Users/nicholasjacob/LITIG-1/packages/backend/unipile_sdk_service.js"
        
        if not self.api_token:
            self.logger.warning("UNIPILE_API_TOKEN não configurado. Funcionalidades limitadas.")
    
    def _get_headers(self) -> Dict[str, str]:
        """Gera headers para requisições à API Unipile."""
        if not self.api_token:
            raise ValueError("API token do Unipile não foi configurado.")

        return {
            "X-API-KEY": self.api_token,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "LITIG-1-Unified-Messaging/1.0"
        }
    
    def _get_url(self, endpoint: str) -> str:
        """Constrói URL completa para API."""
        return f"{self.base_url}/api/v1{endpoint}"
    
    async def _call_node_service(self, command: str, **kwargs) -> Dict[str, Any]:
        """Chama o serviço Node.js via subprocess."""
        try:
            cmd = [
                "node", self.sdk_service_path, command
            ]
            
            # Adiciona parâmetros
            for key, value in kwargs.items():
                if value is not None:
                    cmd.extend([f"--{key}", str(value)])
            
            # Configura ambiente
            env = os.environ.copy()
            env["UNIPILE_API_TOKEN"] = self.api_token or "test_token"
            
            # Executa comando
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                env=env,
                timeout=30
            )
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                self.logger.error(f"Erro no serviço Node.js: {result.stderr}")
                return {"success": False, "error": result.stderr}
                
        except json.JSONDecodeError as e:
            self.logger.error(f"Erro ao decodificar resposta JSON: {e}")
            return {"success": False, "error": "Invalid JSON response"}
        except subprocess.TimeoutExpired:
            self.logger.error("Timeout na chamada do serviço Node.js")
            return {"success": False, "error": "Service timeout"}
        except Exception as e:
            self.logger.error(f"Erro inesperado na chamada Node.js: {e}")
            return {"success": False, "error": str(e)}
    
    # ===============================
    # GESTÃO DE CONTAS
    # ===============================
    
    async def connect_account(self, provider: str, credentials: Dict) -> Dict[str, Any]:
        """
        Conecta uma conta de qualquer provedor suportado.
        
        Args:
            provider: linkedin, instagram, whatsapp, gmail, outlook
            credentials: Dados de autenticação específicos do provedor
        """
        try:
            provider_lower = provider.lower()
            
            if provider_lower == "linkedin":
                return await self._call_node_service(
                    "connect-linkedin",
                    username=credentials.get("username"),
                    password=credentials.get("password")
                )
            elif provider_lower == "instagram":
                return await self._call_node_service(
                    "connect-instagram",
                    username=credentials.get("username"),
                    password=credentials.get("password")
                )
            elif provider_lower == "gmail":
                return await self._call_node_service(
                    "connect-email",
                    provider="gmail",
                    username=credentials.get("username"),
                    password=credentials.get("password")
                )
            elif provider_lower == "outlook":
                return await self._call_node_service(
                    "connect-email",
                    provider="outlook",
                    username=credentials.get("username"),
                    password=credentials.get("password")
                )
            else:
                return {
                    "success": False,
                    "error": f"Provedor {provider} não suportado"
                }
                
        except Exception as e:
            self.logger.error(f"Erro ao conectar conta {provider}: {e}")
            return {"success": False, "error": str(e)}
    
    async def list_connected_accounts(self) -> List[UnifiedAccount]:
        """Lista todas as contas conectadas."""
        try:
            result = await self._call_node_service("list-accounts")
            
            if not result.get("success", False):
                return []
            
            accounts = []
            for account_data in result.get("accounts", []):
                account = UnifiedAccount(
                    id=account_data.get("id"),
                    provider=account_data.get("provider"),
                    account_name=account_data.get("name"),
                    account_email=account_data.get("email"),
                    status=account_data.get("status", "active"),
                    last_sync=self._parse_datetime(account_data.get("last_sync"))
                )
                accounts.append(account)
            
            return accounts
            
        except Exception as e:
            self.logger.error(f"Erro ao listar contas: {e}")
            return []
    
    # ===============================
    # GESTÃO DE CHATS
    # ===============================
    
    async def list_all_chats(self, account_id: Optional[str] = None) -> List[UnifiedChat]:
        """
        Lista todos os chats de todas as contas ou de uma conta específica.
        
        Ref: https://developer.unipile.com/reference/chatscontroller_listallchats
        """
        try:
            all_chats = []
            
            if account_id:
                # Lista chats de uma conta específica
                result = await self._call_node_service(
                    "list-chats",
                    accountId=account_id
                )
                
                if result.get("success"):
                    chats_data = result.get("chats", [])
                    for chat_data in chats_data:
                        chat = self._parse_chat_data(chat_data)
                        all_chats.append(chat)
            else:
                # Lista chats de todas as contas
                accounts = await self.list_connected_accounts()
                
                for account in accounts:
                    if account.status == "active":
                        account_chats = await self.list_all_chats(account.id)
                        all_chats.extend(account_chats)
            
            # Ordena por última mensagem
            all_chats.sort(
                key=lambda x: x.last_message_at or datetime.min,
                reverse=True
            )
            
            return all_chats
            
        except Exception as e:
            self.logger.error(f"Erro ao listar chats: {e}")
            return []
    
    async def get_chat_details(self, chat_id: str, account_id: str) -> Optional[UnifiedChat]:
        """Obtém detalhes de um chat específico."""
        try:
            result = await self._call_node_service(
                "get-chat",
                chatId=chat_id,
                accountId=account_id
            )
            
            if result.get("success"):
                return self._parse_chat_data(result.get("chat", {}))
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao obter chat {chat_id}: {e}")
            return None
    
    async def start_new_chat(self, account_id: str, participant_ids: List[str]) -> Optional[UnifiedChat]:
        """Inicia novo chat com participantes especificados."""
        try:
            result = await self._call_node_service(
                "start-chat",
                accountId=account_id,
                participants=",".join(participant_ids)
            )
            
            if result.get("success"):
                return self._parse_chat_data(result.get("chat", {}))
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao iniciar chat: {e}")
            return None
    
    # ===============================
    # GESTÃO DE MENSAGENS
    # ===============================
    
    async def get_chat_messages(
        self, 
        chat_id: str, 
        account_id: str,
        limit: int = 50,
        cursor: Optional[str] = None
    ) -> List[UnifiedMessage]:
        """
        Recupera mensagens de um chat específico.
        """
        try:
            kwargs = {
                "chatId": chat_id,
                "accountId": account_id,
                "limit": limit
            }
            
            if cursor:
                kwargs["cursor"] = cursor
            
            result = await self._call_node_service("get-chat-messages", **kwargs)
            
            if not result.get("success"):
                return []
            
            messages = []
            for message_data in result.get("messages", []):
                message = self._parse_message_data(message_data)
                messages.append(message)
            
            return messages
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar mensagens do chat {chat_id}: {e}")
            return []
    
    async def send_message(
        self,
        chat_id: str,
        account_id: str,
        content: str,
        message_type: str = "text",
        attachments: Optional[List[Dict]] = None
    ) -> Optional[UnifiedMessage]:
        """Envia uma mensagem para um chat."""
        try:
            kwargs = {
                "chatId": chat_id,
                "accountId": account_id,
                "message": content,
                "type": message_type
            }
            
            if attachments:
                kwargs["attachments"] = json.dumps(attachments)
            
            result = await self._call_node_service("send-message", **kwargs)
            
            if result.get("success"):
                message_data = result.get("message", {})
                return self._parse_message_data(message_data)
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar mensagem: {e}")
            return None
    
    async def mark_message_as_read(self, message_id: str, chat_id: str, account_id: str) -> bool:
        """Marca uma mensagem como lida."""
        try:
            result = await self._call_node_service(
                "mark-read",
                messageId=message_id,
                chatId=chat_id,
                accountId=account_id
            )
            
            return result.get("success", False)
            
        except Exception as e:
            self.logger.error(f"Erro ao marcar mensagem como lida: {e}")
            return False
    
    # ===============================
    # GESTÃO DE E-MAILS
    # ===============================
    
    async def list_emails(
        self,
        account_id: str,
        folder: str = "INBOX",
        limit: int = 50
    ) -> List[UnifiedMessage]:
        """
        Lista e-mails de uma conta.
        
        Ref: https://developer.unipile.com/reference/mailscontroller_listmails
        """
        try:
            result = await self._call_node_service(
                "list-emails",
                accountId=account_id,
                folder=folder,
                limit=limit
            )
            
            if not result.get("success"):
                return []
            
            emails = []
            for email_data in result.get("emails", []):
                email = self._parse_email_as_message(email_data)
                emails.append(email)
            
            return emails
            
        except Exception as e:
            self.logger.error(f"Erro ao listar e-mails: {e}")
            return []
    
    async def send_email(
        self,
        account_id: str,
        to: List[str],
        subject: str,
        content: str,
        cc: Optional[List[str]] = None,
        bcc: Optional[List[str]] = None,
        attachments: Optional[List[Dict]] = None
    ) -> bool:
        """
        Envia um e-mail.
        
        Ref: https://developer.unipile.com/reference/mailscontroller_sendmail
        """
        try:
            kwargs = {
                "accountId": account_id,
                "to": ",".join(to),
                "subject": subject,
                "content": content
            }
            
            if cc:
                kwargs["cc"] = ",".join(cc)
            if bcc:
                kwargs["bcc"] = ",".join(bcc)
            if attachments:
                kwargs["attachments"] = json.dumps(attachments)
            
            result = await self._call_node_service("send-email", **kwargs)
            
            return result.get("success", False)
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar e-mail: {e}")
            return False
    
    # ===============================
    # GESTÃO DE CONTATOS
    # ===============================
    
    async def get_profile_by_email(self, email: str, provider: str = "linkedin") -> Optional[UnifiedContact]:
        """
        Busca perfil de usuário por email.
        
        Ref: https://developer.unipile.com/reference/userscontroller_getprofilebyidentifier
        """
        try:
            result = await self._call_node_service(
                "get-profile",
                email=email,
                provider=provider
            )
            
            if result.get("success"):
                profile_data = result.get("profile", {})
                return self._parse_contact_data(profile_data, provider)
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar perfil {email}: {e}")
            return None
    
    async def get_company_profile(self, company_id: str, account_id: str) -> Optional[Dict]:
        """
        Busca perfil de empresa no LinkedIn.
        
        Ref: https://developer.unipile.com/reference/linkedincontroller_getcompanyprofile
        """
        try:
            result = await self._call_node_service(
                "get-company-profile",
                companyId=company_id,
                accountId=account_id
            )
            
            if result.get("success"):
                return result.get("company", {})
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar perfil da empresa {company_id}: {e}")
            return None
    
    # ===============================
    # MÉTODOS AUXILIARES
    # ===============================
    
    def _parse_chat_data(self, chat_data: Dict) -> UnifiedChat:
        """Converte dados de chat da API para UnifiedChat."""
        return UnifiedChat(
            id=chat_data.get("id", ""),
            provider=chat_data.get("provider", ""),
            chat_name=chat_data.get("name", "Chat sem nome"),
            chat_type=chat_data.get("type", "direct"),
            avatar_url=chat_data.get("avatar"),
            last_message=chat_data.get("last_message"),
            last_message_at=self._parse_datetime(chat_data.get("last_message_at")),
            unread_count=chat_data.get("unread_count", 0),
            is_archived=chat_data.get("is_archived", False)
        )
    
    def _parse_message_data(self, message_data: Dict) -> UnifiedMessage:
        """Converte dados de mensagem da API para UnifiedMessage."""
        return UnifiedMessage(
            id=message_data.get("id", ""),
            chat_id=message_data.get("chat_id", ""),
            provider_message_id=message_data.get("provider_message_id", ""),
            sender_id=message_data.get("sender_id"),
            sender_name=message_data.get("sender_name"),
            sender_email=message_data.get("sender_email"),
            message_type=message_data.get("type", "text"),
            content=message_data.get("content"),
            attachments=message_data.get("attachments", []),
            is_outgoing=message_data.get("is_outgoing", False),
            is_read=message_data.get("is_read", False),
            sent_at=self._parse_datetime(message_data.get("sent_at")),
            received_at=self._parse_datetime(message_data.get("received_at"))
        )
    
    def _parse_email_as_message(self, email_data: Dict) -> UnifiedMessage:
        """Converte dados de e-mail para UnifiedMessage."""
        return UnifiedMessage(
            id=email_data.get("id", ""),
            chat_id=f"email_{email_data.get('folder', 'inbox')}",
            provider_message_id=email_data.get("message_id", ""),
            sender_name=email_data.get("from_name"),
            sender_email=email_data.get("from_email"),
            message_type="email",
            content=f"**{email_data.get('subject', 'Sem assunto')}**\n\n{email_data.get('body', '')}",
            attachments=email_data.get("attachments", []),
            is_outgoing=False,
            is_read=email_data.get("is_read", False),
            sent_at=self._parse_datetime(email_data.get("date")),
            received_at=self._parse_datetime(email_data.get("received_at"))
        )
    
    def _parse_contact_data(self, contact_data: Dict, provider: str) -> UnifiedContact:
        """Converte dados de contato da API para UnifiedContact."""
        return UnifiedContact(
            id=contact_data.get("id", ""),
            provider=provider,
            name=contact_data.get("name", ""),
            email=contact_data.get("email"),
            phone=contact_data.get("phone"),
            avatar_url=contact_data.get("avatar"),
            company=contact_data.get("company"),
            position=contact_data.get("position"),
            profile_url=contact_data.get("profile_url")
        )
    
    def _parse_datetime(self, date_str: Optional[str]) -> Optional[datetime]:
        """Parse de string de data para datetime."""
        if not date_str:
            return None
        
        try:
            # Tenta ISO format primeiro
            return datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
        except:
            try:
                # Tenta formato timestamp
                return datetime.fromtimestamp(float(date_str))
            except:
                return None
    
    # ===============================
    # HEALTH CHECK
    # ===============================
    
    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde da integração com Unipile."""
        try:
            result = await self._call_node_service("health-check")
            
            return {
                "status": "healthy" if result.get("success") else "unhealthy",
                "api_endpoint": self.base_url,
                "has_token": bool(self.api_token),
                "service_available": result.get("success", False),
                "messaging_support": True,
                "email_support": True,
                "calendar_support": True,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    # ===============================
    # SINCRONIZAÇÃO
    # ===============================
    
    async def sync_all_messages(self, user_id: str) -> Dict[str, Any]:
        """Sincroniza todas as mensagens de todas as contas do usuário."""
        try:
            accounts = await self.list_connected_accounts()
            sync_results = []
            
            for account in accounts:
                if account.status == "active":
                    account_result = await self._sync_account_messages(account)
                    sync_results.append({
                        "account_id": account.id,
                        "provider": account.provider,
                        "success": account_result.get("success", False),
                        "synced_chats": account_result.get("synced_chats", 0),
                        "synced_messages": account_result.get("synced_messages", 0)
                    })
            
            total_chats = sum(r["synced_chats"] for r in sync_results)
            total_messages = sum(r["synced_messages"] for r in sync_results)
            
            return {
                "success": True,
                "user_id": user_id,
                "accounts_synced": len(sync_results),
                "total_chats": total_chats,
                "total_messages": total_messages,
                "results": sync_results,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Erro na sincronização geral: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def _sync_account_messages(self, account: UnifiedAccount) -> Dict[str, Any]:
        """Sincroniza mensagens de uma conta específica."""
        try:
            chats = await self.list_all_chats(account.id)
            synced_chats = 0
            synced_messages = 0
            
            for chat in chats:
                messages = await self.get_chat_messages(chat.id, account.id, limit=10)
                if messages:
                    synced_chats += 1
                    synced_messages += len(messages)
            
            return {
                "success": True,
                "synced_chats": synced_chats,
                "synced_messages": synced_messages
            }
            
        except Exception as e:
            self.logger.error(f"Erro ao sincronizar conta {account.id}: {e}")
            return {"success": False, "error": str(e)}