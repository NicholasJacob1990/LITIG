"""
Serviço de Feature Flags para Rollout Gradual
Controla ativação progressiva da contextualização por perfil de usuário
"""

import json
import hashlib
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import logging

from models.user import User
from database import get_db_connection
from utils.cache import cache_result
from utils.redis_client import get_redis_client

logger = logging.getLogger(__name__)

class FeatureStatus(Enum):
    """Status de uma feature flag"""
    DISABLED = "disabled"
    TESTING = "testing"
    GRADUAL_ROLLOUT = "gradual_rollout"
    ENABLED = "enabled"

class RolloutStrategy(Enum):
    """Estratégias de rollout"""
    PERCENTAGE = "percentage"
    USER_LIST = "user_list"
    USER_ROLE = "user_role"
    GEOGRAPHIC = "geographic"
    DEVICE_TYPE = "device_type"
    HYBRID = "hybrid"

@dataclass
class FeatureFlag:
    """Configuração de uma feature flag"""
    name: str
    description: str
    status: FeatureStatus
    rollout_strategy: RolloutStrategy
    rollout_percentage: float
    target_users: List[str]
    target_roles: List[str]
    target_regions: List[str]
    device_types: List[str]
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    metadata: Dict[str, Any]
    created_at: datetime
    updated_at: datetime

@dataclass
class ContextualFeatureConfig:
    """Configuração específica para features de contextualização"""
    allocation_types_enabled: List[str]
    ui_components_enabled: List[str]
    metrics_collection_enabled: bool
    dual_context_enabled: bool
    advanced_kpis_enabled: bool
    real_time_updates_enabled: bool
    performance_monitoring_enabled: bool

