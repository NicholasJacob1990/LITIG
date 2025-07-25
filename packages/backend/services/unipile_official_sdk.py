# -*- coding: utf-8 -*-
"""
Unipile Official SDK Service - Serviço usando SDK Python oficial da Unipile
===========================================================================

Migração do wrapper personalizado para o SDK oficial unified-python-sdk v0.48.9
Aproveita todas as funcionalidades extras e suporte profissional da Unipile.

Baseado em:
- SDK oficial: unified-python-sdk v0.48.9 
- Documentação: https://github.com/unified-to/unified-python-sdk
- API: https://docs.unified.to/
"""

import logging
import os
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field

# SDK oficial da Unipile
from unified_python_sdk import UnifiedTo
from unified_python_sdk.models import shared
from unified_python_sdk.models import errors

# Integração com sistema híbrido
try:
    from services.hybrid_legal_data_service import DataSource, DataTransparency
except ImportError:
    from enum import Enum
    
    class DataSource(Enum):
        UNIPILE = "unipile"
    
    class DataTransparency:
        def __init__(self, source, last_updated, confidence_score, data_freshness_hours, validation_status, source_url, api_version):
            self.source = source
            self.last_updated = last_updated
            self.confidence_score = confidence_score
            self.data_freshness_hours = data_freshness_hours
            self.validation_status = validation_status
            self.source_url = source_url
            self.api_version = api_version
        
        def to_dict(self):
            return {
                "source": self.source.value if hasattr(self.source, 'value') else str(self.source),
                "last_updated": self.last_updated.isoformat() if self.last_updated else None,
                "confidence_score": self.confidence_score,
                "data_freshness_hours": self.data_freshness_hours,
                "validation_status": self.validation_status,
                "source_url": self.source_url,
                "api_version": self.api_version
            }


@dataclass
class UnipileAccount:
    """Conta conectada no Unipile via SDK oficial."""
    id: str
    provider: str  # gmail, outlook, linkedin, etc.
    email: Optional[str] = None
    status: str = "active"
    last_sync: Optional[datetime] = None


@dataclass
class UnipileProfile:
    """Perfil de usuário extraído via SDK oficial."""
    provider_id: str
    provider: str
    name: str
    email: Optional[str] = None
    profile_data: Dict[str, Any] = field(default_factory=dict)
    last_activity: Optional[datetime] = None


