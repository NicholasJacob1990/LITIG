# -*- coding: utf-8 -*-
"""
Unipile Compatibility Layer - Camada de Compatibilidade
======================================================

Esta camada permite usar tanto o wrapper Node.js antigo quanto o SDK oficial
Python, facilitando a migração gradual e mantendo compatibilidade.

Funcionalidades:
- Auto-fallback entre SDK oficial e wrapper Node.js
- Interface unificada para ambos os serviços
- Monitoramento de performance e disponibilidade
- Migração gradual sem breaking changes
"""

import asyncio
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple, Union
from dataclasses import dataclass
from enum import Enum

# SDK oficial
try:
    from backend.services.unipile_official_sdk import UnipileOfficialSDK
    SDK_OFFICIAL_AVAILABLE = True
except ImportError as e:
    SDK_OFFICIAL_AVAILABLE = False
    logging.warning(f"SDK oficial não disponível: {e}")

# Wrapper Node.js existente
try:
    from backend.services.unipile_sdk_wrapper import UnipileSDKWrapper, UnipileAccount, UnipileProfile
    WRAPPER_NODEJS_AVAILABLE = True
except ImportError as e:
    WRAPPER_NODEJS_AVAILABLE = False
    logging.warning(f"Wrapper Node.js não disponível: {e}")
    
    # Fallback classes se wrapper não disponível
    from dataclasses import dataclass
    from datetime import datetime
    from typing import Optional
    
    @dataclass
    class UnipileAccount:
        id: str
        provider: str
        email: Optional[str] = None
        status: str = "active"
        last_sync: Optional[datetime] = None
    
    @dataclass
    class UnipileProfile:
        provider_id: str
        provider: str
        name: str
        email: Optional[str] = None
        profile_data: Dict[str, Any] = None
        last_activity: Optional[datetime] = None
        
        def __post_init__(self):
            if self.profile_data is None:
                self.profile_data = {}

# Sistema híbrido
try:
    from backend.services.hybrid_legal_data_service import DataSource, DataTransparency
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


class ServiceType(Enum):
    """Tipos de serviço disponíveis."""
    SDK_OFFICIAL = "sdk_official"
    WRAPPER_NODEJS = "wrapper_nodejs"
    AUTO_FALLBACK = "auto_fallback"


@dataclass
class ServiceHealth:
    """Status de saúde de um serviço."""
    service_type: ServiceType
    is_healthy: bool
    response_time_ms: float
    last_check: datetime
    error_message: Optional[str] = None


