"""
Serviço para validação de planos e restrições de funcionalidades.
Implementa a lógica para restringir Unipile messaging baseado no tipo de usuário.
"""
import logging
from typing import Dict, Optional, bool
from ..schemas.user_types import EntityType, normalize_entity_type, is_client, is_lawyer
from .user_type_migration_service import UserTypeMigrationService

logger = logging.getLogger(__name__)

class PlanValidationService:
    """Serviço centralizado para validação de planos e funcionalidades."""
    
    def __init__(self):
        self.migration_service = None  # Será injetado quando necessário
    
    def can_use_unipile_messaging(
        self, 
        entity_type: str, 
        plan: str, 
        user_metadata: Optional[Dict] = None
    ) -> bool:
        """
        Verifica se o usuário pode usar o serviço de messaging do Unipile.
        
        REGRA ESTRATÉGICA:
        - Usuários gratuitos: NÃO podem usar Unipile
        - Usuários pagos: Podem usar Unipile
        """
        # Normalizar tipo de entidade
        normalized_type = normalize_entity_type(entity_type)
        
        # Se precisar migrar, usar o serviço de migração
        if user_metadata and entity_type != normalized_type:
            if self.migration_service:
                normalized_type, _ = self.migration_service.migrate_entity_type(
                    entity_type, user_metadata
                )
        
        # Verificar restrições por tipo de entidade
        restrictions = self._get_plan_restrictions(normalized_type, plan)
        return restrictions.get("unipile_messaging", False)
    
    def can_use_advanced_search(self, entity_type: str, plan: str) -> bool:
        """Verifica se pode usar busca avançada."""
        normalized_type = normalize_entity_type(entity_type)
        restrictions = self._get_plan_restrictions(normalized_type, plan)
        return restrictions.get("advanced_search", False)
    
    def get_max_cases_limit(self, entity_type: str, plan: str) -> int:
        """Retorna o limite de casos (-1 = ilimitado)."""
        normalized_type = normalize_entity_type(entity_type)
        restrictions = self._get_plan_restrictions(normalized_type, plan)
        return restrictions.get("max_cases", 3)  # Default: 3 cases
    
    def get_max_partnerships_limit(self, entity_type: str, plan: str) -> int:
        """Retorna o limite de parcerias (-1 = ilimitado)."""
        normalized_type = normalize_entity_type(entity_type)
        restrictions = self._get_plan_restrictions(normalized_type, plan)
        return restrictions.get("max_partnerships", 10)  # Default: 10 partnerships
    
    def get_client_invitations_limit(self, entity_type: str, plan: str) -> int:
        """Retorna o limite de convites para clientes (-1 = ilimitado)."""
        normalized_type = normalize_entity_type(entity_type)
        restrictions = self._get_plan_restrictions(normalized_type, plan)
        return restrictions.get("client_invitations", 5)  # Default: 5 invitations
    
    def validate_feature_access(
        self, 
        feature: str, 
        entity_type: str, 
        plan: str,
        user_metadata: Optional[Dict] = None
    ) -> Dict:
        """
        Valida acesso a uma funcionalidade específica.
        
        Returns:
            Dict com 'allowed' (bool) e 'reason' (str) se negado
        """
        normalized_type = normalize_entity_type(entity_type)
        
        # Features que requerem validação especial
        feature_validators = {
            "unipile_messaging": self.can_use_unipile_messaging,
            "advanced_search": self.can_use_advanced_search,
            "unipile_whatsapp": lambda et, p: self._get_plan_restrictions(et, p).get("unipile_whatsapp", False),
            "unipile_full_suite": lambda et, p: self._get_plan_restrictions(et, p).get("unipile_full_suite", False),
            "hybrid_search": self.can_use_advanced_search,  # Mesmo que advanced_search
            "priority_support": lambda et, p: self._get_plan_restrictions(et, p).get("priority_support", False),
            "multi_user": lambda et, p: self._get_plan_restrictions(et, p).get("multi_user", False),
            "b2b_chat": lambda et, p: self._get_plan_restrictions(et, p).get("b2b_chat", False),
            "partnership_chat": lambda et, p: self._get_plan_restrictions(et, p).get("partnership_chat", False),
            "firm_collaboration": lambda et, p: self._get_plan_restrictions(et, p).get("firm_collaboration", False),
            "multi_participant_chat": lambda et, p: self._get_plan_restrictions(et, p).get("multi_participant_chat", False),
        }
        
        if feature in feature_validators:
            validator = feature_validators[feature]
            if feature == "unipile_messaging":
                allowed = validator(normalized_type, plan, user_metadata)
            else:
                allowed = validator(normalized_type, plan)
            
            if not allowed:
                return {
                    "allowed": False,
                    "reason": self._get_upgrade_message(feature, normalized_type),
                    "suggested_plan": self._get_suggested_plan(normalized_type)
                }
        
        return {"allowed": True}
    
    def _get_plan_restrictions(self, entity_type: str, plan: str) -> Dict:
        """Retorna as restrições do plano para o tipo de entidade."""
        restrictions = {
            # === CLIENTES PESSOA FÍSICA ===
            EntityType.CLIENT_PF: {
                "free_pf": {
                    "unipile_messaging": False,
                    "unipile_whatsapp": False,
                    "unipile_full_suite": False,
                    "max_cases": 3,
                    "priority_support": False,
                    "advanced_search": False,
                    "ai_insights": False,
                },
                "pro_pf": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": False, # Clientes PRO só têm WhatsApp
                    "max_cases": 20,
                    "priority_support": True,
                    "advanced_search": True,
                    "ai_insights": True,
                },
                "vip_pf": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True, # Clientes VIP têm tudo
                    "max_cases": -1,  # Unlimited
                    "priority_support": True,
                    "advanced_search": True,
                    "ai_insights": True,
                    "dedicated_support": True,
                }
            },
            
            # === CLIENTES PESSOA JURÍDICA ===
            EntityType.CLIENT_PJ: {
                "free_pj": {
                    "unipile_messaging": False,
                    "unipile_whatsapp": False,
                    "unipile_full_suite": False,
                    "max_cases": 5,  # PJ tem mais casos no free
                    "priority_support": False,
                    "advanced_search": False,
                    "multi_user": False,
                    "ai_insights": False,
                },
                "business_pj": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True, # Business já tem tudo
                    "max_cases": 50,
                    "priority_support": True,
                    "advanced_search": True,
                    "multi_user": True,
                    "max_users": 5,
                    "ai_insights": True,
                },
                "enterprise_pj": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "max_cases": -1,  # Unlimited
                    "priority_support": True,
                    "advanced_search": True,
                    "multi_user": True,
                    "max_users": -1,  # Unlimited
                    "ai_insights": True,
                    "custom_integration": True,
                    "dedicated_support": True,
                }
            },
            
            # === ADVOGADOS INDIVIDUAIS ===
            EntityType.LAWYER_INDIVIDUAL: {
                "free_lawyer": {
                    "unipile_messaging": False,
                    "unipile_whatsapp": False,
                    "unipile_full_suite": False,
                    "max_partnerships": 10,
                    "client_invitations": 5,
                    "advanced_search": False,
                    "b2b_chat": False,  # Chat B2B bloqueado
                    "partnership_chat": False,  # Chat de parcerias bloqueado
                    "firm_collaboration": False,  # Colaboração entre escritórios bloqueada
                    "multi_participant_chat": False,  # Chat multi-participante bloqueado
                },
                "pro_lawyer": {
                    "unipile_messaging": True, # Mantém para compatibilidade
                    "unipile_whatsapp": True,  # Acesso ao WhatsApp
                    "unipile_full_suite": False, # NÃO tem acesso à suíte completa
                    "max_partnerships": 50,
                    "client_invitations": 50,
                    "advanced_search": True,
                    "priority_support": True,
                    "b2b_chat": True,  # Chat B2B básico liberado
                    "partnership_chat": True,  # Chat de parcerias liberado
                    "firm_collaboration": False,  # Colaboração entre escritórios ainda bloqueada
                    "multi_participant_chat": False,  # Chat multi-participante ainda bloqueado
                    "max_chat_participants": 2,  # Máximo 2 participantes por chat
                },
                "premium_lawyer": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True, # Acesso à suíte completa
                    "max_partnerships": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                    "b2b_chat": True,  # Chat B2B completo
                    "partnership_chat": True,  # Chat de parcerias completo
                    "firm_collaboration": True,  # Colaboração entre escritórios liberada
                    "multi_participant_chat": True,  # Chat multi-participante liberado
                    "max_chat_participants": 10,  # Até 10 participantes por chat
                    "chat_file_sharing": True,  # Compartilhamento de arquivos no chat
                    "chat_screen_sharing": True,  # Compartilhamento de tela (futuro)
                }
            },
            
            # === ADVOGADOS ASSOCIADOS A ESCRITÓRIOS ===
            EntityType.LAWYER_FIRM_MEMBER: {
                "free_lawyer": {
                    "unipile_messaging": False,
                    "unipile_whatsapp": False,
                    "unipile_full_suite": False,
                    "max_partnerships": 5,  # Menos que individuais
                    "client_invitations": 3,  # Menos que individuais
                    "advanced_search": False,
                    "firm_tools_access": False,
                },
                "pro_lawyer": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": False,
                    "max_partnerships": 25,  # Menos que individuais
                    "client_invitations": 25,  # Menos que individuais
                    "advanced_search": True,
                    "priority_support": True,
                    "firm_tools_access": True,
                },
                "premium_lawyer": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "max_partnerships": 100,  # Menos que individuais ilimitado
                    "client_invitations": 100,  # Menos que individuais ilimitado
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                    "firm_tools_access": True,
                }
            },
            
            # === ESCRITÓRIOS ===
            EntityType.FIRM: {
                "free_firm": {
                    "unipile_messaging": False,  # Escritórios gratuitos seguem regras de advogados gratuitos
                    "unipile_whatsapp": False,
                    "unipile_full_suite": False,
                    "max_lawyers": 3,  # Limite baixo para escritórios gratuitos
                    "client_invitations": 10,
                    "advanced_search": False,
                    "priority_support": False,
                    "b2b_chat": False,  # Chat B2B bloqueado para escritórios gratuitos
                    "partnership_chat": False,  # Chat de parcerias bloqueado
                    "firm_collaboration": False,  # Colaboração entre escritórios bloqueada
                    "multi_participant_chat": False,  # Chat multi-participante bloqueado
                    "max_chat_participants": 2,  # Máximo 2 participantes
                    "chat_file_sharing": False,  # Compartilhamento de arquivos bloqueado
                    "chat_delegation": False,  # Delegação bloqueada
                },
                "partner_firm": {
                    "unipile_messaging": True,  # Escritórios pagos têm messaging
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "max_lawyers": 10,
                    "client_invitations": 100,
                    "advanced_search": True,
                    "priority_support": True,
                    "b2b_chat": True,  # Chat B2B liberado para escritórios pagos
                    "partnership_chat": True,  # Chat de parcerias liberado
                    "firm_collaboration": True,  # Colaboração entre escritórios liberada
                    "multi_participant_chat": True,  # Chat multi-participante liberado
                    "max_chat_participants": 15,  # Até 15 participantes por chat
                    "chat_file_sharing": True,  # Compartilhamento de arquivos
                    "chat_delegation": True,  # Pode delegar conversas para associados
                },
                "premium_firm": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "max_lawyers": 50,
                    "client_invitations": 500,
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                    "b2b_chat": True,
                    "partnership_chat": True,
                    "firm_collaboration": True,
                    "multi_participant_chat": True,
                    "max_chat_participants": 25,  # Mais participantes para premium
                    "chat_file_sharing": True,
                    "chat_delegation": True,
                    "chat_analytics": True,  # Analytics de comunicação
                    "chat_integrations": True,  # Integrações com CRM/ERP
                },
                "enterprise_firm": {
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "max_lawyers": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                    "custom_integration": True,
                    "dedicated_support": True,
                    "b2b_chat": True,
                    "partnership_chat": True,
                    "firm_collaboration": True,
                    "multi_participant_chat": True,
                    "max_chat_participants": -1,  # Participantes ilimitados
                    "chat_file_sharing": True,
                    "chat_delegation": True,
                    "chat_analytics": True,
                    "chat_integrations": True,
                    "chat_white_label": True,  # Chat com marca própria
                    "chat_api_access": True,  # Acesso à API de chat
                    "chat_backup_export": True,  # Backup e exportação de conversas
                }
            },
            
            # === SUPER ASSOCIADO ===
            EntityType.SUPER_ASSOCIATE: {
                "premium_lawyer": {  # Super Associado sempre premium
                    "unipile_messaging": True,
                    "unipile_whatsapp": True,
                    "unipile_full_suite": True,
                    "cost_subsidized": True,  # Plataforma paga os custos
                    "beta_features": True,    # Acesso antecipado a recursos
                    "max_partnerships": -1,  # Ilimitado
                    "client_invitations": -1,  # Ilimitado
                    "priority_support": True,
                    "dedicated_support": True,
                    "ai_insights": True,
                    "b2b_chat": True,
                    "partnership_chat": True,
                    "firm_collaboration": True,
                    "multi_participant_chat": True,
                    "max_chat_participants": 15,  # Premium level
                    "chat_file_sharing": True,
                    "chat_delegation": True,
                    "chat_analytics": True,
                    "chat_integrations": True,
                    "platform_representative": True,  # Pode representar a plataforma
                    "cross_platform_messaging": True,  # Messaging entre plataformas
                }
            }
        }
        
        return restrictions.get(entity_type, {}).get(plan, {})
    
    def _get_upgrade_message(self, feature: str, entity_type: str) -> str:
        """Retorna mensagem de upgrade personalizada por tipo de usuário."""
        messages = {
            "unipile_messaging": {
                EntityType.CLIENT_PF: "Para enviar mensagens diretas aos advogados, faça upgrade para o plano PRO.",
                EntityType.CLIENT_PJ: "Para comunicação integrada, faça upgrade para o plano Business.",
                EntityType.LAWYER_INDIVIDUAL: "Para messaging automático, faça upgrade para o plano PRO.",
                EntityType.LAWYER_FIRM_MEMBER: "Para messaging integrado com ferramentas do escritório, faça upgrade para o plano PRO.",
                EntityType.FIRM: "Esta funcionalidade está disponível em todos os planos de escritório.",
            },
            "advanced_search": {
                EntityType.CLIENT_PF: "Para busca avançada com IA, faça upgrade para o plano PRO.",
                EntityType.CLIENT_PJ: "Para busca empresarial avançada, faça upgrade para o plano Business.",
                EntityType.LAWYER_INDIVIDUAL: "Para busca avançada, faça upgrade para o plano PRO.",
                EntityType.LAWYER_FIRM_MEMBER: "Para busca avançada e ferramentas do escritório, faça upgrade para o plano PRO.",
                EntityType.FIRM: "Esta funcionalidade está incluída em todos os planos de escritório.",
            },
            "b2b_chat": {
                EntityType.LAWYER_INDIVIDUAL: "Para chat B2B com outros advogados e escritórios, faça upgrade para o plano PRO.",
                EntityType.LAWYER_FIRM_MEMBER: "Para comunicação B2B inter-escritórios, faça upgrade para o plano PRO.",
                EntityType.FIRM: "Para chat B2B entre escritórios, faça upgrade para o plano Partner.",
            },
            "partnership_chat": {
                EntityType.LAWYER_INDIVIDUAL: "Para chat interno de parcerias, faça upgrade para o plano PRO.",
                EntityType.LAWYER_FIRM_MEMBER: "Para gestão de parcerias com chat integrado, faça upgrade para o plano PRO.",
                EntityType.FIRM: "Para chat de parcerias entre escritórios, faça upgrade para o plano Partner.",
            },
            "firm_collaboration": {
                EntityType.LAWYER_INDIVIDUAL: "Para colaboração direta com escritórios, faça upgrade para o plano PREMIUM.",
                EntityType.LAWYER_FIRM_MEMBER: "Para colaboração inter-escritórios, faça upgrade para o plano PREMIUM.",
                EntityType.FIRM: "Para colaboração entre escritórios, faça upgrade para o plano Partner.",
            },
            "multi_participant_chat": {
                EntityType.LAWYER_INDIVIDUAL: "Para chat com múltiplos participantes, faça upgrade para o plano PREMIUM.",
                EntityType.LAWYER_FIRM_MEMBER: "Para reuniões virtuais com múltiplos advogados, faça upgrade para o plano PREMIUM.",
                EntityType.FIRM: "Para chat multi-participante entre escritórios, faça upgrade para o plano Partner.",
            }
        }
        
        return messages.get(feature, {}).get(
            entity_type, 
            "Esta funcionalidade requer um plano pago."
        )
    
    def _get_suggested_plan(self, entity_type: str) -> str:
        """Retorna o plano sugerido para upgrade."""
        suggestions = {
            EntityType.CLIENT_PF: "pro_pf",
            EntityType.CLIENT_PJ: "business_pj",
            EntityType.LAWYER_INDIVIDUAL: "pro_lawyer",
            EntityType.LAWYER_FIRM_MEMBER: "pro_lawyer",
            EntityType.FIRM: "partner_firm",  # Escritórios gratuitos devem fazer upgrade para Partner
        }
        
        return suggestions.get(entity_type, "pro_pf")
    
    def get_feature_comparison(self, entity_type: str) -> Dict:
        """Retorna comparação de funcionalidades entre planos."""
        normalized_type = normalize_entity_type(entity_type)
        
        if normalized_type == EntityType.CLIENT_PF:
            return {
                "plans": ["free_pf", "pro_pf", "vip_pf"],
                "features": {
                    "Casos simultâneos": ["3", "20", "Ilimitado"],
                    "Messaging integrado": ["❌", "✅", "✅"],
                    "Busca avançada": ["❌", "✅", "✅"],
                    "Suporte prioritário": ["❌", "✅", "✅"],
                    "IA insights": ["❌", "✅", "✅"],
                    "Suporte dedicado": ["❌", "❌", "✅"],
                }
            }
        # Adicionar outras comparações conforme necessário
        
        return {} 