@dataclass
class UnipileCalendarEvent:
    """Evento de calendário via SDK oficial."""
    id: str
    calendar_id: str
    title: str
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    location: Optional[str] = None
    attendees: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class UnipileMessage:
    """Mensagem via SDK oficial."""
    id: str
    channel_id: str
    content: str
    sender: Optional[str] = None
    timestamp: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class UnipileOfficialSDK:
    """Serviço usando SDK oficial unified-python-sdk."""
    
    def __init__(self, api_key: Optional[str] = None, server_region: str = "north-america"):
        self.logger = logging.getLogger(__name__)
        
        # Configurar credenciais
        self.api_key = api_key or os.getenv("UNIPILE_API_TOKEN") or os.getenv("UNIFIED_API_KEY")
        
        if not self.api_key:
            self.logger.warning("⚠️ API key não configurada. Configure UNIPILE_API_TOKEN ou UNIFIED_API_KEY")
            raise ValueError("API key é obrigatória para usar o SDK oficial")
        
        # Configurar servidor por região
        server_urls = {
            "north-america": "https://api.unified.to",
            "europe": "https://api-eu.unified.to", 
            "australia": "https://api-au.unified.to"
        }
        
        server_url = server_urls.get(server_region, server_urls["north-america"])
        
        # Inicializar cliente oficial
        try:
            self.client = UnifiedTo(
                security=shared.Security(jwt=self.api_key),
                server_url=server_url
            )
            self.logger.info(f"✅ SDK oficial inicializado - região: {server_region}")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar SDK oficial: {e}")
            raise
    
    # ===== MÉTODOS DE CONECTIVIDADE =====
    
    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde da conexão com API."""
        try:
            # Testar listagem de conexões como health check
            result = self.client.connection.list_unified_connections()
            
            return {
                "status": "healthy",
                "sdk_version": "unified-python-sdk-v0.48.9",
                "connections_available": len(result.connections or []),
                "timestamp": datetime.now().isoformat(),
                "success": True
            }
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro no health check: {e.message}")
            return {
                "status": "error",
                "sdk_version": "unified-python-sdk-v0.48.9", 
                "error": e.message,
                "status_code": e.status_code,
                "timestamp": datetime.now().isoformat(),
                "success": False
            }
        except Exception as e:
            self.logger.error(f"Erro no health check: {e}")
            return {
                "status": "error",
                "sdk_version": "unified-python-sdk-v0.48.9",
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
                "success": False
            }
    
    async def list_connections(self) -> List[Dict[str, Any]]:
        """Lista todas as conexões ativas."""
        try:
            result = self.client.connection.list_unified_connections()
            
            connections = []
            for conn in (result.connections or []):
                connections.append({
                    "id": conn.id,
                    "integration_type": conn.integration_type,
                    "environment": conn.environment,
                    "categories": conn.categories or [],
                    "auth": conn.auth,
                    "is_paused": conn.is_paused,
                    "created_at": conn.created_at.isoformat() if conn.created_at else None,
                    "updated_at": conn.updated_at.isoformat() if conn.updated_at else None
                })
            
            self.logger.info(f"Listadas {len(connections)} conexões via SDK oficial")
            return connections
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao listar conexões: {e.message}")
            return []
        except Exception as e:
            self.logger.error(f"Erro ao listar conexões: {e}")
            return []
    
    async def create_connection(self, integration_type: str, auth_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Cria nova conexão com provedor."""
        try:
            connection_data = {
                "integration_type": integration_type,
                "auth": auth_data,
                "categories": ["messaging", "calendar", "crm"],  # Categorias padrão
                "environment": "Production"
            }
            
            result = self.client.connection.create_unified_connection(request=connection_data)
            
            if result.connection:
                self.logger.info(f"✅ Conexão criada: {integration_type}")
                return {
                    "id": result.connection.id,
                    "integration_type": result.connection.integration_type,
                    "status": "created",
                    "timestamp": datetime.now().isoformat()
                }
            
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao criar conexão: {e.message}")
            return None
        except Exception as e:
            self.logger.error(f"Erro ao criar conexão: {e}")
            return None
    
    # ===== MÉTODOS DE CALENDÁRIO (migração 1:1) =====
    
    async def create_calendar_event(self, connection_id: str, event_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Cria evento de calendário - NOME IDÊNTICO ao wrapper!"""
        try:
            result = self.client.calendar.create_calendar_event(request={
                "connection_id": connection_id,
                "calendar_event": event_data
            })
            
            if result.calendar_event:
                return {
                    "id": result.calendar_event.id,
                    "title": result.calendar_event.title,
                    "start_at": result.calendar_event.start_at,
                    "end_at": result.calendar_event.end_at,
                    "timestamp": datetime.now().isoformat()
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao criar evento: {e.message}")
            return None
    
    async def list_calendar_events(self, connection_id: str, calendar_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Lista eventos de calendário - NOME IDÊNTICO ao wrapper!"""
        try:
            params = {"connection_id": connection_id}
            if calendar_id:
                params["calendar_id"] = calendar_id
                
            result = self.client.calendar.list_calendar_events(request=params)
            
            events = []
            for event in (result.calendar_events or []):
                events.append({
                    "id": event.id,
                    "title": event.title,
                    "description": event.description,
                    "start_at": event.start_at,
                    "end_at": event.end_at,
                    "location": event.location,
                    "attendees": event.attendees or []
                })
            
            return events
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao listar eventos: {e.message}")
            return []
    
    async def get_calendar_event(self, connection_id: str, event_id: str) -> Optional[Dict[str, Any]]:
        """Obtém evento específico - NOME IDÊNTICO ao wrapper!"""
        try:
            result = self.client.calendar.get_calendar_event(request={
                "connection_id": connection_id,
                "id": event_id
            })
            
            if result.calendar_event:
                event = result.calendar_event
                return {
                    "id": event.id,
                    "title": event.title,
                    "description": event.description,
                    "start_at": event.start_at,
                    "end_at": event.end_at,
                    "location": event.location,
                    "attendees": event.attendees or [],
                    "created_at": event.created_at,
                    "updated_at": event.updated_at
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao obter evento: {e.message}")
            return None
    
    async def update_calendar_event(self, connection_id: str, event_id: str, event_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Atualiza evento - NOME IDÊNTICO ao wrapper!"""
        try:
            result = self.client.calendar.update_calendar_event(request={
                "connection_id": connection_id,
                "id": event_id,
                "calendar_event": event_data
            })
            
            if result.calendar_event:
                return {
                    "id": result.calendar_event.id,
                    "title": result.calendar_event.title,
                    "updated_at": result.calendar_event.updated_at,
                    "timestamp": datetime.now().isoformat()
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao atualizar evento: {e.message}")
            return None
    
    async def delete_calendar_event(self, connection_id: str, event_id: str) -> bool:
        """Remove evento de calendário."""
        try:
            self.client.calendar.remove_calendar_event(request={
                "connection_id": connection_id,
                "id": event_id
            })
            
            self.logger.info(f"✅ Evento removido: {event_id}")
            return True
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao remover evento: {e.message}")
            return False
    
    # ===== MÉTODOS DE MESSAGING/EMAIL =====
    
    async def send_email(self, connection_id: str, message_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Envia email via SDK oficial."""
        try:
            result = self.client.messaging.create_messaging_message(request={
                "connection_id": connection_id,
                "messaging_message": message_data
            })
            
            if result.messaging_message:
                return {
                    "id": result.messaging_message.id,
                    "subject": result.messaging_message.subject,
                    "sent_at": result.messaging_message.created_at,
                    "timestamp": datetime.now().isoformat()
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao enviar email: {e.message}")
            return None
    
    async def list_emails(self, connection_id: str, channel_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Lista emails/mensagens."""
        try:
            params = {"connection_id": connection_id}
            if channel_id:
                params["channel_id"] = channel_id
                
            result = self.client.messaging.list_messaging_messages(request=params)
            
            messages = []
            for msg in (result.messaging_messages or []):
                messages.append({
                    "id": msg.id,
                    "subject": msg.subject,
                    "body": msg.body,
                    "from": msg.from_,
                    "to": msg.to,
                    "created_at": msg.created_at,
                    "channel_id": msg.channel_id
                })
            
            return messages
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao listar mensagens: {e.message}")
            return []
    
    # ===== MÉTODOS DE CRM/LINKEDIN =====
    
    async def get_crm_contacts(self, connection_id: str) -> List[Dict[str, Any]]:
        """Lista contatos CRM (LinkedIn, etc)."""
        try:
            result = self.client.crm.list_crm_contacts(request={
                "connection_id": connection_id
            })
            
            contacts = []
            for contact in (result.crm_contacts or []):
                contacts.append({
                    "id": contact.id,
                    "name": contact.name,
                    "email": contact.emails[0] if contact.emails else None,
                    "company": contact.company,
                    "title": contact.title,
                    "created_at": contact.created_at
                })
            
            return contacts
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao listar contatos CRM: {e.message}")
            return []
    
    async def get_company_profile(self, connection_id: str, company_id: str) -> Optional[Dict[str, Any]]:
        """Obtém perfil de empresa via CRM."""
        try:
            result = self.client.crm.get_crm_company(request={
                "connection_id": connection_id,
                "id": company_id
            })
            
            if result.crm_company:
                company = result.crm_company
                return {
                    "id": company.id,
                    "name": company.name,
                    "website": company.website,
                    "industry": company.industry,
                    "description": company.description,
                    "employees_count": company.num_employees,
                    "created_at": company.created_at
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao obter empresa: {e.message}")
            return None
    
    # ===== MÉTODOS DE WEBHOOKS =====
    
    async def create_webhook(self, connection_id: str, webhook_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Cria webhook."""
        try:
            result = self.client.webhook.create_unified_webhook(request={
                "connection_id": connection_id,
                "webhook": webhook_data
            })
            
            if result.webhook:
                return {
                    "id": result.webhook.id,
                    "url": result.webhook.hook_url,
                    "events": result.webhook.events,
                    "created_at": result.webhook.created_at
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao criar webhook: {e.message}")
            return None
    
    async def list_webhooks(self, connection_id: str) -> List[Dict[str, Any]]:
        """Lista webhooks."""
        try:
            result = self.client.webhook.list_unified_webhooks(request={
                "connection_id": connection_id
            })
            
            webhooks = []
            for webhook in (result.webhooks or []):
                webhooks.append({
                    "id": webhook.id,
                    "url": webhook.hook_url,
                    "events": webhook.events,
                    "is_healthy": webhook.is_healthy,
                    "created_at": webhook.created_at
                })
            
            return webhooks
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro ao listar webhooks: {e.message}")
            return []
    
    # ===== INTEGRAÇÃO COM SISTEMA HÍBRIDO =====
    
    async def get_communication_data(self, oab_number: str, email: Optional[str] = None) -> Tuple[Optional[Dict], DataTransparency]:
        """
        Busca dados de comunicação usando SDK oficial.
        Compatibilidade com sistema híbrido existente.
        """
        transparency = DataTransparency(
            source=DataSource.UNIPILE,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url="https://api.unified.to",
            api_version="unified-python-sdk-v0.48.9"
        )
        
        try:
            # 1. Listar conexões disponíveis
            connections = await self.list_connections()
            
            if not connections:
                transparency.validation_status = "no_connections"
                transparency.confidence_score = 0.0
                return None, transparency
            
            # 2. Buscar dados de comunicação por conexão
            all_data = {
                "oab_number": oab_number,
                "email": email,
                "connections_found": len(connections),
                "last_updated": datetime.now().isoformat(),
                "data_sources": ["unified_api_official"]
            }
            
            for conn in connections:
                conn_id = conn["id"]
                integration_type = conn["integration_type"]
                
                # Buscar dados conforme tipo de integração
                if "messaging" in conn.get("categories", []):
                    messages = await self.list_emails(conn_id)
                    all_data[f"{integration_type}_messages"] = len(messages)
                
                if "calendar" in conn.get("categories", []):
                    events = await self.list_calendar_events(conn_id)
                    all_data[f"{integration_type}_events"] = len(events)
                
                if "crm" in conn.get("categories", []):
                    contacts = await self.get_crm_contacts(conn_id)
                    all_data[f"{integration_type}_contacts"] = len(contacts)
            
            # 3. Calcular transparência baseada nos dados
            data_points = len([k for k in all_data.keys() if k.endswith(('_messages', '_events', '_contacts'))])
            
            if data_points > 0:
                transparency.confidence_score = min(0.95, 0.6 + (data_points * 0.1))
                transparency.validation_status = "validated"
                transparency.data_freshness_hours = 1
            else:
                transparency.confidence_score = 0.5
                transparency.validation_status = "partial"
                transparency.data_freshness_hours = 24
            
            return all_data, transparency
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados de comunicação: {e}")
            transparency.validation_status = "failed"
            transparency.confidence_score = 0.0
            return None, transparency
    
    # ===== MÉTODOS DE COMPATIBILIDADE =====
    
    async def list_accounts(self) -> List[UnipileAccount]:
        """Método de compatibilidade - mapeia conexões para contas."""
        connections = await self.list_connections()
        
        accounts = []
        for conn in connections:
            account = UnipileAccount(
                id=conn["id"],
                provider=conn["integration_type"],
                email=None,  # SDK oficial não expõe email diretamente
                status="active" if not conn.get("is_paused") else "paused",
                last_sync=datetime.fromisoformat(conn["updated_at"]) if conn["updated_at"] else None
            )
            accounts.append(account)
        
        return accounts
    
    # ===== MÉTODOS EXTRAS DO SDK OFICIAL =====
    
    async def get_enrichment_data(self, domain: str) -> Optional[Dict[str, Any]]:
        """Aproveita funcionalidade de enriquecimento do SDK oficial."""
        try:
            result = self.client.enrich.list_enrich_companies(request={
                "domain": domain
            })
            
            if result.enrich_companies:
                company = result.enrich_companies[0]
                return {
                    "name": company.name,
                    "domain": company.domain,
                    "industry": company.industry,
                    "employees": company.num_employees,
                    "founded": company.founded,
                    "description": company.description
                }
            return None
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro no enriquecimento: {e.message}")
            return None
    
    async def search_people(self, query: str) -> List[Dict[str, Any]]:
        """Busca pessoas usando enriquecimento."""
        try:
            result = self.client.enrich.list_enrich_people(request={
                "name": query
            })
            
            people = []
            for person in (result.enrich_people or []):
                people.append({
                    "name": person.name,
                    "email": person.email,
                    "title": person.title,
                    "company": person.company,
                    "linkedin_url": person.linkedin_url
                })
            
            return people
            
        except errors.UnifiedToError as e:
            self.logger.error(f"Erro na busca de pessoas: {e.message}")
            return []
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        # O SDK oficial gerencia recursos automaticamente
        pass 