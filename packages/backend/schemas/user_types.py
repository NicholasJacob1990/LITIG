from enum import Enum

class EntityType(str, Enum):
    """Tipos de entidade principais do sistema."""
    CLIENT_PF = "client_pf"          # Cliente Pessoa Física
    CLIENT_PJ = "client_pj"          # Cliente Pessoa Jurídica  
    LAWYER_INDIVIDUAL = "lawyer_individual"  # Advogado Individual/Autônomo
    LAWYER_FIRM_MEMBER = "lawyer_firm_member"  # Advogado Associado a Escritório
    FIRM = "firm"                    # Escritório de Advocacia
    SUPER_ASSOCIATE = "super_associate"  # Super Associado da Plataforma

class UserRole(str, Enum):
    """Roles/papéis específicos dos usuários."""
    # Clientes
    CLIENT_PF = "client_pf"
    CLIENT_PJ = "client_pj"
    
    # Advogados
    LAWYER_INDIVIDUAL = "lawyer_individual"
    LAWYER_FIRM_MEMBER = "lawyer_firm_member"  # Advogado membro de escritório
    LAWYER_FIRM_OWNER = "lawyer_firm_owner"    # Sócio/Proprietário de escritório
    
    # Plataforma
    SUPER_ASSOCIATE = "super_associate"
    ADMIN = "admin"

class PlanType(str, Enum):
    """Tipos de planos por entidade."""
    # Clientes PF
    FREE_PF = "free_pf"
    PRO_PF = "pro_pf"
    VIP_PF = "vip_pf"
    
    # Clientes PJ
    FREE_PJ = "free_pj"
    BUSINESS_PJ = "business_pj"
    ENTERPRISE_PJ = "enterprise_pj"
    
    # Advogados Individuais
    FREE_LAWYER = "free_lawyer"
    PRO_LAWYER = "pro_lawyer"
    PREMIUM_LAWYER = "premium_lawyer"
    
    # Advogados Associados (mesmo plano que individuais)
    FREE_LAWYER_MEMBER = "free_lawyer"      # Compartilha plano com individual
    PRO_LAWYER_MEMBER = "pro_lawyer"        # Compartilha plano com individual
    PREMIUM_LAWYER_MEMBER = "premium_lawyer" # Compartilha plano com individual
    
    # Escritórios
    PARTNER_FIRM = "partner_firm"
    PREMIUM_FIRM = "premium_firm"
    ENTERPRISE_FIRM = "enterprise_firm"

class ClientType(str, Enum):
    """Tipos específicos de cliente para compatibilidade."""
    PF = "PF"  # Pessoa Física
    PJ = "PJ"  # Pessoa Jurídica

# Mapeamentos para compatibilidade com código existente
LEGACY_TYPE_MAPPING = {
    # Mapear tipos antigos para novos
    "client": "client_pf",  # Assumir PF como padrão para migração
    "lawyer": "lawyer_individual",
    "lawyer_office": "firm",  # CORREÇÃO: lawyer_office vira firm
    "lawyer_associated": "lawyer_firm_member",  # CORREÇÃO: lawyer_associated vira lawyer_firm_member
    "firm": "firm",
}

ENTITY_DISPLAY_NAMES = {
    EntityType.CLIENT_PF: "Cliente (Pessoa Física)",
    EntityType.CLIENT_PJ: "Cliente (Pessoa Jurídica)", 
    EntityType.LAWYER_INDIVIDUAL: "Advogado Individual",
    EntityType.LAWYER_FIRM_MEMBER: "Advogado Associado a Escritório",
    EntityType.FIRM: "Escritório de Advocacia",
    EntityType.SUPER_ASSOCIATE: "Super Associado",
}

def normalize_entity_type(legacy_type: str) -> str:
    """Converte tipos legados para os novos tipos padronizados."""
    return LEGACY_TYPE_MAPPING.get(legacy_type, legacy_type)

def get_entity_display_name(entity_type: str) -> str:
    """Retorna nome amigável para o tipo de entidade."""
    return ENTITY_DISPLAY_NAMES.get(entity_type, "Usuário")

def is_client(entity_type: str) -> bool:
    """Verifica se é um tipo de cliente."""
    return entity_type in [EntityType.CLIENT_PF, EntityType.CLIENT_PJ]

def is_lawyer(entity_type: str) -> bool:
    """Verifica se é um tipo de advogado."""
    return entity_type in [EntityType.LAWYER_INDIVIDUAL, EntityType.LAWYER_FIRM_MEMBER, EntityType.FIRM]

def is_firm(entity_type: str) -> bool:
    """Verifica se é um escritório."""
    return entity_type == EntityType.FIRM

def is_individual_lawyer(entity_type: str) -> bool:
    """Verifica se é um advogado individual (não associado a escritório)."""
    return entity_type == EntityType.LAWYER_INDIVIDUAL

def is_firm_member(entity_type: str) -> bool:
    """Verifica se é um advogado associado a escritório."""
    return entity_type == EntityType.LAWYER_FIRM_MEMBER 