class FeatureFlagService:
    """Serviço para gerenciamento de feature flags"""
    
    def __init__(self):
        self.db = get_db_connection()
        self.redis = get_redis_client()
        self.cache_ttl = 300  # 5 minutos
        
        # Feature flags para contextualização
        self.contextual_features = {
            'contextual_case_view': 'Visualização contextual de casos',
            'contextual_kpis': 'KPIs contextuais',
            'contextual_actions': 'Ações contextuais',
            'contextual_highlights': 'Destaques contextuais',
            'dual_context_navigation': 'Navegação em contexto duplo',
            'advanced_allocation_types': 'Tipos de alocação avançados',
            'contextual_metrics': 'Métricas contextuais',
            'real_time_contextual_updates': 'Atualizações contextuais em tempo real',
            'contextual_performance_monitoring': 'Monitoramento de performance contextual'
        }
    
    async def is_feature_enabled(
        self,
        feature_name: str,
        user: User,
        context: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Verifica se uma feature está habilitada para um usuário"""
        try:
            # Primeiro verifica cache
            cache_key = f"feature_flag:{feature_name}:{user.id}"
            cached_result = await self.redis.get(cache_key)
            
            if cached_result is not None:
                return json.loads(cached_result)
            
            # Busca configuração da feature
            feature_flag = await self.get_feature_flag(feature_name)
            
            if not feature_flag:
                return False
            
            # Verifica status da feature
            if feature_flag.status == FeatureStatus.DISABLED:
                result = False
            elif feature_flag.status == FeatureStatus.ENABLED:
                result = True
            else:
                # Aplica estratégia de rollout
                result = await self._evaluate_rollout_strategy(feature_flag, user, context)
            
            # Cache resultado
            await self.redis.setex(
                cache_key,
                self.cache_ttl,
                json.dumps(result)
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error checking feature flag {feature_name}: {e}")
            return False
    
    async def get_contextual_feature_config(
        self,
        user: User,
        context: Optional[Dict[str, Any]] = None
    ) -> ContextualFeatureConfig:
        """Obtém configuração completa de features contextuais para um usuário"""
        try:
            # Verifica cada feature contextual
            contextual_features_enabled = {}
            
            for feature_name in self.contextual_features.keys():
                is_enabled = await self.is_feature_enabled(feature_name, user, context)
                contextual_features_enabled[feature_name] = is_enabled
            
            # Determina tipos de alocação habilitados
            allocation_types_enabled = []
            if contextual_features_enabled.get('contextual_case_view', False):
                allocation_types_enabled.append('platform_match_direct')
            
            if contextual_features_enabled.get('advanced_allocation_types', False):
                allocation_types_enabled.extend([
                    'platform_match_partnership',
                    'partnership_proactive_search',
                    'partnership_platform_suggestion',
                    'internal_delegation'
                ])
            
            # Determina componentes UI habilitados
            ui_components_enabled = []
            if contextual_features_enabled.get('contextual_case_view', False):
                ui_components_enabled.append('contextual_case_card')
            
            if contextual_features_enabled.get('contextual_kpis', False):
                ui_components_enabled.append('contextual_kpis')
            
            if contextual_features_enabled.get('contextual_actions', False):
                ui_components_enabled.append('contextual_actions')
            
            if contextual_features_enabled.get('contextual_highlights', False):
                ui_components_enabled.append('contextual_highlights')
            
            return ContextualFeatureConfig(
                allocation_types_enabled=allocation_types_enabled,
                ui_components_enabled=ui_components_enabled,
                metrics_collection_enabled=contextual_features_enabled.get('contextual_metrics', False),
                dual_context_enabled=contextual_features_enabled.get('dual_context_navigation', False),
                advanced_kpis_enabled=contextual_features_enabled.get('contextual_kpis', False),
                real_time_updates_enabled=contextual_features_enabled.get('real_time_contextual_updates', False),
                performance_monitoring_enabled=contextual_features_enabled.get('contextual_performance_monitoring', False)
            )
            
        except Exception as e:
            logger.error(f"Error getting contextual feature config: {e}")
            # Fallback para configuração mínima
            return ContextualFeatureConfig(
                allocation_types_enabled=['platform_match_direct'],
                ui_components_enabled=['contextual_case_card'],
                metrics_collection_enabled=False,
                dual_context_enabled=False,
                advanced_kpis_enabled=False,
                real_time_updates_enabled=False,
                performance_monitoring_enabled=False
            )
    
    async def create_feature_flag(
        self,
        name: str,
        description: str,
        rollout_strategy: RolloutStrategy = RolloutStrategy.PERCENTAGE,
        rollout_percentage: float = 0.0,
        target_users: Optional[List[str]] = None,
        target_roles: Optional[List[str]] = None,
        target_regions: Optional[List[str]] = None,
        device_types: Optional[List[str]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> FeatureFlag:
        """Cria uma nova feature flag"""
        try:
            feature_flag = FeatureFlag(
                name=name,
                description=description,
                status=FeatureStatus.DISABLED,
                rollout_strategy=rollout_strategy,
                rollout_percentage=rollout_percentage,
                target_users=target_users or [],
                target_roles=target_roles or [],
                target_regions=target_regions or [],
                device_types=device_types or [],
                start_date=start_date,
                end_date=end_date,
                metadata=metadata or {},
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            
            await self._store_feature_flag(feature_flag)
            
            # Invalida cache
            await self._invalidate_feature_cache(name)
            
            logger.info(f"Created feature flag: {name}")
            return feature_flag
            
        except Exception as e:
            logger.error(f"Error creating feature flag: {e}")
            raise
    
    async def update_feature_flag(
        self,
        name: str,
        status: Optional[FeatureStatus] = None,
        rollout_percentage: Optional[float] = None,
        target_users: Optional[List[str]] = None,
        target_roles: Optional[List[str]] = None,
        target_regions: Optional[List[str]] = None,
        device_types: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[FeatureFlag]:
        """Atualiza uma feature flag existente"""
        try:
            feature_flag = await self.get_feature_flag(name)
            
            if not feature_flag:
                return None
            
            # Atualiza campos se fornecidos
            if status is not None:
                feature_flag.status = status
            if rollout_percentage is not None:
                feature_flag.rollout_percentage = rollout_percentage
            if target_users is not None:
                feature_flag.target_users = target_users
            if target_roles is not None:
                feature_flag.target_roles = target_roles
            if target_regions is not None:
                feature_flag.target_regions = target_regions
            if device_types is not None:
                feature_flag.device_types = device_types
            if metadata is not None:
                feature_flag.metadata = metadata
            
            feature_flag.updated_at = datetime.utcnow()
            
            await self._store_feature_flag(feature_flag)
            
            # Invalida cache
            await self._invalidate_feature_cache(name)
            
            logger.info(f"Updated feature flag: {name}")
            return feature_flag
            
        except Exception as e:
            logger.error(f"Error updating feature flag: {e}")
            raise
    
    async def get_feature_flag(self, name: str) -> Optional[FeatureFlag]:
        """Obtém uma feature flag pelo nome"""
        try:
            query = """
            SELECT name, description, status, rollout_strategy, rollout_percentage,
                   target_users, target_roles, target_regions, device_types,
                   start_date, end_date, metadata, created_at, updated_at
            FROM feature_flags
            WHERE name = %s
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (name,))
                row = cursor.fetchone()
                
                if not row:
                    return None
                
                return FeatureFlag(
                    name=row[0],
                    description=row[1],
                    status=FeatureStatus(row[2]),
                    rollout_strategy=RolloutStrategy(row[3]),
                    rollout_percentage=row[4],
                    target_users=row[5] or [],
                    target_roles=row[6] or [],
                    target_regions=row[7] or [],
                    device_types=row[8] or [],
                    start_date=row[9],
                    end_date=row[10],
                    metadata=row[11] or {},
                    created_at=row[12],
                    updated_at=row[13]
                )
                
        except Exception as e:
            logger.error(f"Error getting feature flag: {e}")
            return None
    
    async def list_feature_flags(self) -> List[FeatureFlag]:
        """Lista todas as feature flags"""
        try:
            query = """
            SELECT name, description, status, rollout_strategy, rollout_percentage,
                   target_users, target_roles, target_regions, device_types,
                   start_date, end_date, metadata, created_at, updated_at
            FROM feature_flags
            ORDER BY created_at DESC
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query)
                rows = cursor.fetchall()
                
                return [
                    FeatureFlag(
                        name=row[0],
                        description=row[1],
                        status=FeatureStatus(row[2]),
                        rollout_strategy=RolloutStrategy(row[3]),
                        rollout_percentage=row[4],
                        target_users=row[5] or [],
                        target_roles=row[6] or [],
                        target_regions=row[7] or [],
                        device_types=row[8] or [],
                        start_date=row[9],
                        end_date=row[10],
                        metadata=row[11] or {},
                        created_at=row[12],
                        updated_at=row[13]
                    )
                    for row in rows
                ]
                
        except Exception as e:
            logger.error(f"Error listing feature flags: {e}")
            return []
    
    async def initialize_contextual_features(self) -> None:
        """Inicializa feature flags para contextualização"""
        try:
            # Rollout progressivo por perfil de usuário
            rollout_phases = [
                {
                    'features': ['contextual_case_view'],
                    'target_roles': ['admin', 'super_admin'],
                    'percentage': 100.0,
                    'description': 'Fase 1: Admins e super admins'
                },
                {
                    'features': ['contextual_case_view', 'contextual_kpis'],
                    'target_roles': ['advogado'],
                    'percentage': 25.0,
                    'description': 'Fase 2: 25% dos advogados'
                },
                {
                    'features': ['contextual_case_view', 'contextual_kpis', 'contextual_actions'],
                    'target_roles': ['advogado'],
                    'percentage': 50.0,
                    'description': 'Fase 3: 50% dos advogados'
                },
                {
                    'features': ['contextual_case_view', 'contextual_kpis', 'contextual_actions', 'contextual_highlights'],
                    'target_roles': ['cliente'],
                    'percentage': 10.0,
                    'description': 'Fase 4: 10% dos clientes'
                },
                {
                    'features': ['dual_context_navigation'],
                    'target_roles': ['advogado'],
                    'percentage': 10.0,
                    'description': 'Fase 5: Contexto duplo para advogados'
                }
            ]
            
            for phase in rollout_phases:
                for feature_name in phase['features']:
                    if feature_name in self.contextual_features:
                        existing_flag = await self.get_feature_flag(feature_name)
                        
                        if not existing_flag:
                            await self.create_feature_flag(
                                name=feature_name,
                                description=f"{self.contextual_features[feature_name]} - {phase['description']}",
                                rollout_strategy=RolloutStrategy.HYBRID,
                                rollout_percentage=phase['percentage'],
                                target_roles=phase['target_roles'],
                                metadata={
                                    'phase': phase['description'],
                                    'contextual_feature': True
                                }
                            )
                        else:
                            # Atualiza flag existente
                            await self.update_feature_flag(
                                name=feature_name,
                                rollout_percentage=phase['percentage'],
                                target_roles=phase['target_roles'],
                                metadata={
                                    'phase': phase['description'],
                                    'contextual_feature': True
                                }
                            )
            
            logger.info("Contextual features initialized")
            
        except Exception as e:
            logger.error(f"Error initializing contextual features: {e}")
            raise
    
    async def _evaluate_rollout_strategy(
        self,
        feature_flag: FeatureFlag,
        user: User,
        context: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Avalia estratégia de rollout para determinar se feature está habilitada"""
        try:
            # Verifica data de início/fim
            now = datetime.utcnow()
            
            if feature_flag.start_date and now < feature_flag.start_date:
                return False
            
            if feature_flag.end_date and now > feature_flag.end_date:
                return False
            
            # Avalia estratégia específica
            if feature_flag.rollout_strategy == RolloutStrategy.USER_LIST:
                return user.id in feature_flag.target_users
            
            elif feature_flag.rollout_strategy == RolloutStrategy.USER_ROLE:
                return user.role in feature_flag.target_roles
            
            elif feature_flag.rollout_strategy == RolloutStrategy.PERCENTAGE:
                return self._is_user_in_percentage(user.id, feature_flag.rollout_percentage)
            
            elif feature_flag.rollout_strategy == RolloutStrategy.GEOGRAPHIC:
                user_region = context.get('region') if context else getattr(user, 'region', None)
                return user_region in feature_flag.target_regions if user_region else False
            
            elif feature_flag.rollout_strategy == RolloutStrategy.DEVICE_TYPE:
                device_type = context.get('device_type') if context else None
                return device_type in feature_flag.device_types if device_type else False
            
            elif feature_flag.rollout_strategy == RolloutStrategy.HYBRID:
                # Combinação de estratégias
                
                # Primeiro verifica lista de usuários específicos
                if user.id in feature_flag.target_users:
                    return True
                
                # Depois verifica role
                if user.role in feature_flag.target_roles:
                    # Se está na role correta, aplica percentual
                    return self._is_user_in_percentage(user.id, feature_flag.rollout_percentage)
                
                return False
            
            return False
            
        except Exception as e:
            logger.error(f"Error evaluating rollout strategy: {e}")
            return False
    
    def _is_user_in_percentage(self, user_id: str, percentage: float) -> bool:
        """Determina se usuário está no percentual de rollout usando hash consistente"""
        try:
            # Usa hash MD5 para garantir distribuição consistente
            hash_input = f"{user_id}_contextual_rollout".encode('utf-8')
            hash_result = hashlib.md5(hash_input).hexdigest()
            
            # Converte primeiros 8 caracteres para int
            hash_int = int(hash_result[:8], 16)
            
            # Calcula percentual (0-100)
            user_percentage = (hash_int % 10000) / 100.0
            
            return user_percentage < percentage
            
        except Exception as e:
            logger.error(f"Error calculating user percentage: {e}")
            return False
    
    async def _store_feature_flag(self, feature_flag: FeatureFlag) -> None:
        """Armazena feature flag no banco"""
        try:
            query = """
            INSERT INTO feature_flags (
                name, description, status, rollout_strategy, rollout_percentage,
                target_users, target_roles, target_regions, device_types,
                start_date, end_date, metadata, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                description = VALUES(description),
                status = VALUES(status),
                rollout_strategy = VALUES(rollout_strategy),
                rollout_percentage = VALUES(rollout_percentage),
                target_users = VALUES(target_users),
                target_roles = VALUES(target_roles),
                target_regions = VALUES(target_regions),
                device_types = VALUES(device_types),
                start_date = VALUES(start_date),
                end_date = VALUES(end_date),
                metadata = VALUES(metadata),
                updated_at = VALUES(updated_at)
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (
                    feature_flag.name,
                    feature_flag.description,
                    feature_flag.status.value,
                    feature_flag.rollout_strategy.value,
                    feature_flag.rollout_percentage,
                    json.dumps(feature_flag.target_users),
                    json.dumps(feature_flag.target_roles),
                    json.dumps(feature_flag.target_regions),
                    json.dumps(feature_flag.device_types),
                    feature_flag.start_date,
                    feature_flag.end_date,
                    json.dumps(feature_flag.metadata),
                    feature_flag.created_at,
                    feature_flag.updated_at
                ))
                self.db.commit()
                
        except Exception as e:
            logger.error(f"Error storing feature flag: {e}")
            self.db.rollback()
            raise
    
    async def _invalidate_feature_cache(self, feature_name: str) -> None:
        """Invalida cache de uma feature flag"""
        try:
            pattern = f"feature_flag:{feature_name}:*"
            keys = await self.redis.keys(pattern)
            
            if keys:
                await self.redis.delete(*keys)
                
        except Exception as e:
            logger.error(f"Error invalidating feature cache: {e}")
    
    async def get_feature_analytics(self, feature_name: str) -> Dict[str, Any]:
        """Obtém analytics de uma feature flag"""
        try:
            query = """
            SELECT 
                COUNT(*) as total_checks,
                SUM(CASE WHEN enabled = true THEN 1 ELSE 0 END) as enabled_count,
                COUNT(DISTINCT user_id) as unique_users,
                AVG(CASE WHEN enabled = true THEN 1 ELSE 0 END) as enable_rate
            FROM feature_flag_logs
            WHERE feature_name = %s
            AND created_at >= %s
            """
            
            start_date = datetime.utcnow() - timedelta(days=7)
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (feature_name, start_date))
                row = cursor.fetchone()
                
                if row:
                    return {
                        'total_checks': row[0],
                        'enabled_count': row[1],
                        'unique_users': row[2],
                        'enable_rate': float(row[3]) if row[3] else 0.0,
                        'period': '7 days'
                    }
                
                return {
                    'total_checks': 0,
                    'enabled_count': 0,
                    'unique_users': 0,
                    'enable_rate': 0.0,
                    'period': '7 days'
                }
                
        except Exception as e:
            logger.error(f"Error getting feature analytics: {e}")
            return {} 