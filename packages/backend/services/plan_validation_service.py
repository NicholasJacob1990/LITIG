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
            "hybrid_search": self.can_use_advanced_search,  # Mesmo que advanced_search
            "priority_support": lambda et, p: self._get_plan_restrictions(et, p).get("priority_support", False),
            "multi_user": lambda et, p: self._get_plan_restrictions(et, p).get("multi_user", False),
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
                    "max_cases": 3,
                    "priority_support": False,
                    "advanced_search": False,
                    "ai_insights": False,
                },
                "pro_pf": {
                    "unipile_messaging": True,
                    "max_cases": 20,
                    "priority_support": True,
                    "advanced_search": True,
                    "ai_insights": True,
                },
                "vip_pf": {
                    "unipile_messaging": True,
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
                    "max_cases": 5,  # PJ tem mais casos no free
                    "priority_support": False,
                    "advanced_search": False,
                    "multi_user": False,
                    "ai_insights": False,
                },
                "business_pj": {
                    "unipile_messaging": True,
                    "max_cases": 50,
                    "priority_support": True,
                    "advanced_search": True,
                    "multi_user": True,
                    "max_users": 5,
                    "ai_insights": True,
                },
                "enterprise_pj": {
                    "unipile_messaging": True,
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
                    "max_partnerships": 10,
                    "client_invitations": 5,
                    "advanced_search": False,
                },
                "pro_lawyer": {
                    "unipile_messaging": True,
                    "max_partnerships": 50,
                    "client_invitations": 50,
                    "advanced_search": True,
                    "priority_support": True,
                },
                "premium_lawyer": {
                    "unipile_messaging": True,
                    "max_partnerships": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                }
            },
            
            # === ADVOGADOS ASSOCIADOS A ESCRITÓRIOS ===
            EntityType.LAWYER_FIRM_MEMBER: {
                "free_lawyer": {
                    "unipile_messaging": False,
                    "max_partnerships": 5,  # Menos que individuais
                    "client_invitations": 3,  # Menos que individuais
                    "advanced_search": False,
                    "firm_tools_access": False,
                },
                "pro_lawyer": {
                    "unipile_messaging": True,
                    "max_partnerships": 25,  # Menos que individuais
                    "client_invitations": 25,  # Menos que individuais
                    "advanced_search": True,
                    "priority_support": True,
                    "firm_tools_access": True,
                },
                "premium_lawyer": {
                    "unipile_messaging": True,
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
                "partner_firm": {
                    "unipile_messaging": True,  # Escritórios sempre têm messaging
                    "max_lawyers": 10,
                    "client_invitations": 100,
                    "advanced_search": True,
                    "priority_support": True,
                },
                "premium_firm": {
                    "unipile_messaging": True,
                    "max_lawyers": 50,
                    "client_invitations": 500,
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                },
                "enterprise_firm": {
                    "unipile_messaging": True,
                    "max_lawyers": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                    "advanced_search": True,
                    "priority_support": True,
                    "ai_insights": True,
                    "custom_integration": True,
                    "dedicated_support": True,
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
            EntityType.FIRM: "premium_firm",
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