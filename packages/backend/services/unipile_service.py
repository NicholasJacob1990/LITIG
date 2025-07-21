# -*- coding: utf-8 -*-
"""
Unipile Service - Integração com API do Unipile
==============================================

Serviço especializado para integração com a API do Unipile para extração
de dados de comunicação, email e networking profissional.

Baseado na documentação oficial:
- https://developer.unipile.com/reference/accountscontroller_listaccounts
- https://github.com/unipile/unipile-node-sdk
- https://developer.unipile.com/docs/api-usage
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
import json
import os

import aiohttp
from dataclasses import dataclass, field

from backend.services.hybrid_legal_data_service import DataSource, DataTransparency


@dataclass
class UnipileAccount:
    """Representação de uma conta conectada no Unipile."""
    id: str
    provider: str  # gmail, outlook, linkedin, etc.
    email: Optional[str] = None
    status: str = "active"
    last_sync: Optional[datetime] = None


@dataclass
class UnipileProfile:
    """Perfil de usuário extraído do Unipile."""
    provider_id: str
    provider: str
    name: str
    email: Optional[str] = None
    profile_data: Dict[str, Any] = field(default_factory=dict)
    last_activity: Optional[datetime] = None


@dataclass
class UnipileCalendar:
    """Representação de um calendário do Unipile."""
    id: str
    name: str
    account_id: str
    provider: str  # google, outlook
    primary: bool = False
    color: Optional[str] = None
    timezone: Optional[str] = None


@dataclass
class UnipileCalendarEvent:
    """Representação de um evento de calendário do Unipile."""
    id: str
    calendar_id: str
    title: str
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    location: Optional[str] = None
    attendees: List[str] = field(default_factory=list)
    reminders: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


class UnipileService:
    """Serviço para integração com API do Unipile."""
    
    def __init__(self, base_url: Optional[str] = None, api_token: Optional[str] = None):
        self.base_url = base_url or "https://api.unipile.com" # /v1 será adicionado no _get_url
        self.api_token = api_token or os.getenv("UNIPILE_API_TOKEN")
        self.dsn = os.getenv("UNIPILE_DSN")  # Data Source Name específico
        self.logger = logging.getLogger(__name__)
        
        if not self.api_token:
            self.logger.warning("UNIPILE_API_TOKEN não configurado. Chamadas para API Unipile falharão.")
    
    def _get_headers(self) -> Dict[str, str]:
        """
        Gera headers para requisições à API Unipile.
        
        Conforme documentação oficial:
        - X-API-KEY: token de autenticação
        - Content-Type: application/json
        """
        if not self.api_token:
            raise ValueError("API token do Unipile (UNIPILE_API_TOKEN) não foi configurado.")

        return {
            "X-API-KEY": self.api_token,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "LITGO-Backend/1.0"
        }
    
    def _get_url(self, endpoint: str) -> str:
        """Constrói URL completa com DSN se necessário."""
        base = f"https://{self.dsn}" if self.dsn else self.base_url
        return f"{base}/api/v1{endpoint}"
    
    async def list_accounts(self) -> List[UnipileAccount]:
        """
        Lista todas as contas conectadas, tratando a paginação com cursor.
        
        Endpoint: GET /api/v1/accounts
        Ref: https://developer.unipile.com/reference/accountscontroller_listaccounts
        """
        all_accounts = []
        cursor = None
        
        try:
            async with aiohttp.ClientSession() as session:
                while True:
                    url = self._get_url("/accounts")
                    headers = self._get_headers()
                    
                    params: Dict[str, Any] = {"limit": 250} # Usar o limite máximo permitido
                    if cursor:
                        params["cursor"] = cursor

                    async with session.get(url, headers=headers, params=params, timeout=15) as response:
                        if response.status == 200:
                            data = await response.json()
                            
                            accounts_data = data.get("items", [])
                            
                            for account_data in accounts_data:
                                account = UnipileAccount(
                                    id=account_data.get("id"),
                                    provider=account_data.get("provider"),
                                    email=account_data.get("login"),
                                    status=account_data.get("status", "active"),
                                    last_sync=self._parse_datetime(account_data.get("last_sync_at"))
                                )
                                all_accounts.append(account)
                            
                            cursor = data.get("cursor")
                            if not cursor:
                                break 
                        
                        elif response.status == 401:
                            self.logger.error("Token de API inválido para Unipile. Verifique a variável de ambiente UNIPILE_API_TOKEN.")
                            break
                        elif response.status == 429:
                            self.logger.warning("Rate limit atingido na API Unipile. Tentando novamente mais tarde.")
                            await asyncio.sleep(5)
                            break
                        else:
                            error_text = await response.text()
                            self.logger.error(f"Erro ao listar contas Unipile: {response.status} - {error_text}")
                            break
                            
            self.logger.info(f"Listadas {len(all_accounts)} contas do Unipile no total.")
            return all_accounts
                        
        except (asyncio.TimeoutError, ValueError) as e:
            self.logger.error(f"Erro na requisição Unipile: {e}")
            return []
        except Exception as e:
            self.logger.error(f"Erro inesperado na requisição Unipile: {e}")
            return []
    
    async def get_profile_by_email(self, email: str) -> Optional[UnipileProfile]:
        """
        Busca perfil de usuário por email.
        
        Endpoint: GET /users/{email}
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/users/{email}")
                headers = self._get_headers()
                
                async with session.get(url, headers=headers, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        return UnipileProfile(
                            provider_id=data.get("provider_id"),
                            provider=data.get("provider"),
                            name=data.get("name", ""),
                            email=data.get("email"),
                            profile_data=data.get("profile_data", {}),
                            last_activity=self._parse_datetime(data.get("last_activity"))
                        )
                    else:
                        self.logger.warning(f"Perfil não encontrado para {email}: {response.status}")
                        return None
                        
        except asyncio.TimeoutError:
            self.logger.error("Timeout na requisição para Unipile API")
            return None
        except (ValueError, Exception) as e:
            self.logger.error(f"Erro na requisição Unipile: {e}")
            return None
    
    async def get_communication_data(self, oab_number: str, email: str = None) -> Tuple[Optional[Dict], DataTransparency]:
        """
        Busca dados de comunicação para um advogado.
        
        Args:
            oab_number: Número OAB do advogado
            email: Email do advogado (opcional)
            
        Returns:
            Tuple com dados e transparência
        """
        transparency = DataTransparency(
            source=DataSource.UNIPILE,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.base_url}/lawyers/{oab_number}",
            api_version="v1"
        )
        
        try:
            # 1. Listar contas para encontrar dados relevantes
            accounts = await self.list_accounts()
            
            # 2. Buscar perfil por email se fornecido
            profile = None
            if email:
                profile = await self.get_profile_by_email(email)
            
            # 3. Buscar dados de comunicação
            communication_data = await self._fetch_communication_metrics(accounts, profile)
            
            if communication_data:
                # Validar dados
                if self._validate_communication_data(communication_data):
                    transparency.confidence_score = 0.75
                    transparency.validation_status = "validated"
                    transparency.data_freshness_hours = self._calculate_freshness(
                        communication_data.get("last_updated")
                    )
                    
                    # Enriquecer dados com informações específicas para advogados
                    enriched_data = self._enrich_lawyer_data(communication_data, oab_number)
                    
                    return enriched_data, transparency
                else:
                    transparency.validation_status = "failed"
                    self.logger.warning(f"Dados inválidos do Unipile para OAB {oab_number}")
            else:
                self.logger.info(f"Nenhum dado de comunicação encontrado para OAB {oab_number}")
                
        except (ValueError, Exception) as e:
            self.logger.error(f"Erro ao buscar dados Unipile: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _fetch_communication_metrics(self, accounts: List[UnipileAccount], profile: Optional[UnipileProfile]) -> Optional[Dict]:
        """Busca métricas de comunicação baseadas nas contas e perfil."""
        if not accounts and not profile:
            return None
        
        metrics = {
            "communication_score": 0.0,
            "email_activity": {},
            "linkedin_activity": {},
            "response_time_avg": 0.0,
            "professional_network_size": 0,
            "last_updated": datetime.now().isoformat()
        }
        
        # Processar contas de email
        email_accounts = [acc for acc in accounts if acc.provider in ["gmail", "outlook", "imap"]]
        if email_accounts:
            metrics["email_activity"] = await self._get_email_metrics(email_accounts)
        
        # Processar conta LinkedIn
        linkedin_accounts = [acc for acc in accounts if acc.provider == "linkedin"]
        if linkedin_accounts:
            metrics["linkedin_activity"] = await self._get_linkedin_metrics(linkedin_accounts)
        
        # Calcular score de comunicação
        metrics["communication_score"] = self._calculate_communication_score(metrics)
        
        return metrics
    
    async def _get_email_metrics(self, accounts: List[UnipileAccount]) -> Dict[str, Any]:
        """Busca métricas de email."""
        # Implementação simplificada - em produção, buscar dados reais
        return {
            "total_emails": 0,
            "response_rate": 0.0,
            "avg_response_time_hours": 0.0,
            "professional_contacts": 0
        }
    
    async def _get_linkedin_metrics(self, accounts: List[UnipileAccount]) -> Dict[str, Any]:
        """Busca métricas do LinkedIn."""
        # Implementação simplificada - em produção, buscar dados reais
        return {
            "connections": 0,
            "posts_last_30d": 0,
            "engagement_rate": 0.0,
            "professional_activity": 0.0
        }
    
    def _calculate_communication_score(self, metrics: Dict) -> float:
        """Calcula score de comunicação baseado nas métricas."""
        score = 0.0
        
        # Email activity (40% do score)
        email_activity = metrics.get("email_activity", {})
        if email_activity.get("response_rate", 0) > 0.7:
            score += 0.4
        elif email_activity.get("response_rate", 0) > 0.5:
            score += 0.2
        
        # LinkedIn activity (35% do score)
        linkedin_activity = metrics.get("linkedin_activity", {})
        if linkedin_activity.get("engagement_rate", 0) > 0.1:
            score += 0.35
        elif linkedin_activity.get("connections", 0) > 500:
            score += 0.2
        
        # Professional network size (25% do score)
        network_size = metrics.get("professional_network_size", 0)
        if network_size > 1000:
            score += 0.25
        elif network_size > 500:
            score += 0.15
        
        return min(score, 1.0)
    
    def _enrich_lawyer_data(self, communication_data: Dict, oab_number: str) -> Dict:
        """Enriquece dados de comunicação com informações específicas para advogados."""
        return {
            "oab_number": oab_number,
            "name": communication_data.get("profile_name", ""),
            "specializations": self._infer_specializations(communication_data),
            "success_rate": communication_data.get("communication_score", 0.0),
            "communication_metrics": communication_data,
            "professional_network": {
                "size": communication_data.get("professional_network_size", 0),
                "quality_score": communication_data.get("communication_score", 0.0)
            },
            "responsiveness": {
                "email_response_time": communication_data.get("email_activity", {}).get("avg_response_time_hours", 0),
                "response_rate": communication_data.get("email_activity", {}).get("response_rate", 0)
            }
        }
    
    def _infer_specializations(self, communication_data: Dict) -> List[str]:
        """Infere especializações baseadas nos dados de comunicação."""
        # Implementação simplificada - em produção, usar NLP/ML
        specializations = []
        
        linkedin_activity = communication_data.get("linkedin_activity", {})
        if linkedin_activity.get("posts_last_30d", 0) > 10:
            specializations.append("Direito Digital")
        
        return specializations or ["Direito Geral"]
    
    def _validate_communication_data(self, data: Dict) -> bool:
        """Valida dados de comunicação do Unipile."""
        required_fields = ["communication_score", "last_updated"]
        return all(field in data for field in required_fields)
    
    def _calculate_freshness(self, last_updated: Optional[str]) -> int:
        """Calcula frescor dos dados em horas."""
        if not last_updated:
            return 24  # Padrão: 24 horas
        
        try:
            updated_time = datetime.fromisoformat(last_updated.replace('Z', '+00:00'))
            delta = datetime.now() - updated_time.replace(tzinfo=None)
            return int(delta.total_seconds() / 3600)
        except:
            return 24
    
    def _parse_datetime(self, date_str: Optional[str]) -> Optional[datetime]:
        """Parse de string de data para datetime."""
        if not date_str:
            return None
        
        try:
            return datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
        except:
            return None
    
    # ========================================
    # 📅 MÉTODOS DE CALENDÁRIO (NOVO v3.0)
    # ========================================
    
    async def list_calendars(self, account_id: str) -> List[UnipileCalendar]:
        """
        Lista todos os calendários de uma conta.
        
        Endpoint: GET /api/v1/calendars
        Ref: https://developer.unipile.com/reference/calendarscontroller_listcalendars
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url("/calendars")
                headers = self._get_headers()
                params = {"account_id": account_id}
                
                async with session.get(url, headers=headers, params=params, timeout=15) as response:
                    if response.status == 200:
                        data = await response.json()
                        calendars = []
                        
                        for cal_data in data.get("items", []):
                            calendar = UnipileCalendar(
                                id=cal_data.get("id"),
                                name=cal_data.get("name", ""),
                                account_id=account_id,
                                provider=cal_data.get("provider", ""),
                                primary=cal_data.get("primary", False),
                                color=cal_data.get("color"),
                                timezone=cal_data.get("timezone")
                            )
                            calendars.append(calendar)
                        
                        self.logger.info(f"Listados {len(calendars)} calendários para conta {account_id}")
                        return calendars
                    
                    elif response.status == 401:
                        self.logger.error("Token de API inválido para Unipile (calendários)")
                        return []
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro ao listar calendários: {response.status} - {error_text}")
                        return []
                        
        except Exception as e:
            self.logger.error(f"Erro ao listar calendários: {e}")
            return []
    
    async def get_calendar(self, calendar_id: str, account_id: str) -> Optional[UnipileCalendar]:
        """
        Obtém um calendário específico.
        
        Endpoint: GET /api/v1/calendars/{calendar_id}
        Ref: https://developer.unipile.com/reference/calendarscontroller_getcalendar
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}")
                headers = self._get_headers()
                params = {"account_id": account_id}
                
                async with session.get(url, headers=headers, params=params, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        return UnipileCalendar(
                            id=data.get("id"),
                            name=data.get("name", ""),
                            account_id=account_id,
                            provider=data.get("provider", ""),
                            primary=data.get("primary", False),
                            color=data.get("color"),
                            timezone=data.get("timezone")
                        )
                    else:
                        self.logger.warning(f"Calendário {calendar_id} não encontrado: {response.status}")
                        return None
                        
        except Exception as e:
            self.logger.error(f"Erro ao obter calendário {calendar_id}: {e}")
            return None
    
    async def list_calendar_events(self, calendar_id: str, limit: int = 100, start_date: Optional[datetime] = None, end_date: Optional[datetime] = None) -> List[UnipileCalendarEvent]:
        """
        Lista eventos de um calendário específico.
        
        Endpoint: GET /api/v1/calendars/{calendar_id}/events
        Ref: https://developer.unipile.com/reference/calendarscontroller_listcalendareventsbycalendar
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}/events")
                headers = self._get_headers()
                
                params = {"limit": limit}
                if start_date:
                    params["start_date"] = start_date.isoformat()
                if end_date:
                    params["end_date"] = end_date.isoformat()
                
                async with session.get(url, headers=headers, params=params, timeout=15) as response:
                    if response.status == 200:
                        data = await response.json()
                        events = []
                        
                        for event_data in data.get("items", []):
                            event = UnipileCalendarEvent(
                                id=event_data.get("id"),
                                calendar_id=calendar_id,
                                title=event_data.get("title", ""),
                                description=event_data.get("description"),
                                start_time=self._parse_datetime(event_data.get("start_time")),
                                end_time=self._parse_datetime(event_data.get("end_time")),
                                location=event_data.get("location"),
                                attendees=event_data.get("attendees", []),
                                reminders=event_data.get("reminders", []),
                                metadata=event_data.get("metadata", {})
                            )
                            events.append(event)
                        
                        self.logger.info(f"Listados {len(events)} eventos do calendário {calendar_id}")
                        return events
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro ao listar eventos: {response.status} - {error_text}")
                        return []
                        
        except Exception as e:
            self.logger.error(f"Erro ao listar eventos do calendário {calendar_id}: {e}")
            return []
    
    async def create_calendar_event(self, calendar_id: str, event_data: Dict[str, Any]) -> Optional[UnipileCalendarEvent]:
        """
        Cria um novo evento no calendário.
        
        Endpoint: POST /api/v1/calendars/{calendar_id}/events
        Ref: https://developer.unipile.com/reference/calendarscontroller_createcalendarevent
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}/events")
                headers = self._get_headers()
                
                async with session.post(url, headers=headers, json=event_data, timeout=15) as response:
                    if response.status in [200, 201]:
                        data = await response.json()
                        
                        event = UnipileCalendarEvent(
                            id=data.get("id"),
                            calendar_id=calendar_id,
                            title=data.get("title", ""),
                            description=data.get("description"),
                            start_time=self._parse_datetime(data.get("start_time")),
                            end_time=self._parse_datetime(data.get("end_time")),
                            location=data.get("location"),
                            attendees=data.get("attendees", []),
                            reminders=data.get("reminders", []),
                            metadata=data.get("metadata", {})
                        )
                        
                        self.logger.info(f"Evento criado: {event.title} em {calendar_id}")
                        return event
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro ao criar evento: {response.status} - {error_text}")
                        return None
                        
        except Exception as e:
            self.logger.error(f"Erro ao criar evento no calendário {calendar_id}: {e}")
            return None
    
    async def get_calendar_event(self, calendar_id: str, event_id: str) -> Optional[UnipileCalendarEvent]:
        """
        Obtém um evento específico.
        
        Endpoint: GET /api/v1/calendars/{calendar_id}/events/{event_id}
        Ref: https://developer.unipile.com/reference/calendarscontroller_getcalendarevent
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}/events/{event_id}")
                headers = self._get_headers()
                
                async with session.get(url, headers=headers, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        return UnipileCalendarEvent(
                            id=data.get("id"),
                            calendar_id=calendar_id,
                            title=data.get("title", ""),
                            description=data.get("description"),
                            start_time=self._parse_datetime(data.get("start_time")),
                            end_time=self._parse_datetime(data.get("end_time")),
                            location=data.get("location"),
                            attendees=data.get("attendees", []),
                            reminders=data.get("reminders", []),
                            metadata=data.get("metadata", {})
                        )
                    else:
                        self.logger.warning(f"Evento {event_id} não encontrado: {response.status}")
                        return None
                        
        except Exception as e:
            self.logger.error(f"Erro ao obter evento {event_id}: {e}")
            return None
    
    async def edit_calendar_event(self, calendar_id: str, event_id: str, event_data: Dict[str, Any]) -> Optional[UnipileCalendarEvent]:
        """
        Edita um evento existente.
        
        Endpoint: PUT /api/v1/calendars/{calendar_id}/events/{event_id}
        Ref: https://developer.unipile.com/reference/calendarscontroller_editcalendarevent
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}/events/{event_id}")
                headers = self._get_headers()
                
                async with session.put(url, headers=headers, json=event_data, timeout=15) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        event = UnipileCalendarEvent(
                            id=data.get("id"),
                            calendar_id=calendar_id,
                            title=data.get("title", ""),
                            description=data.get("description"),
                            start_time=self._parse_datetime(data.get("start_time")),
                            end_time=self._parse_datetime(data.get("end_time")),
                            location=data.get("location"),
                            attendees=data.get("attendees", []),
                            reminders=data.get("reminders", []),
                            metadata=data.get("metadata", {})
                        )
                        
                        self.logger.info(f"Evento editado: {event.title}")
                        return event
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro ao editar evento: {response.status} - {error_text}")
                        return None
                        
        except Exception as e:
            self.logger.error(f"Erro ao editar evento {event_id}: {e}")
            return None
    
    async def delete_calendar_event(self, calendar_id: str, event_id: str) -> bool:
        """
        Deleta um evento.
        
        Endpoint: DELETE /api/v1/calendars/{calendar_id}/events/{event_id}
        Ref: https://developer.unipile.com/reference/calendarscontroller_deletecalendarevent
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = self._get_url(f"/calendars/{calendar_id}/events/{event_id}")
                headers = self._get_headers()
                
                async with session.delete(url, headers=headers, timeout=10) as response:
                    if response.status in [200, 204]:
                        self.logger.info(f"Evento {event_id} deletado com sucesso")
                        return True
                    else:
                        error_text = await response.text()
                        self.logger.error(f"Erro ao deletar evento: {response.status} - {error_text}")
                        return False
                        
        except Exception as e:
            self.logger.error(f"Erro ao deletar evento {event_id}: {e}")
            return False
    
    async def create_legal_event(self, calendar_id: str, legal_event_data: Dict[str, Any]) -> Optional[UnipileCalendarEvent]:
        """
        Cria um evento jurídico LITIG-1 com formatação específica.
        """
        # Formatar dados do evento jurídico
        formatted_description = self._format_legal_event_description(legal_event_data)
        
        event_data = {
            "title": legal_event_data.get("title", ""),
            "description": formatted_description,
            "start_time": legal_event_data.get("start_time"),
            "end_time": legal_event_data.get("end_time"),
            "location": legal_event_data.get("location"),
            "attendees": legal_event_data.get("attendees", []),
            "reminders": legal_event_data.get("reminders", self._get_default_legal_reminders()),
            "metadata": {
                **legal_event_data.get("metadata", {}),
                "source": "LITIG-1",
                "case_id": legal_event_data.get("case_id"),
                "case_type": legal_event_data.get("case_type"),
                "lawyer_id": legal_event_data.get("lawyer_id"),
                "client_id": legal_event_data.get("client_id"),
                "event_category": legal_event_data.get("event_category", "legal_appointment")
            }
        }
        
        return await self.create_calendar_event(calendar_id, event_data)
    
    async def sync_legal_events_with_calendar(self, account_id: str, litig_events: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Sincroniza eventos LITIG-1 com calendário externo.
        """
        try:
            # Listar calendários disponíveis
            calendars = await self.list_calendars(account_id)
            if not calendars:
                return {
                    "success": False,
                    "error": "Nenhum calendário encontrado para a conta"
                }
            
            # Encontrar calendário primário ou usar o primeiro
            primary_calendar = next((cal for cal in calendars if cal.primary), calendars[0])
            
            results = []
            success_count = 0
            error_count = 0
            
            for litig_event in litig_events:
                result = await self.create_legal_event(primary_calendar.id, litig_event)
                
                event_result = {
                    "case_id": litig_event.get("case_id"),
                    "title": litig_event.get("title"),
                    "success": result is not None,
                    "calendar_event_id": result.id if result else None,
                    "error": None if result else "Falha ao criar evento"
                }
                
                results.append(event_result)
                
                if result:
                    success_count += 1
                else:
                    error_count += 1
            
            return {
                "success": True,
                "calendar_id": primary_calendar.id,
                "calendar_name": primary_calendar.name,
                "synced_events": results,
                "success_count": success_count,
                "error_count": error_count,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Erro ao sincronizar eventos legais: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def _format_legal_event_description(self, legal_event_data: Dict[str, Any]) -> str:
        """Formata descrição para eventos jurídicos."""
        parts = [
            legal_event_data.get("description", ""),
            "",
            "🏛️ Evento LITIG-1",
            f"📋 Caso: {legal_event_data.get('case_number', legal_event_data.get('case_id', 'N/A'))}",
            f"⚖️ Tipo: {legal_event_data.get('case_type', 'Jurídico')}",
            f"👤 Cliente: {legal_event_data.get('client_name', 'N/A')}",
            f"👨‍💼 Advogado: {legal_event_data.get('lawyer_name', 'N/A')}"
        ]
        
        if legal_event_data.get("urgency"):
            parts.append(f"🚨 Urgência: {legal_event_data.get('urgency')}")
        
        if legal_event_data.get("notes"):
            parts.extend(["", "📝 Observações:", legal_event_data.get("notes")])
        
        return "\n".join(filter(None, parts))
    
    def _get_default_legal_reminders(self) -> List[Dict[str, Any]]:
        """Define lembretes padrão para eventos jurídicos."""
        return [
            {"method": "email", "minutes": 24 * 60},  # 1 dia antes
            {"method": "popup", "minutes": 2 * 60},   # 2 horas antes
            {"method": "popup", "minutes": 30}        # 30 minutos antes
        ]

    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde da conexão com Unipile."""
        try:
            accounts = await self.list_accounts()
            return {
                "status": "healthy",
                "connected_accounts": len(accounts),
                "api_endpoint": self.base_url,
                "has_token": bool(self.api_token),
                "calendar_support": True,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            } 