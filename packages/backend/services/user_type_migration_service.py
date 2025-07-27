"""
Serviço para migração gradual dos tipos de usuário e correção de inconsistências.
"""
import logging
from typing import Dict, Optional, Tuple, List
from sqlalchemy.orm import Session
from ..schemas.user_types import (
    EntityType, UserRole, ClientType, normalize_entity_type,
    is_client, is_lawyer, is_firm
)

logger = logging.getLogger(__name__)

class UserTypeMigrationService:
    """Serviço para migração e normalização de tipos de usuário."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def migrate_entity_type(self, current_type: str, user_metadata: Dict) -> Tuple[str, Dict]:
        """
        Migra um tipo de entidade legado para o novo padrão.
        
        Args:
            current_type: Tipo atual do usuário
            user_metadata: Metadados do usuário para inferir o tipo correto
            
        Returns:
            Tuple com (novo_tipo, metadados_atualizados)
        """
        # Primeiro, normalizar tipos conhecidos
        normalized_type = normalize_entity_type(current_type)
        updated_metadata = user_metadata.copy()
        
        # Se é cliente, precisamos determinar se é PF ou PJ
        if current_type == "client":
            client_type = self._determine_client_type(user_metadata)
            if client_type == ClientType.PF:
                normalized_type = EntityType.CLIENT_PF
            else:
                normalized_type = EntityType.CLIENT_PJ
            
            # Atualizar metadados com o tipo de cliente
            updated_metadata["client_type"] = client_type.value
            updated_metadata["entity_type"] = normalized_type
        
        # Se é lawyer_office, converter para firm
        elif current_type == "lawyer_office":
            normalized_type = EntityType.FIRM
            updated_metadata["entity_type"] = EntityType.FIRM
            updated_metadata["user_role"] = UserRole.LAWYER_FIRM_OWNER  # Assumir owner por padrão
        
        # Se é lawyer_associated, converter para lawyer_firm_member
        elif current_type == "lawyer_associated":
            normalized_type = EntityType.LAWYER_FIRM_MEMBER
            updated_metadata["entity_type"] = EntityType.LAWYER_FIRM_MEMBER
            updated_metadata["user_role"] = UserRole.LAWYER_FIRM_MEMBER
        
        # Se é lawyer individual
        elif current_type in ["lawyer", "lawyer_individual"]:
            normalized_type = EntityType.LAWYER_INDIVIDUAL
            updated_metadata["entity_type"] = EntityType.LAWYER_INDIVIDUAL
            updated_metadata["user_role"] = UserRole.LAWYER_INDIVIDUAL
        
        logger.info(f"Migrating user type: {current_type} -> {normalized_type}")
        return normalized_type, updated_metadata
    
    def _determine_client_type(self, user_metadata: Dict) -> ClientType:
        """
        Determina se o cliente é PF ou PJ baseado nos metadados disponíveis.
        """
        # Verificar se já está explicitamente definido
        if "client_type" in user_metadata:
            client_type = user_metadata["client_type"]
            if client_type in [ClientType.PF, ClientType.PJ]:
                return ClientType(client_type)
        
        # Inferir baseado em outros campos
        indicators_pj = [
            "cnpj" in user_metadata,
            "company_name" in user_metadata,
            "corporate" in user_metadata.get("profile_type", "").lower(),
            "empresa" in user_metadata.get("name", "").lower(),
            "ltda" in user_metadata.get("name", "").lower(),
            "s.a." in user_metadata.get("name", "").lower(),
        ]
        
        indicators_pf = [
            "cpf" in user_metadata,
            "individual" in user_metadata.get("profile_type", "").lower(),
        ]
        
        if any(indicators_pj):
            return ClientType.PJ
        elif any(indicators_pf):
            return ClientType.PF
        else:
            # Padrão: assumir PF para migração segura
            logger.warning(f"Could not determine client type, defaulting to PF for user: {user_metadata.get('id', 'unknown')}")
            return ClientType.PF
    
    def get_plan_restrictions_for_entity(self, entity_type: str, plan: str) -> Dict:
        """
        Retorna as restrições de plano específicas para cada tipo de entidade.
        """
        restrictions = {
            # Clientes PF
            EntityType.CLIENT_PF: {
                "free_pf": {
                    "unipile_messaging": False,
                    "max_cases": 3,
                    "priority_support": False,
                    "advanced_search": False,
                },
                "pro_pf": {
                    "unipile_messaging": True,
                    "max_cases": 20,
                    "priority_support": True,
                    "advanced_search": True,
                },
                "vip_pf": {
                    "unipile_messaging": True,
                    "max_cases": -1,  # Unlimited
                    "priority_support": True,
                    "advanced_search": True,
                    "dedicated_support": True,
                }
            },
            
            # Clientes PJ
            EntityType.CLIENT_PJ: {
                "free_pj": {
                    "unipile_messaging": False,
                    "max_cases": 5,
                    "priority_support": False,
                    "advanced_search": False,
                    "multi_user": False,
                },
                "business_pj": {
                    "unipile_messaging": True,
                    "max_cases": 50,
                    "priority_support": True,
                    "advanced_search": True,
                    "multi_user": True,
                    "max_users": 5,
                },
                "enterprise_pj": {
                    "unipile_messaging": True,
                    "max_cases": -1,  # Unlimited
                    "priority_support": True,
                    "advanced_search": True,
                    "multi_user": True,
                    "max_users": -1,  # Unlimited
                    "custom_integration": True,
                }
            },
            
            # Advogados Individuais
            EntityType.LAWYER_INDIVIDUAL: {
                "free_lawyer": {
                    "unipile_messaging": False,
                    "max_partnerships": 10,
                    "client_invitations": 5,
                },
                "pro_lawyer": {
                    "unipile_messaging": True,
                    "max_partnerships": 50,
                    "client_invitations": 50,
                },
                "premium_lawyer": {
                    "unipile_messaging": True,
                    "max_partnerships": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                }
            },
            
            # Escritórios
            EntityType.FIRM: {
                "partner_firm": {
                    "unipile_messaging": True,
                    "max_lawyers": 10,
                    "client_invitations": 100,
                },
                "premium_firm": {
                    "unipile_messaging": True,
                    "max_lawyers": 50,
                    "client_invitations": 500,
                },
                "enterprise_firm": {
                    "unipile_messaging": True,
                    "max_lawyers": -1,  # Unlimited
                    "client_invitations": -1,  # Unlimited
                }
            }
        }
        
        return restrictions.get(entity_type, {}).get(plan, {})
    
    def validate_plan_for_entity(self, entity_type: str, plan: str) -> bool:
        """Valida se um plano é válido para um tipo de entidade."""
        valid_plans = {
            EntityType.CLIENT_PF: ["free_pf", "pro_pf", "vip_pf"],
            EntityType.CLIENT_PJ: ["free_pj", "business_pj", "enterprise_pj"],
            EntityType.LAWYER_INDIVIDUAL: ["free_lawyer", "pro_lawyer", "premium_lawyer"],
            EntityType.FIRM: ["partner_firm", "premium_firm", "enterprise_firm"],
        }
        
        return plan in valid_plans.get(entity_type, [])
    
    def get_default_plan_for_entity(self, entity_type: str) -> str:
        """Retorna o plano padrão para um tipo de entidade."""
        defaults = {
            EntityType.CLIENT_PF: "free_pf",
            EntityType.CLIENT_PJ: "free_pj", 
            EntityType.LAWYER_INDIVIDUAL: "free_lawyer",
            EntityType.FIRM: "partner_firm",  # Escritórios começam no Partner
            EntityType.SUPER_ASSOCIATE: "premium_lawyer",
        }
        
        return defaults.get(entity_type, "free_pf")
    
    async def migrate_user_in_database(self, user_id: str) -> bool:
        """
        Migra um usuário específico no banco de dados.
        """
        try:
            # Esta função seria implementada para fazer a migração real no banco
            # Por enquanto, apenas log da ação
            logger.info(f"Would migrate user {user_id} in database")
            return True
        except Exception as e:
            logger.error(f"Error migrating user {user_id}: {str(e)}")
            return False 