class UnipileCompatibilityLayer:
    """
    Camada de compatibilidade que unifica acesso ao SDK oficial e wrapper Node.js.
    """
    
    def __init__(self, preferred_service: ServiceType = ServiceType.AUTO_FALLBACK):
        self.logger = logging.getLogger(__name__)
        self.preferred_service = preferred_service
        
        # Inicializar serviços disponíveis
        self.official_sdk = None
        self.nodejs_wrapper = None
        self.service_health = {}
        
        self._initialize_services()
    
    def _initialize_services(self):
        """Inicializa serviços disponíveis."""
        
        # Tentar inicializar SDK oficial
        if SDK_OFFICIAL_AVAILABLE:
            try:
                api_key = os.getenv("UNIPILE_API_TOKEN") or os.getenv("UNIFIED_API_KEY")
                if api_key:
                    self.official_sdk = UnipileOfficialSDK(api_key=api_key)
                    self.logger.info("✅ SDK oficial inicializado")
                else:
                    self.logger.warning("⚠️ SDK oficial: API key não encontrada")
            except Exception as e:
                self.logger.error(f"❌ Erro ao inicializar SDK oficial: {e}")
        
        # Tentar inicializar wrapper Node.js
        if WRAPPER_NODEJS_AVAILABLE:
            try:
                self.nodejs_wrapper = UnipileSDKWrapper()
                self.logger.info("✅ Wrapper Node.js inicializado")
            except Exception as e:
                self.logger.error(f"❌ Erro ao inicializar wrapper Node.js: {e}")
        
        # Verificar se pelo menos um serviço está disponível
        if not self.official_sdk and not self.nodejs_wrapper:
            raise RuntimeError("❌ Nenhum serviço Unipile disponível")
    
    async def _check_service_health(self, service_type: ServiceType) -> ServiceHealth:
        """Verifica saúde de um serviço específico."""
        start_time = datetime.now()
        
        try:
            if service_type == ServiceType.SDK_OFFICIAL and self.official_sdk:
                result = await self.official_sdk.health_check()
                is_healthy = result.get("success", False) or result.get("status") == "healthy"
                
            elif service_type == ServiceType.WRAPPER_NODEJS and self.nodejs_wrapper:
                result = await self.nodejs_wrapper.health_check()
                is_healthy = result.get("success", False)
                
            else:
                is_healthy = False
                result = {"error": "Serviço não disponível"}
            
            response_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return ServiceHealth(
                service_type=service_type,
                is_healthy=is_healthy,
                response_time_ms=response_time,
                last_check=datetime.now(),
                error_message=result.get("error") if not is_healthy else None
            )
            
        except Exception as e:
            response_time = (datetime.now() - start_time).total_seconds() * 1000
            return ServiceHealth(
                service_type=service_type,
                is_healthy=False,
                response_time_ms=response_time,
                last_check=datetime.now(),
                error_message=str(e)
            )
    
    async def _get_best_service(self) -> Tuple[Union['UnipileOfficialSDK', 'UnipileSDKWrapper'], ServiceType]:
        """Determina o melhor serviço disponível baseado em saúde e preferência."""
        
        # Verificar saúde dos serviços
        if self.official_sdk:
            official_health = await self._check_service_health(ServiceType.SDK_OFFICIAL)
            self.service_health[ServiceType.SDK_OFFICIAL] = official_health
        
        if self.nodejs_wrapper:
            nodejs_health = await self._check_service_health(ServiceType.WRAPPER_NODEJS)
            self.service_health[ServiceType.WRAPPER_NODEJS] = nodejs_health
        
        # Lógica de seleção baseada na preferência
        if self.preferred_service == ServiceType.SDK_OFFICIAL:
            if self.official_sdk and self.service_health.get(ServiceType.SDK_OFFICIAL, {}).is_healthy:
                return self.official_sdk, ServiceType.SDK_OFFICIAL
            elif self.nodejs_wrapper and self.service_health.get(ServiceType.WRAPPER_NODEJS, {}).is_healthy:
                self.logger.warning("🔄 Fallback para wrapper Node.js (SDK oficial não disponível)")
                return self.nodejs_wrapper, ServiceType.WRAPPER_NODEJS
        
        elif self.preferred_service == ServiceType.WRAPPER_NODEJS:
            if self.nodejs_wrapper and self.service_health.get(ServiceType.WRAPPER_NODEJS, {}).is_healthy:
                return self.nodejs_wrapper, ServiceType.WRAPPER_NODEJS
            elif self.official_sdk and self.service_health.get(ServiceType.SDK_OFFICIAL, {}).is_healthy:
                self.logger.warning("🔄 Fallback para SDK oficial (wrapper Node.js não disponível)")
                return self.official_sdk, ServiceType.SDK_OFFICIAL
        
        else:  # AUTO_FALLBACK
            # Preferir SDK oficial se ambos estão saudáveis
            official_ok = self.official_sdk and self.service_health.get(ServiceType.SDK_OFFICIAL, {}).is_healthy
            nodejs_ok = self.nodejs_wrapper and self.service_health.get(ServiceType.WRAPPER_NODEJS, {}).is_healthy
            
            if official_ok and nodejs_ok:
                # Comparar performance se ambos disponíveis
                official_time = self.service_health[ServiceType.SDK_OFFICIAL].response_time_ms
                nodejs_time = self.service_health[ServiceType.WRAPPER_NODEJS].response_time_ms
                
                if official_time <= nodejs_time * 1.2:  # 20% de tolerância
                    self.logger.info("🚀 Usando SDK oficial (melhor performance)")
                    return self.official_sdk, ServiceType.SDK_OFFICIAL
                else:
                    self.logger.info("⚡ Usando wrapper Node.js (melhor performance)")
                    return self.nodejs_wrapper, ServiceType.WRAPPER_NODEJS
            
            elif official_ok:
                return self.official_sdk, ServiceType.SDK_OFFICIAL
            elif nodejs_ok:
                return self.nodejs_wrapper, ServiceType.WRAPPER_NODEJS
        
        raise RuntimeError("❌ Nenhum serviço Unipile saudável disponível")
    
    # ===== MÉTODOS UNIFICADOS =====
    
    async def health_check(self) -> Dict[str, Any]:
        """Health check unificado."""
        try:
            service, service_type = await self._get_best_service()
            result = await service.health_check()
            
            return {
                **result,
                "service_used": service_type.value,
                "compatibility_layer": "v1.0",
                "services_available": {
                    "sdk_official": self.official_sdk is not None,
                    "wrapper_nodejs": self.nodejs_wrapper is not None
                },
                "service_health": {
                    k.value: {
                        "healthy": v.is_healthy,
                        "response_time_ms": v.response_time_ms,
                        "last_check": v.last_check.isoformat(),
                        "error": v.error_message
                    }
                    for k, v in self.service_health.items()
                }
            }
            
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "compatibility_layer": "v1.0",
                "timestamp": datetime.now().isoformat()
            }
    
    async def list_accounts(self) -> List[Union[UnipileAccount, Dict[str, Any]]]:
        """Lista contas usando o melhor serviço disponível."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                # SDK oficial retorna lista de dicionários, converter para UnipileAccount
                accounts_data = await service.list_connections()
                accounts = []
                
                for conn in accounts_data:
                    account = UnipileAccount(
                        id=conn["id"],
                        provider=conn["integration_type"],
                        email=None,  # SDK oficial não expõe email diretamente
                        status="active" if not conn.get("is_paused") else "paused",
                        last_sync=datetime.fromisoformat(conn["updated_at"]) if conn.get("updated_at") else None
                    )
                    accounts.append(account)
                
                return accounts
                
            else:  # WRAPPER_NODEJS
                return await service.list_accounts()
            
        except Exception as e:
            self.logger.error(f"Erro ao listar contas: {e}")
            return []
    
    async def create_calendar_event(self, connection_id: str, event_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Cria evento de calendário - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                return await service.create_calendar_event(connection_id, event_data)
            else:  # WRAPPER_NODEJS
                # Wrapper Node.js pode ter interface ligeiramente diferente
                return await service.create_calendar_event(connection_id, event_data)
            
        except Exception as e:
            self.logger.error(f"Erro ao criar evento: {e}")
            return None
    
    async def list_calendar_events(self, connection_id: str, calendar_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Lista eventos de calendário - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                return await service.list_calendar_events(connection_id, calendar_id)
            else:  # WRAPPER_NODEJS
                return await service.list_calendar_events(connection_id, calendar_id)
            
        except Exception as e:
            self.logger.error(f"Erro ao listar eventos: {e}")
            return []
    
    async def send_email(self, connection_id: str, message_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Envia email - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                return await service.send_email(connection_id, message_data)
            else:  # WRAPPER_NODEJS
                # Adaptar interface se necessário
                return await service.send_email(connection_id, message_data)
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar email: {e}")
            return None
    
    async def list_emails(self, connection_id: str, channel_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Lista emails - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                return await service.list_emails(connection_id, channel_id)
            else:  # WRAPPER_NODEJS
                return await service.list_emails(connection_id, channel_id)
            
        except Exception as e:
            self.logger.error(f"Erro ao listar emails: {e}")
            return []
    
    async def create_webhook(self, connection_id: str, webhook_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Cria webhook - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            if service_type == ServiceType.SDK_OFFICIAL:
                return await service.create_webhook(connection_id, webhook_data)
            else:  # WRAPPER_NODEJS
                return await service.create_webhook(connection_id, webhook_data)
            
        except Exception as e:
            self.logger.error(f"Erro ao criar webhook: {e}")
            return None
    
    async def get_communication_data(self, oab_number: str, email: Optional[str] = None) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados de comunicação - interface unificada."""
        try:
            service, service_type = await self._get_best_service()
            
            result = await service.get_communication_data(oab_number, email)
            
            # Adicionar informações sobre o serviço usado
            if result[0]:  # Se há dados
                result[0]["service_used"] = service_type.value
                result[0]["compatibility_layer"] = "v1.0"
            
            # Atualizar transparência
            if result[1]:
                result[1].api_version = f"{result[1].api_version}-compatibility-layer"
            
            return result
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados de comunicação: {e}")
            transparency = DataTransparency(
                source=DataSource.UNIPILE,
                last_updated=datetime.now(),
                confidence_score=0.0,
                data_freshness_hours=0,
                validation_status="failed",
                source_url="compatibility-layer",
                api_version="compatibility-layer-v1.0"
            )
            return None, transparency
    
    # ===== MÉTODOS DE MONITORAMENTO =====
    
    async def get_service_metrics(self) -> Dict[str, Any]:
        """Retorna métricas de performance dos serviços."""
        return {
            "timestamp": datetime.now().isoformat(),
            "preferred_service": self.preferred_service.value,
            "services": {
                service_type.value: {
                    "available": health.is_healthy,
                    "response_time_ms": health.response_time_ms,
                    "last_check": health.last_check.isoformat(),
                    "error": health.error_message
                }
                for service_type, health in self.service_health.items()
            }
        }
    
    async def switch_service(self, new_service: ServiceType) -> Dict[str, Any]:
        """Permite alternar manualmente entre serviços."""
        old_service = self.preferred_service
        self.preferred_service = new_service
        
        return {
            "previous_service": old_service.value,
            "new_service": new_service.value,
            "timestamp": datetime.now().isoformat(),
            "status": "switched"
        }


