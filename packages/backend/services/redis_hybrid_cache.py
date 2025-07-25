import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import redis.asyncio as redis
from dataclasses import asdict

from ..config.settings import get_settings
from .hybrid_legal_data_service_complete import (
    ConsolidatedLawyerProfile,
    DataSourceType,
    DataSourceInfo
)

logger = logging.getLogger(__name__)
settings = get_settings()

class RedisHybridCache:
    """
    Serviço Redis especializado para cache de dados híbridos
    
    Características:
    - Cache diferenciado por fonte de dados
    - TTL específico por tipo de dados
    - Serialização otimizada para perfis consolidados
    - Invalidação inteligente
    - Métricas de cache
    """
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self.is_connected = False
        
        # Configurações de TTL por fonte
        self.ttl_config = {
            DataSourceType.LINKEDIN: timedelta(hours=getattr(settings, 'LINKEDIN_CACHE_TTL_HOURS', 6)),
            DataSourceType.ACADEMIC: timedelta(hours=getattr(settings, 'ACADEMIC_CACHE_TTL_HOURS', 24)),
            DataSourceType.ESCAVADOR: timedelta(hours=getattr(settings, 'ESCAVADOR_CACHE_TTL_HOURS', 12)),
            DataSourceType.JUSBRASIL: timedelta(hours=getattr(settings, 'JUSBRASIL_CACHE_TTL_HOURS', 12)),
            DataSourceType.DEEP_RESEARCH: timedelta(hours=getattr(settings, 'DEEP_RESEARCH_CACHE_TTL_HOURS', 48)),
            DataSourceType.INTERNAL: timedelta(hours=getattr(settings, 'INTERNAL_CACHE_TTL_HOURS', 1))
        }
        
        # Prefixos para organização
        self.key_prefixes = {
            'consolidated_profile': 'hybrid:profile:consolidated:',
            'source_data': 'hybrid:source:',
            'quality_report': 'hybrid:quality:',
            'transparency_report': 'hybrid:transparency:',
            'metadata': 'hybrid:meta:',
            'metrics': 'hybrid:metrics:'
        }
    
    async def initialize(self):
        """Inicializar conexão Redis"""
        try:
            redis_url = getattr(settings, 'REDIS_URL', 'redis://localhost:6379/0')
            
            self.redis_client = redis.from_url(
                redis_url,
                encoding='utf-8',
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True,
                health_check_interval=30
            )
            
            # Testar conexão
            await self.redis_client.ping()
            self.is_connected = True
            
            logger.info("Redis Hybrid Cache inicializado com sucesso")
            
        except Exception as e:
            logger.error(f"Erro ao inicializar Redis Hybrid Cache: {str(e)}")
            self.is_connected = False
            self.redis_client = None
    
    async def cache_consolidated_profile(
        self,
        lawyer_id: str,
        profile: ConsolidatedLawyerProfile
    ) -> bool:
        """
        Cachear perfil consolidado completo
        
        Args:
            lawyer_id: ID do advogado
            profile: Perfil consolidado
            
        Returns:
            True se cacheado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            # Chave principal do perfil
            profile_key = f"{self.key_prefixes['consolidated_profile']}{lawyer_id}"
            
            # Serializar perfil (convertendo para dict)
            profile_data = self._serialize_profile(profile)
            
            # TTL baseado na fonte com menor TTL para invalidação inteligente
            min_ttl = min(self.ttl_config.values())
            ttl_seconds = int(min_ttl.total_seconds())
            
            # Pipeline para operações atômicas
            pipe = self.redis_client.pipeline()
            
            # Cachear perfil principal
            pipe.setex(profile_key, ttl_seconds, json.dumps(profile_data))
            
            # Cachear dados por fonte individualmente
            for source_type, source_info in profile.data_sources.items():
                source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
                source_ttl = int(self.ttl_config[source_type].total_seconds())
                
                source_data = {
                    'source_type': source_type.value,
                    'last_updated': source_info.last_updated.isoformat(),
                    'quality': source_info.quality.value,
                    'confidence_score': source_info.confidence_score,
                    'fields_available': source_info.fields_available,
                    'cost_per_query': source_info.cost_per_query
                }
                
                pipe.setex(source_key, source_ttl, json.dumps(source_data))
            
            # Cachear metadados
            metadata_key = f"{self.key_prefixes['metadata']}{lawyer_id}"
            metadata = {
                'last_consolidated': profile.last_consolidated.isoformat(),
                'overall_quality_score': profile.overall_quality_score,
                'completeness_score': profile.completeness_score,
                'sources_count': len(profile.data_sources),
                'cached_at': datetime.utcnow().isoformat()
            }
            pipe.setex(metadata_key, ttl_seconds, json.dumps(metadata))
            
            # Executar pipeline
            await pipe.execute()
            
            # Incrementar métricas
            await self._increment_cache_metrics('profiles_cached')
            
            logger.info(f"Perfil consolidado cacheado: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao cachear perfil consolidado {lawyer_id}: {str(e)}")
            return False
    
    async def get_consolidated_profile(
        self,
        lawyer_id: str
    ) -> Optional[ConsolidatedLawyerProfile]:
        """
        Recuperar perfil consolidado do cache
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            Perfil consolidado ou None se não encontrado
        """
        if not self.is_connected or not self.redis_client:
            return None
        
        try:
            profile_key = f"{self.key_prefixes['consolidated_profile']}{lawyer_id}"
            
            # Buscar dados do perfil
            profile_json = await self.redis_client.get(profile_key)
            
            if not profile_json:
                await self._increment_cache_metrics('profiles_miss')
                return None
            
            # Deserializar perfil
            profile_data = json.loads(profile_json)
            profile = self._deserialize_profile(profile_data)
            
            # Incrementar métricas
            await self._increment_cache_metrics('profiles_hit')
            
            logger.debug(f"Perfil consolidado recuperado do cache: {lawyer_id}")
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao recuperar perfil do cache {lawyer_id}: {str(e)}")
            await self._increment_cache_metrics('profiles_error')
            return None
    
    async def cache_source_data(
        self,
        lawyer_id: str,
        source_type: DataSourceType,
        data: Any,
        source_info: DataSourceInfo
    ) -> bool:
        """
        Cachear dados de uma fonte específica
        
        Args:
            lawyer_id: ID do advogado
            source_type: Tipo da fonte
            data: Dados da fonte
            source_info: Informações da fonte
            
        Returns:
            True se cacheado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
            
            # Serializar dados da fonte
            cache_data = {
                'data': self._serialize_source_data(data),
                'source_info': {
                    'source_type': source_type.value,
                    'last_updated': source_info.last_updated.isoformat(),
                    'quality': source_info.quality.value,
                    'confidence_score': source_info.confidence_score,
                    'fields_available': source_info.fields_available,
                    'cost_per_query': source_info.cost_per_query
                },
                'cached_at': datetime.utcnow().isoformat()
            }
            
            # TTL específico da fonte
            ttl_seconds = int(self.ttl_config[source_type].total_seconds())
            
            # Cachear
            await self.redis_client.setex(
                source_key,
                ttl_seconds,
                json.dumps(cache_data)
            )
            
            await self._increment_cache_metrics(f'source_{source_type.value}_cached')
            
            logger.debug(f"Dados da fonte {source_type.value} cacheados: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao cachear dados da fonte {source_type.value} {lawyer_id}: {str(e)}")
            return False
    
    async def get_source_data(
        self,
        lawyer_id: str,
        source_type: DataSourceType
    ) -> Optional[Dict[str, Any]]:
        """
        Recuperar dados de uma fonte específica
        
        Args:
            lawyer_id: ID do advogado
            source_type: Tipo da fonte
            
        Returns:
            Dados da fonte ou None se não encontrado
        """
        if not self.is_connected or not self.redis_client:
            return None
        
        try:
            source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
            
            # Buscar dados
            cache_json = await self.redis_client.get(source_key)
            
            if not cache_json:
                await self._increment_cache_metrics(f'source_{source_type.value}_miss')
                return None
            
            cache_data = json.loads(cache_json)
            
            await self._increment_cache_metrics(f'source_{source_type.value}_hit')
            
            return cache_data
            
        except Exception as e:
            logger.error(f"Erro ao recuperar dados da fonte {source_type.value} {lawyer_id}: {str(e)}")
            return None
    
    async def invalidate_profile(self, lawyer_id: str) -> bool:
        """
        Invalidar todos os dados de cache de um advogado
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            True se invalidado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            # Buscar todas as chaves relacionadas
            patterns = [
                f"{self.key_prefixes['consolidated_profile']}{lawyer_id}*",
                f"{self.key_prefixes['source_data']}{lawyer_id}:*",
                f"{self.key_prefixes['quality_report']}{lawyer_id}*",
                f"{self.key_prefixes['transparency_report']}{lawyer_id}*",
                f"{self.key_prefixes['metadata']}{lawyer_id}*"
            ]
            
            keys_to_delete = []
            for pattern in patterns:
                keys = await self.redis_client.keys(pattern)
                keys_to_delete.extend(keys)
            
            # Deletar em lote
            if keys_to_delete:
                await self.redis_client.delete(*keys_to_delete)
            
            await self._increment_cache_metrics('profiles_invalidated')
            
            logger.info(f"Cache invalidado para advogado: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao invalidar cache {lawyer_id}: {str(e)}")
            return False
    
    async def get_cache_statistics(self) -> Dict[str, Any]:
        """
        Obter estatísticas do cache híbrido
        
        Returns:
            Estatísticas do cache
        """
        if not self.is_connected or not self.redis_client:
            return {'status': 'disconnected'}
        
        try:
            # Buscar métricas
            metrics_keys = await self.redis_client.keys(f"{self.key_prefixes['metrics']}*")
            metrics = {}
            
            for key in metrics_keys:
                metric_name = key.replace(self.key_prefixes['metrics'], '')
                value = await self.redis_client.get(key)
                metrics[metric_name] = int(value) if value else 0
            
            # Calcular estatísticas gerais
            total_profiles = await self.redis_client.keys(f"{self.key_prefixes['consolidated_profile']}*")
            total_sources = await self.redis_client.keys(f"{self.key_prefixes['source_data']}*")
            
            # Informações do Redis
            redis_info = await self.redis_client.info()
            
            statistics = {
                'status': 'connected',
                'cache_metrics': metrics,
                'cache_counts': {
                    'consolidated_profiles': len(total_profiles),
                    'source_data_entries': len(total_sources),
                },
                'redis_info': {
                    'used_memory': redis_info.get('used_memory_human'),
                    'connected_clients': redis_info.get('connected_clients'),
                    'total_commands_processed': redis_info.get('total_commands_processed'),
                    'keyspace_hits': redis_info.get('keyspace_hits'),
                    'keyspace_misses': redis_info.get('keyspace_misses'),
                    'hit_rate': self._calculate_hit_rate(redis_info)
                },
                'ttl_config': {
                    source.value: int(ttl.total_seconds() / 3600)
                    for source, ttl in self.ttl_config.items()
                },
                'generated_at': datetime.utcnow().isoformat()
            }
            
            return statistics
            
        except Exception as e:
            logger.error(f"Erro ao obter estatísticas do cache: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    def _serialize_profile(self, profile: ConsolidatedLawyerProfile) -> Dict[str, Any]:
        """Serializar perfil consolidado para JSON"""
        try:
            # Converter para dict, tratando campos especiais
            data = {
                'lawyer_id': profile.lawyer_id,
                'full_name': profile.full_name,
                'alternative_names': profile.alternative_names,
                'linkedin_profile': self._serialize_linkedin_profile(profile.linkedin_profile),
                'academic_profile': self._serialize_academic_profile(profile.academic_profile),
                'legal_cases_data': profile.legal_cases_data,
                'market_insights': profile.market_insights,
                'platform_metrics': profile.platform_metrics,
                'data_sources': {
                    source_type.value: {
                        'source_type': source_info.source_type.value,
                        'last_updated': source_info.last_updated.isoformat(),
                        'quality': source_info.quality.value,
                        'confidence_score': source_info.confidence_score,
                        'fields_available': source_info.fields_available,
                        'cost_per_query': source_info.cost_per_query,
                        'rate_limit_per_hour': source_info.rate_limit_per_hour
                    }
                    for source_type, source_info in profile.data_sources.items()
                },
                'overall_quality_score': profile.overall_quality_score,
                'completeness_score': profile.completeness_score,
                'last_consolidated': profile.last_consolidated.isoformat(),
                'consolidation_version': profile.consolidation_version,
                'social_influence_score': profile.social_influence_score,
                'academic_prestige_score': profile.academic_prestige_score,
                'legal_expertise_score': profile.legal_expertise_score,
                'market_reputation_score': profile.market_reputation_score,
                'overall_success_probability': profile.overall_success_probability
            }
            
            return data
            
        except Exception as e:
            logger.error(f"Erro ao serializar perfil: {str(e)}")
            raise
    
    def _deserialize_profile(self, data: Dict[str, Any]) -> ConsolidatedLawyerProfile:
        """Deserializar perfil consolidado do JSON"""
        try:
            # TODO: Implementar deserialização completa
            # Por ora, retornar estrutura básica
            from .hybrid_legal_data_service_complete import ConsolidatedLawyerProfile
            
            # Converter data_sources de volta para objetos
            data_sources = {}
            for source_type_str, source_data in data.get('data_sources', {}).items():
                source_type = DataSourceType(source_type_str)
                data_sources[source_type] = DataSourceInfo(
                    source_type=DataSourceType(source_data['source_type']),
                    last_updated=datetime.fromisoformat(source_data['last_updated']),
                    quality=source_data['quality'],
                    confidence_score=source_data['confidence_score'],
                    fields_available=source_data['fields_available'],
                    cost_per_query=source_data['cost_per_query'],
                    rate_limit_per_hour=source_data.get('rate_limit_per_hour', 100)
                )
            
            profile = ConsolidatedLawyerProfile(
                lawyer_id=data['lawyer_id'],
                full_name=data['full_name'],
                alternative_names=data['alternative_names'],
                data_sources=data_sources,
                overall_quality_score=data['overall_quality_score'],
                completeness_score=data['completeness_score'],
                last_consolidated=datetime.fromisoformat(data['last_consolidated']),
                consolidation_version=data.get('consolidation_version', '1.0'),
                social_influence_score=data.get('social_influence_score', 0.0),
                academic_prestige_score=data.get('academic_prestige_score', 0.0),
                legal_expertise_score=data.get('legal_expertise_score', 0.0),
                market_reputation_score=data.get('market_reputation_score', 0.0),
                overall_success_probability=data.get('overall_success_probability', 0.0)
            )
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao deserializar perfil: {str(e)}")
            raise
    
    def _serialize_linkedin_profile(self, profile) -> Optional[Dict[str, Any]]:
        """Serializar perfil LinkedIn"""
        if not profile:
            return None
        
        try:
            # TODO: Implementar serialização específica do LinkedIn
            return {
                'linkedin_id': profile.linkedin_id,
                'full_name': profile.full_name,
                'headline': profile.headline,
                'data_quality_score': profile.data_quality_score
            }
        except Exception:
            return None
    
    def _serialize_academic_profile(self, profile) -> Optional[Dict[str, Any]]:
        """Serializar perfil acadêmico"""
        if not profile:
            return None
        
        try:
            # TODO: Implementar serialização específica acadêmica
            return {
                'full_name': profile.full_name,
                'academic_prestige_score': profile.academic_prestige_score,
                'confidence_score': profile.confidence_score
            }
        except Exception:
            return None
    
    def _serialize_source_data(self, data: Any) -> Any:
        """Serializar dados de fonte específica"""
        try:
            if hasattr(data, '__dict__'):
                return asdict(data) if hasattr(asdict, '__call__') else data.__dict__
            return data
        except Exception:
            return str(data)
    
    async def _increment_cache_metrics(self, metric_name: str):
        """Incrementar métrica de cache"""
        if not self.is_connected or not self.redis_client:
            return
        
        try:
            metric_key = f"{self.key_prefixes['metrics']}{metric_name}"
            await self.redis_client.incr(metric_key)
            # Configurar expiração de 24 horas para métricas
            await self.redis_client.expire(metric_key, 86400)
        except Exception as e:
            logger.debug(f"Erro ao incrementar métrica {metric_name}: {str(e)}")
    
    def _calculate_hit_rate(self, redis_info: Dict[str, Any]) -> float:
        """Calcular taxa de acerto do cache"""
        try:
            hits = redis_info.get('keyspace_hits', 0)
            misses = redis_info.get('keyspace_misses', 0)
            total = hits + misses
            
            if total == 0:
                return 0.0
            
            return round((hits / total) * 100, 2)
            
        except Exception:
            return 0.0
    
    async def close(self):
        """Fechar conexão Redis"""
        if self.redis_client:
            await self.redis_client.close()
            self.is_connected = False
            logger.info("Redis Hybrid Cache fechado")

# Instância global
redis_hybrid_cache = RedisHybridCache() 
import json
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import redis.asyncio as redis
from dataclasses import asdict

from ..config.settings import get_settings
from .hybrid_legal_data_service_complete import (
    ConsolidatedLawyerProfile,
    DataSourceType,
    DataSourceInfo
)

logger = logging.getLogger(__name__)
settings = get_settings()

class RedisHybridCache:
    """
    Serviço Redis especializado para cache de dados híbridos
    
    Características:
    - Cache diferenciado por fonte de dados
    - TTL específico por tipo de dados
    - Serialização otimizada para perfis consolidados
    - Invalidação inteligente
    - Métricas de cache
    """
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self.is_connected = False
        
        # Configurações de TTL por fonte
        self.ttl_config = {
            DataSourceType.LINKEDIN: timedelta(hours=getattr(settings, 'LINKEDIN_CACHE_TTL_HOURS', 6)),
            DataSourceType.ACADEMIC: timedelta(hours=getattr(settings, 'ACADEMIC_CACHE_TTL_HOURS', 24)),
            DataSourceType.ESCAVADOR: timedelta(hours=getattr(settings, 'ESCAVADOR_CACHE_TTL_HOURS', 12)),
            DataSourceType.JUSBRASIL: timedelta(hours=getattr(settings, 'JUSBRASIL_CACHE_TTL_HOURS', 12)),
            DataSourceType.DEEP_RESEARCH: timedelta(hours=getattr(settings, 'DEEP_RESEARCH_CACHE_TTL_HOURS', 48)),
            DataSourceType.INTERNAL: timedelta(hours=getattr(settings, 'INTERNAL_CACHE_TTL_HOURS', 1))
        }
        
        # Prefixos para organização
        self.key_prefixes = {
            'consolidated_profile': 'hybrid:profile:consolidated:',
            'source_data': 'hybrid:source:',
            'quality_report': 'hybrid:quality:',
            'transparency_report': 'hybrid:transparency:',
            'metadata': 'hybrid:meta:',
            'metrics': 'hybrid:metrics:'
        }
    
    async def initialize(self):
        """Inicializar conexão Redis"""
        try:
            redis_url = getattr(settings, 'REDIS_URL', 'redis://localhost:6379/0')
            
            self.redis_client = redis.from_url(
                redis_url,
                encoding='utf-8',
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True,
                health_check_interval=30
            )
            
            # Testar conexão
            await self.redis_client.ping()
            self.is_connected = True
            
            logger.info("Redis Hybrid Cache inicializado com sucesso")
            
        except Exception as e:
            logger.error(f"Erro ao inicializar Redis Hybrid Cache: {str(e)}")
            self.is_connected = False
            self.redis_client = None
    
    async def cache_consolidated_profile(
        self,
        lawyer_id: str,
        profile: ConsolidatedLawyerProfile
    ) -> bool:
        """
        Cachear perfil consolidado completo
        
        Args:
            lawyer_id: ID do advogado
            profile: Perfil consolidado
            
        Returns:
            True se cacheado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            # Chave principal do perfil
            profile_key = f"{self.key_prefixes['consolidated_profile']}{lawyer_id}"
            
            # Serializar perfil (convertendo para dict)
            profile_data = self._serialize_profile(profile)
            
            # TTL baseado na fonte com menor TTL para invalidação inteligente
            min_ttl = min(self.ttl_config.values())
            ttl_seconds = int(min_ttl.total_seconds())
            
            # Pipeline para operações atômicas
            pipe = self.redis_client.pipeline()
            
            # Cachear perfil principal
            pipe.setex(profile_key, ttl_seconds, json.dumps(profile_data))
            
            # Cachear dados por fonte individualmente
            for source_type, source_info in profile.data_sources.items():
                source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
                source_ttl = int(self.ttl_config[source_type].total_seconds())
                
                source_data = {
                    'source_type': source_type.value,
                    'last_updated': source_info.last_updated.isoformat(),
                    'quality': source_info.quality.value,
                    'confidence_score': source_info.confidence_score,
                    'fields_available': source_info.fields_available,
                    'cost_per_query': source_info.cost_per_query
                }
                
                pipe.setex(source_key, source_ttl, json.dumps(source_data))
            
            # Cachear metadados
            metadata_key = f"{self.key_prefixes['metadata']}{lawyer_id}"
            metadata = {
                'last_consolidated': profile.last_consolidated.isoformat(),
                'overall_quality_score': profile.overall_quality_score,
                'completeness_score': profile.completeness_score,
                'sources_count': len(profile.data_sources),
                'cached_at': datetime.utcnow().isoformat()
            }
            pipe.setex(metadata_key, ttl_seconds, json.dumps(metadata))
            
            # Executar pipeline
            await pipe.execute()
            
            # Incrementar métricas
            await self._increment_cache_metrics('profiles_cached')
            
            logger.info(f"Perfil consolidado cacheado: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao cachear perfil consolidado {lawyer_id}: {str(e)}")
            return False
    
    async def get_consolidated_profile(
        self,
        lawyer_id: str
    ) -> Optional[ConsolidatedLawyerProfile]:
        """
        Recuperar perfil consolidado do cache
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            Perfil consolidado ou None se não encontrado
        """
        if not self.is_connected or not self.redis_client:
            return None
        
        try:
            profile_key = f"{self.key_prefixes['consolidated_profile']}{lawyer_id}"
            
            # Buscar dados do perfil
            profile_json = await self.redis_client.get(profile_key)
            
            if not profile_json:
                await self._increment_cache_metrics('profiles_miss')
                return None
            
            # Deserializar perfil
            profile_data = json.loads(profile_json)
            profile = self._deserialize_profile(profile_data)
            
            # Incrementar métricas
            await self._increment_cache_metrics('profiles_hit')
            
            logger.debug(f"Perfil consolidado recuperado do cache: {lawyer_id}")
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao recuperar perfil do cache {lawyer_id}: {str(e)}")
            await self._increment_cache_metrics('profiles_error')
            return None
    
    async def cache_source_data(
        self,
        lawyer_id: str,
        source_type: DataSourceType,
        data: Any,
        source_info: DataSourceInfo
    ) -> bool:
        """
        Cachear dados de uma fonte específica
        
        Args:
            lawyer_id: ID do advogado
            source_type: Tipo da fonte
            data: Dados da fonte
            source_info: Informações da fonte
            
        Returns:
            True se cacheado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
            
            # Serializar dados da fonte
            cache_data = {
                'data': self._serialize_source_data(data),
                'source_info': {
                    'source_type': source_type.value,
                    'last_updated': source_info.last_updated.isoformat(),
                    'quality': source_info.quality.value,
                    'confidence_score': source_info.confidence_score,
                    'fields_available': source_info.fields_available,
                    'cost_per_query': source_info.cost_per_query
                },
                'cached_at': datetime.utcnow().isoformat()
            }
            
            # TTL específico da fonte
            ttl_seconds = int(self.ttl_config[source_type].total_seconds())
            
            # Cachear
            await self.redis_client.setex(
                source_key,
                ttl_seconds,
                json.dumps(cache_data)
            )
            
            await self._increment_cache_metrics(f'source_{source_type.value}_cached')
            
            logger.debug(f"Dados da fonte {source_type.value} cacheados: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao cachear dados da fonte {source_type.value} {lawyer_id}: {str(e)}")
            return False
    
    async def get_source_data(
        self,
        lawyer_id: str,
        source_type: DataSourceType
    ) -> Optional[Dict[str, Any]]:
        """
        Recuperar dados de uma fonte específica
        
        Args:
            lawyer_id: ID do advogado
            source_type: Tipo da fonte
            
        Returns:
            Dados da fonte ou None se não encontrado
        """
        if not self.is_connected or not self.redis_client:
            return None
        
        try:
            source_key = f"{self.key_prefixes['source_data']}{lawyer_id}:{source_type.value}"
            
            # Buscar dados
            cache_json = await self.redis_client.get(source_key)
            
            if not cache_json:
                await self._increment_cache_metrics(f'source_{source_type.value}_miss')
                return None
            
            cache_data = json.loads(cache_json)
            
            await self._increment_cache_metrics(f'source_{source_type.value}_hit')
            
            return cache_data
            
        except Exception as e:
            logger.error(f"Erro ao recuperar dados da fonte {source_type.value} {lawyer_id}: {str(e)}")
            return None
    
    async def invalidate_profile(self, lawyer_id: str) -> bool:
        """
        Invalidar todos os dados de cache de um advogado
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            True se invalidado com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False
        
        try:
            # Buscar todas as chaves relacionadas
            patterns = [
                f"{self.key_prefixes['consolidated_profile']}{lawyer_id}*",
                f"{self.key_prefixes['source_data']}{lawyer_id}:*",
                f"{self.key_prefixes['quality_report']}{lawyer_id}*",
                f"{self.key_prefixes['transparency_report']}{lawyer_id}*",
                f"{self.key_prefixes['metadata']}{lawyer_id}*"
            ]
            
            keys_to_delete = []
            for pattern in patterns:
                keys = await self.redis_client.keys(pattern)
                keys_to_delete.extend(keys)
            
            # Deletar em lote
            if keys_to_delete:
                await self.redis_client.delete(*keys_to_delete)
            
            await self._increment_cache_metrics('profiles_invalidated')
            
            logger.info(f"Cache invalidado para advogado: {lawyer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao invalidar cache {lawyer_id}: {str(e)}")
            return False
    
    async def get_cache_statistics(self) -> Dict[str, Any]:
        """
        Obter estatísticas do cache híbrido
        
        Returns:
            Estatísticas do cache
        """
        if not self.is_connected or not self.redis_client:
            return {'status': 'disconnected'}
        
        try:
            # Buscar métricas
            metrics_keys = await self.redis_client.keys(f"{self.key_prefixes['metrics']}*")
            metrics = {}
            
            for key in metrics_keys:
                metric_name = key.replace(self.key_prefixes['metrics'], '')
                value = await self.redis_client.get(key)
                metrics[metric_name] = int(value) if value else 0
            
            # Calcular estatísticas gerais
            total_profiles = await self.redis_client.keys(f"{self.key_prefixes['consolidated_profile']}*")
            total_sources = await self.redis_client.keys(f"{self.key_prefixes['source_data']}*")
            
            # Informações do Redis
            redis_info = await self.redis_client.info()
            
            statistics = {
                'status': 'connected',
                'cache_metrics': metrics,
                'cache_counts': {
                    'consolidated_profiles': len(total_profiles),
                    'source_data_entries': len(total_sources),
                },
                'redis_info': {
                    'used_memory': redis_info.get('used_memory_human'),
                    'connected_clients': redis_info.get('connected_clients'),
                    'total_commands_processed': redis_info.get('total_commands_processed'),
                    'keyspace_hits': redis_info.get('keyspace_hits'),
                    'keyspace_misses': redis_info.get('keyspace_misses'),
                    'hit_rate': self._calculate_hit_rate(redis_info)
                },
                'ttl_config': {
                    source.value: int(ttl.total_seconds() / 3600)
                    for source, ttl in self.ttl_config.items()
                },
                'generated_at': datetime.utcnow().isoformat()
            }
            
            return statistics
            
        except Exception as e:
            logger.error(f"Erro ao obter estatísticas do cache: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    def _serialize_profile(self, profile: ConsolidatedLawyerProfile) -> Dict[str, Any]:
        """Serializar perfil consolidado para JSON"""
        try:
            # Converter para dict, tratando campos especiais
            data = {
                'lawyer_id': profile.lawyer_id,
                'full_name': profile.full_name,
                'alternative_names': profile.alternative_names,
                'linkedin_profile': self._serialize_linkedin_profile(profile.linkedin_profile),
                'academic_profile': self._serialize_academic_profile(profile.academic_profile),
                'legal_cases_data': profile.legal_cases_data,
                'market_insights': profile.market_insights,
                'platform_metrics': profile.platform_metrics,
                'data_sources': {
                    source_type.value: {
                        'source_type': source_info.source_type.value,
                        'last_updated': source_info.last_updated.isoformat(),
                        'quality': source_info.quality.value,
                        'confidence_score': source_info.confidence_score,
                        'fields_available': source_info.fields_available,
                        'cost_per_query': source_info.cost_per_query,
                        'rate_limit_per_hour': source_info.rate_limit_per_hour
                    }
                    for source_type, source_info in profile.data_sources.items()
                },
                'overall_quality_score': profile.overall_quality_score,
                'completeness_score': profile.completeness_score,
                'last_consolidated': profile.last_consolidated.isoformat(),
                'consolidation_version': profile.consolidation_version,
                'social_influence_score': profile.social_influence_score,
                'academic_prestige_score': profile.academic_prestige_score,
                'legal_expertise_score': profile.legal_expertise_score,
                'market_reputation_score': profile.market_reputation_score,
                'overall_success_probability': profile.overall_success_probability
            }
            
            return data
            
        except Exception as e:
            logger.error(f"Erro ao serializar perfil: {str(e)}")
            raise
    
    def _deserialize_profile(self, data: Dict[str, Any]) -> ConsolidatedLawyerProfile:
        """Deserializar perfil consolidado do JSON"""
        try:
            # TODO: Implementar deserialização completa
            # Por ora, retornar estrutura básica
            from .hybrid_legal_data_service_complete import ConsolidatedLawyerProfile
            
            # Converter data_sources de volta para objetos
            data_sources = {}
            for source_type_str, source_data in data.get('data_sources', {}).items():
                source_type = DataSourceType(source_type_str)
                data_sources[source_type] = DataSourceInfo(
                    source_type=DataSourceType(source_data['source_type']),
                    last_updated=datetime.fromisoformat(source_data['last_updated']),
                    quality=source_data['quality'],
                    confidence_score=source_data['confidence_score'],
                    fields_available=source_data['fields_available'],
                    cost_per_query=source_data['cost_per_query'],
                    rate_limit_per_hour=source_data.get('rate_limit_per_hour', 100)
                )
            
            profile = ConsolidatedLawyerProfile(
                lawyer_id=data['lawyer_id'],
                full_name=data['full_name'],
                alternative_names=data['alternative_names'],
                data_sources=data_sources,
                overall_quality_score=data['overall_quality_score'],
                completeness_score=data['completeness_score'],
                last_consolidated=datetime.fromisoformat(data['last_consolidated']),
                consolidation_version=data.get('consolidation_version', '1.0'),
                social_influence_score=data.get('social_influence_score', 0.0),
                academic_prestige_score=data.get('academic_prestige_score', 0.0),
                legal_expertise_score=data.get('legal_expertise_score', 0.0),
                market_reputation_score=data.get('market_reputation_score', 0.0),
                overall_success_probability=data.get('overall_success_probability', 0.0)
            )
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao deserializar perfil: {str(e)}")
            raise
    
    def _serialize_linkedin_profile(self, profile) -> Optional[Dict[str, Any]]:
        """Serializar perfil LinkedIn"""
        if not profile:
            return None
        
        try:
            # TODO: Implementar serialização específica do LinkedIn
            return {
                'linkedin_id': profile.linkedin_id,
                'full_name': profile.full_name,
                'headline': profile.headline,
                'data_quality_score': profile.data_quality_score
            }
        except Exception:
            return None
    
    def _serialize_academic_profile(self, profile) -> Optional[Dict[str, Any]]:
        """Serializar perfil acadêmico"""
        if not profile:
            return None
        
        try:
            # TODO: Implementar serialização específica acadêmica
            return {
                'full_name': profile.full_name,
                'academic_prestige_score': profile.academic_prestige_score,
                'confidence_score': profile.confidence_score
            }
        except Exception:
            return None
    
    def _serialize_source_data(self, data: Any) -> Any:
        """Serializar dados de fonte específica"""
        try:
            if hasattr(data, '__dict__'):
                return asdict(data) if hasattr(asdict, '__call__') else data.__dict__
            return data
        except Exception:
            return str(data)
    
    async def _increment_cache_metrics(self, metric_name: str):
        """Incrementar métrica de cache"""
        if not self.is_connected or not self.redis_client:
            return
        
        try:
            metric_key = f"{self.key_prefixes['metrics']}{metric_name}"
            await self.redis_client.incr(metric_key)
            # Configurar expiração de 24 horas para métricas
            await self.redis_client.expire(metric_key, 86400)
        except Exception as e:
            logger.debug(f"Erro ao incrementar métrica {metric_name}: {str(e)}")
    
    def _calculate_hit_rate(self, redis_info: Dict[str, Any]) -> float:
        """Calcular taxa de acerto do cache"""
        try:
            hits = redis_info.get('keyspace_hits', 0)
            misses = redis_info.get('keyspace_misses', 0)
            total = hits + misses
            
            if total == 0:
                return 0.0
            
            return round((hits / total) * 100, 2)
            
        except Exception:
            return 0.0
    
    async def close(self):
        """Fechar conexão Redis"""
        if self.redis_client:
            await self.redis_client.close()
            self.is_connected = False
            logger.info("Redis Hybrid Cache fechado")

# Instância global
redis_hybrid_cache = RedisHybridCache() 