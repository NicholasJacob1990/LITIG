# packages/backend/services/auto_context_service.py
from typing import Optional, Dict, Any
from datetime import datetime
import json
from enum import Enum

class OperationMode(Enum):
    PLATFORM_WORK = "platform_work"        # Trabalho da plataforma (padrão)
    PERSONAL_CLIENT = "personal_client"     # Cliente pessoal

class AutoContextService:
    """
    Serviço para detecção automática de contexto operacional
    SOLUÇÃO 3: Sem toggle manual - contexto detectado automaticamente
    """
    
    def __init__(self, supabase_client, audit_service):
        self.supabase = supabase_client
        self.audit_service = audit_service
    
    async def detect_context_for_action(
        self,
        user_id: str,
        current_route: str,
        action_data: Dict[str, Any],
        session_id: str
    ) -> OperationMode:
        """
        Detecta automaticamente o contexto baseado na rota e dados da ação
        """
        # Verificar se usuário é Super Associado
        if not await self._is_super_associate(user_id):
            return OperationMode.PLATFORM_WORK
        
        # Regras de detecção automática
        context = self._analyze_context_signals(current_route, action_data, user_id)
        
        # Registrar mudança automática se necessário
        await self._register_auto_context_switch(user_id, context, session_id, {
            "route": current_route,
            "action_data": action_data,
            "detection_method": "automatic"
        })
        
        return context
    
    def _analyze_context_signals(
        self, 
        route: str, 
        action_data: Dict[str, Any], 
        user_id: str
    ) -> OperationMode:
        """
        Analisa sinais para determinar contexto automaticamente
        """
        # SINAL 1: Rota contém indicadores pessoais
        personal_route_indicators = [
            '/personal/',
            '/my-cases/',
            '/personal-area/',
            '/hire-for-me/',
            '/my-payments/'
        ]
        
        if any(indicator in route for indicator in personal_route_indicators):
            return OperationMode.PERSONAL_CLIENT
        
        # SINAL 2: Dados da ação indicam contexto pessoal
        if action_data.get('is_personal_action') == True:
            return OperationMode.PERSONAL_CLIENT
        
        if action_data.get('client_id') == user_id:
            return OperationMode.PERSONAL_CLIENT
        
        if action_data.get('payment_source') == 'personal_funds':
            return OperationMode.PERSONAL_CLIENT
        
        # SINAL 3: Tipo de entidade sendo manipulada
        personal_entity_types = [
            'personal_case',
            'personal_contract',
            'personal_payment',
            'personal_lawyer_hire'
        ]
        
        if action_data.get('entity_type') in personal_entity_types:
            return OperationMode.PERSONAL_CLIENT
        
        # SINAL 4: Metadata específica
        metadata = action_data.get('metadata', {})
        if metadata.get('on_behalf_of') == user_id:  # Agindo em nome próprio
            return OperationMode.PERSONAL_CLIENT
        
        # PADRÃO: Sempre trabalho da plataforma
        return OperationMode.PLATFORM_WORK
    
    async def get_current_context(self, user_id: str) -> Dict[str, Any]:
        """
        Obtém o contexto atual do usuário (último detectado)
        """
        context_record = await self.supabase.table("auto_context_logs")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("detected_at", desc=True)\
            .limit(1)\
            .execute()
        
        if context_record.data:
            return {
                "current_mode": context_record.data[0]["context_mode"],
                "detected_at": context_record.data[0]["detected_at"],
                "detection_method": context_record.data[0]["detection_method"]
            }
        
        # Contexto padrão para Super Associados
        return {
            "current_mode": OperationMode.PLATFORM_WORK.value,
            "detected_at": datetime.utcnow().isoformat(),
            "detection_method": "default"
        }
    
    async def get_contextual_permissions(
        self, 
        user_id: str, 
        context_mode: OperationMode
    ) -> list:
        """
        Retorna permissões baseadas no contexto detectado
        """
        if context_mode == OperationMode.PERSONAL_CLIENT:
            return [
                "nav.view.client_home",
                "nav.view.find_lawyers",
                "nav.view.client_cases",
                "nav.view.client_messages",
                "nav.view.client_profile",
                "cases.create_personal",
                "lawyers.hire_personal",
                "contracts.manage_personal",
                "payments.personal",
            ]
        
        # PLATFORM_WORK (padrão)
        return [
            "nav.view.dashboard",
            "nav.view.offers",
            "nav.view.cases",
            "nav.view.partners",
            "nav.view.partnerships",
            "nav.view.messages",
            "nav.view.profile",
            "offers.receive",
            "partnerships.create_platform",
            "partnerships.manage_platform",
            "offers.create_platform",
            "search.advanced.platform",
            "platform.administrative",
        ]
    
    async def _register_auto_context_switch(
        self,
        user_id: str,
        new_context: OperationMode,
        session_id: str,
        detection_metadata: Dict[str, Any]
    ):
        """
        Registra mudança automática de contexto
        """
        switch_record = {
            "user_id": user_id,
            "context_mode": new_context.value,
            "session_id": session_id,
            "detection_method": "automatic",
            "detection_metadata": json.dumps(detection_metadata),
            "detected_at": datetime.utcnow(),
            "ip_address": self._get_request_ip(),
            "user_agent": self._get_user_agent()
        }
        
        await self.supabase.table("auto_context_logs").insert(switch_record).execute()
        
        # Log de auditoria
        await self.audit_service.log_contextual_action(
            user_id=user_id,
            action="context.auto_detected",
            context_mode=new_context.value,
            entity_type="context_switch",
            metadata={
                "detection_method": "automatic",
                "previous_context": await self._get_previous_context(user_id),
                "detection_signals": detection_metadata
            },
            session_id=session_id,
            on_behalf_of="LITIG-1" if new_context == OperationMode.PLATFORM_WORK else user_id
        )
    
    async def _is_super_associate(self, user_id: str) -> bool:
        """
        Verifica se o usuário é Super Associado
        """
        try:
            profile = await self.supabase.table("profiles")\
                .select("user_role")\
                .eq("user_id", user_id)\
                .single()\
                .execute()
            
            # Verificar se é super associado (novo nome)
            user_role = profile.data.get("user_role", "")
            # Suportar tanto o nome novo quanto o legado durante transição
            return user_role in ["super_associate", "lawyer_platform_associate"]
        except:
            return False
    
    async def _get_previous_context(self, user_id: str) -> Optional[str]:
        """
        Obtém o contexto anterior do usuário
        """
        try:
            previous = await self.supabase.table("auto_context_logs")\
                .select("context_mode")\
                .eq("user_id", user_id)\
                .order("detected_at", desc=True)\
                .limit(1)\
                .execute()
            
            return previous.data[0]["context_mode"] if previous.data else None
        except:
            return None
    
    def _get_request_ip(self) -> str:
        """Obtém IP da requisição atual"""
        # Implementar baseado no framework web usado
        return "127.0.0.1"  # Placeholder
    
    def _get_user_agent(self) -> str:
        """Obtém User-Agent da requisição atual"""
        # Implementar baseado no framework web usado
        return "AutoContextService/1.0"  # Placeholder 