# ===== INSTÂNCIA GLOBAL =====

# Instância global da camada de compatibilidade
_compatibility_layer: Optional[UnipileCompatibilityLayer] = None


def get_unipile_service(preferred_service: ServiceType = ServiceType.AUTO_FALLBACK) -> UnipileCompatibilityLayer:
    """
    Factory function para obter instância da camada de compatibilidade.
    
    Args:
        preferred_service: Serviço preferido (AUTO_FALLBACK por padrão)
    
    Returns:
        Instância da camada de compatibilidade
    """
    global _compatibility_layer
    
    if _compatibility_layer is None:
        _compatibility_layer = UnipileCompatibilityLayer(preferred_service=preferred_service)
    
    return _compatibility_layer


# ===== FUNÇÕES DE CONVENIÊNCIA =====

async def health_check() -> Dict[str, Any]:
    """Health check de conveniência."""
    service = get_unipile_service()
    return await service.health_check()


async def list_accounts() -> List[Union[UnipileAccount, Dict[str, Any]]]:
    """Lista contas de conveniência."""
    service = get_unipile_service()
    return await service.list_accounts()


async def get_communication_data(oab_number: str, email: Optional[str] = None) -> Tuple[Optional[Dict], DataTransparency]:
    """Busca dados de comunicação de conveniência."""
    service = get_unipile_service()
    return await service.get_communication_data(oab_number, email) 