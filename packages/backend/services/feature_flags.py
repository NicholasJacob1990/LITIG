"""
Feature Flags Service - Sistema B2B Law Firms
Controla o rollout gradual das funcionalidades B2B
"""

import os
import logging
from typing import Dict, Optional, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)

class FeatureFlagStatus(Enum):
    ENABLED = "enabled"
    DISABLED = "disabled"
    PERCENTAGE = "percentage"

@dataclass
class FeatureFlag:
    name: str
    status: FeatureFlagStatus
    value: Any = None
    description: str = ""
    rollout_percentage: int = 0  # 0-100

class FeatureFlagsService:
    """
    Serviço para gerenciar feature flags do sistema B2B.
    Suporta variáveis de ambiente e configuração dinâmica.
    """
    
    def __init__(self):
        self._flags: Dict[str, FeatureFlag] = {}
        self._load_default_flags()
    
    def _load_default_flags(self):
        """Carrega as feature flags padrão do sistema B2B"""
        
        # Feature flag principal para habilitar/desabilitar escritórios
        enable_firm_match = os.getenv("ENABLE_FIRM_MATCH", "false").lower() == "true"
        self._flags["ENABLE_FIRM_MATCH"] = FeatureFlag(
            name="ENABLE_FIRM_MATCH",
            status=FeatureFlagStatus.ENABLED if enable_firm_match else FeatureFlagStatus.DISABLED,
            value=enable_firm_match,
            description="Habilita funcionalidades de escritórios (B2B Matching)",
            rollout_percentage=100 if enable_firm_match else 0
        )
        
        # Preset padrão para casos corporativos
        default_preset = os.getenv("DEFAULT_PRESET_CORPORATE", "balanced")
        self._flags["DEFAULT_PRESET_CORPORATE"] = FeatureFlag(
            name="DEFAULT_PRESET_CORPORATE",
            status=FeatureFlagStatus.ENABLED,
            value=default_preset,
            description="Preset padrão para casos corporativos (b2b para habilitar two-pass)",
            rollout_percentage=100
        )
        
        # Rollout gradual B2B
        b2b_rollout = int(os.getenv("B2B_ROLLOUT_PERCENTAGE", "0"))
        self._flags["B2B_ROLLOUT_PERCENTAGE"] = FeatureFlag(
            name="B2B_ROLLOUT_PERCENTAGE",
            status=FeatureFlagStatus.PERCENTAGE,
            value=b2b_rollout,
            description="Percentual de usuários com acesso ao B2B (0-100)",
            rollout_percentage=b2b_rollout
        )
        
        # Cache segmentado
        enable_segmented_cache = os.getenv("ENABLE_SEGMENTED_CACHE", "true").lower() == "true"
        self._flags["ENABLE_SEGMENTED_CACHE"] = FeatureFlag(
            name="ENABLE_SEGMENTED_CACHE",
            status=FeatureFlagStatus.ENABLED if enable_segmented_cache else FeatureFlagStatus.DISABLED,
            value=enable_segmented_cache,
            description="Habilita cache segmentado por entidade (firm/lawyer)",
            rollout_percentage=100 if enable_segmented_cache else 0
        )
        
        logger.info(f"Feature flags carregadas: {list(self._flags.keys())}")
    
    def is_enabled(self, flag_name: str, user_id: Optional[str] = None) -> bool:
        """
        Verifica se uma feature flag está habilitada.
        
        Args:
            flag_name: Nome da feature flag
            user_id: ID do usuário (para rollout gradual)
            
        Returns:
            True se a flag estiver habilitada
        """
        if flag_name not in self._flags:
            logger.warning(f"Feature flag '{flag_name}' não encontrada")
            return False
        
        flag = self._flags[flag_name]
        
        if flag.status == FeatureFlagStatus.DISABLED:
            return False
        
        if flag.status == FeatureFlagStatus.ENABLED:
            return True
        
        if flag.status == FeatureFlagStatus.PERCENTAGE:
            if user_id is None:
                return flag.rollout_percentage >= 100
            
            # Hash do user_id para distribuição consistente
            user_hash = hash(user_id) % 100
            return user_hash < flag.rollout_percentage
        
        return False
    
    def get_value(self, flag_name: str, default: Any = None) -> Any:
        """
        Obtém o valor de uma feature flag.
        
        Args:
            flag_name: Nome da feature flag
            default: Valor padrão se a flag não existir
            
        Returns:
            Valor da feature flag ou default
        """
        if flag_name not in self._flags:
            return default
        
        return self._flags[flag_name].value
    
    def get_all_flags(self) -> Dict[str, FeatureFlag]:
        """Retorna todas as feature flags"""
        return self._flags.copy()
    
    def update_flag(self, flag_name: str, status: FeatureFlagStatus, value: Any = None, rollout_percentage: int = 0):
        """
        Atualiza uma feature flag existente.
        
        Args:
            flag_name: Nome da feature flag
            status: Novo status
            value: Novo valor
            rollout_percentage: Percentual de rollout (0-100)
        """
        if flag_name not in self._flags:
            logger.error(f"Tentativa de atualizar flag inexistente: {flag_name}")
            return
        
        flag = self._flags[flag_name]
        flag.status = status
        if value is not None:
            flag.value = value
        flag.rollout_percentage = max(0, min(100, rollout_percentage))
        
        logger.info(f"Feature flag '{flag_name}' atualizada: {status.value}, valor={value}, rollout={rollout_percentage}%")

# Instância global do serviço
feature_flags = FeatureFlagsService()

# Funções de conveniência
def is_firm_matching_enabled(user_id: Optional[str] = None) -> bool:
    """Verifica se o matching de escritórios está habilitado"""
    return feature_flags.is_enabled("ENABLE_FIRM_MATCH", user_id)

def get_corporate_preset() -> str:
    """Obtém o preset padrão para casos corporativos"""
    return feature_flags.get_value("DEFAULT_PRESET_CORPORATE", "balanced")

def is_b2b_enabled_for_user(user_id: str) -> bool:
    """Verifica se o B2B está habilitado para um usuário específico"""
    return feature_flags.is_enabled("B2B_ROLLOUT_PERCENTAGE", user_id)

def is_segmented_cache_enabled() -> bool:
    """Verifica se o cache segmentado está habilitado"""
    return feature_flags.is_enabled("ENABLE_SEGMENTED_CACHE") 