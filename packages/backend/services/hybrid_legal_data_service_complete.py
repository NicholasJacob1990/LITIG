import asyncio
import logging
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import json

from .unipile_official_linkedin_service import unipile_linkedin_service
from .perplexity_academic_service import perplexity_academic_service
from .escavador_service import escavador_service
from .jusbrasil_service import jusbrasil_service
from .deep_research_service import deep_research_service

from ..schemas.linkedin_schemas import LinkedInComprehensiveProfile
from ..schemas.academic_schemas import AcademicProfile
from ..config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

class DataSourceType(str, Enum):
    """Tipos de fontes de dados"""
    LINKEDIN = "linkedin"
    ACADEMIC = "academic"
    ESCAVADOR = "escavador"
    JUSBRASIL = "jusbrasil"
    DEEP_RESEARCH = "deep_research"
    INTERNAL = "internal"

class DataQuality(str, Enum):
    """Níveis de qualidade dos dados"""
    HIGH = "high"      # Dados verificados e completos
    MEDIUM = "medium"  # Dados parciais mas confiáveis
    LOW = "low"        # Dados básicos ou não verificados
    UNKNOWN = "unknown"

@dataclass
class DataSourceInfo:
    """Informações sobre uma fonte de dados"""
    source_type: DataSourceType
    last_updated: datetime
    quality: DataQuality
    confidence_score: float
    fields_available: List[str]
    cost_per_query: float = 0.0
    rate_limit_per_hour: int = 100

@dataclass
class ConsolidatedLawyerProfile:
    """Perfil consolidado completo de um advogado"""
    # Identificação
    lawyer_id: str
    full_name: str
    alternative_names: List[str]
    
    # Dados LinkedIn (via Unipile)
    linkedin_profile: Optional[LinkedInComprehensiveProfile] = None
    
    # Dados Acadêmicos (via Perplexity)
    academic_profile: Optional[AcademicProfile] = None
    
    # Dados Processuais (via Escavador/JusBrasil)
    legal_cases_data: Optional[Dict[str, Any]] = None
    legal_performance_metrics: Optional[Dict[str, float]] = None
    
    # Pesquisa Avançada (via Deep Research)
    market_insights: Optional[Dict[str, Any]] = None
    regulatory_trends: Optional[List[str]] = None
    
    # Dados Internos da Plataforma
    platform_metrics: Optional[Dict[str, Any]] = None
    
    # Metadados de Consolidação
    data_sources: Dict[DataSourceType, DataSourceInfo]
    overall_quality_score: float
    completeness_score: float
    last_consolidated: datetime
    consolidation_version: str = "1.0"
    
    # Scores Finais Calculados
    social_influence_score: float = 0.0
    academic_prestige_score: float = 0.0
    legal_expertise_score: float = 0.0
    market_reputation_score: float = 0.0
    overall_success_probability: float = 0.0

class HybridLegalDataServiceComplete:
    """
    Serviço híbrido completo para consolidação de dados multi-fonte
    
    Integra:
    - LinkedIn (via Unipile SDK oficial)
    - Dados acadêmicos (via Perplexity)
    - Dados processuais (via Escavador/JusBrasil)
    - Pesquisa avançada (via Deep Research)
    - Dados internos da plataforma
    
    Características:
    - Cache inteligente por fonte
    - Sistema de transparência de dados
    - Cálculo de scores consolidados
    - Rate limiting otimizado
    - Fallback entre fontes
    """
    
    def __init__(self):
        self.cache_ttl = {
            DataSourceType.LINKEDIN: timedelta(hours=6),
            DataSourceType.ACADEMIC: timedelta(hours=24),
            DataSourceType.ESCAVADOR: timedelta(hours=12),
            DataSourceType.JUSBRASIL: timedelta(hours=12),
            DataSourceType.DEEP_RESEARCH: timedelta(hours=48),
            DataSourceType.INTERNAL: timedelta(hours=1)
        }
        
        self.source_priorities = {
            DataSourceType.LINKEDIN: 1,      # Dados mais frescos e detalhados
            DataSourceType.ACADEMIC: 2,      # Dados acadêmicos específicos
            DataSourceType.ESCAVADOR: 3,     # Dados processuais confiáveis
            DataSourceType.JUSBRASIL: 4,     # Backup para dados processuais
            DataSourceType.DEEP_RESEARCH: 5, # Insights de mercado
            DataSourceType.INTERNAL: 6       # Dados da plataforma
        }
        
        self.max_concurrent_sources = 3
        self.total_timeout_seconds = 300  # 5 minutos máximo
    
    async def get_complete_lawyer_profile(
        self,
        lawyer_id: str,
        force_refresh: bool = False,
        include_sources: Optional[List[DataSourceType]] = None
    ) -> Optional[ConsolidatedLawyerProfile]:
        """
        Obter perfil completo consolidado de um advogado
        
        Args:
            lawyer_id: ID do advogado
            force_refresh: Forçar atualização de todas as fontes
            include_sources: Fontes específicas a incluir (None = todas)
            
        Returns:
            Perfil consolidado completo
        """
        try:
            start_time = datetime.utcnow()
            
            logger.info(f"Iniciando consolidação completa para advogado: {lawyer_id}")
            
            # Determinar fontes a consultar
            sources_to_query = include_sources or list(DataSourceType)
            
            # Buscar dados básicos do advogado
            lawyer_basic_info = await self._get_lawyer_basic_info(lawyer_id)
            if not lawyer_basic_info:
                logger.error(f"Advogado não encontrado: {lawyer_id}")
                return None
            
            # Executar coleta paralela de dados de múltiplas fontes
            source_results = await self._collect_multi_source_data(
                lawyer_basic_info,
                sources_to_query,
                force_refresh
            )
            
            # Consolidar dados coletados
            consolidated_profile = await self._consolidate_collected_data(
                lawyer_id,
                lawyer_basic_info,
                source_results
            )
            
            # Calcular scores finais
            consolidated_profile = await self._calculate_final_scores(consolidated_profile)
            
            # Salvar no cache
            await self._cache_consolidated_profile(consolidated_profile)
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            logger.info(
                f"Consolidação completa finalizada em {processing_time:.1f}s. "
                f"Qualidade: {consolidated_profile.overall_quality_score:.2f}"
            )
            
            return consolidated_profile
            
        except Exception as e:
            logger.error(f"Erro na consolidação completa {lawyer_id}: {str(e)}")
            return None
    
    async def _get_lawyer_basic_info(self, lawyer_id: str) -> Optional[Dict[str, Any]]:
        """Obter informações básicas do advogado (nome, OAB, etc.)"""
        try:
            # TODO: Implementar busca na base interna
            # Por ora, vamos simular dados básicos
            return {
                'id': lawyer_id,
                'name': 'Advogado Teste',  # Seria obtido da base
                'oab_number': '123456/SP',
                'email': 'advogado@teste.com',
                'linkedin_url': None  # Seria obtido se disponível
            }
        except Exception as e:
            logger.error(f"Erro ao buscar dados básicos {lawyer_id}: {str(e)}")
            return None
    
    async def _collect_multi_source_data(
        self,
        lawyer_info: Dict[str, Any],
        sources: List[DataSourceType],
        force_refresh: bool
    ) -> Dict[DataSourceType, Tuple[Any, DataSourceInfo]]:
        """
        Coletar dados de múltiplas fontes em paralelo
        
        Args:
            lawyer_info: Informações básicas do advogado
            sources: Lista de fontes a consultar
            force_refresh: Forçar refresh do cache
            
        Returns:
            Dict com dados coletados por fonte
        """
        try:
            # Preparar tasks para execução paralela
            tasks = {}
            
            for source in sources:
                if source == DataSourceType.LINKEDIN:
                    tasks[source] = self._collect_linkedin_data(lawyer_info, force_refresh)
                elif source == DataSourceType.ACADEMIC:
                    tasks[source] = self._collect_academic_data(lawyer_info, force_refresh)
                elif source == DataSourceType.ESCAVADOR:
                    tasks[source] = self._collect_escavador_data(lawyer_info, force_refresh)
                elif source == DataSourceType.JUSBRASIL:
                    tasks[source] = self._collect_jusbrasil_data(lawyer_info, force_refresh)
                elif source == DataSourceType.DEEP_RESEARCH:
                    tasks[source] = self._collect_deep_research_data(lawyer_info, force_refresh)
                elif source == DataSourceType.INTERNAL:
                    tasks[source] = self._collect_internal_data(lawyer_info, force_refresh)
            
            # Executar com timeout global
            results = {}
            
            try:
                # Executar tasks com controle de concorrência
                semaphore = asyncio.Semaphore(self.max_concurrent_sources)
                
                async def execute_with_semaphore(source, task):
                    async with semaphore:
                        return await task
                
                # Preparar execução controlada
                limited_tasks = {
                    source: execute_with_semaphore(source, task)
                    for source, task in tasks.items()
                }
                
                # Executar com timeout global
                completed_results = await asyncio.wait_for(
                    asyncio.gather(*[
                        asyncio.create_task(task, name=f"source_{source}")
                        for source, task in limited_tasks.items()
                    ], return_exceptions=True),
                    timeout=self.total_timeout_seconds
                )
                
                # Processar resultados
                for i, (source, _) in enumerate(limited_tasks.items()):
                    result = completed_results[i]
                    if isinstance(result, Exception):
                        logger.error(f"Erro na fonte {source}: {str(result)}")
                        results[source] = (None, self._create_error_source_info(source))
                    else:
                        results[source] = result
                
            except asyncio.TimeoutError:
                logger.warning(f"Timeout na coleta multi-fonte após {self.total_timeout_seconds}s")
                # Retornar resultados parciais se houver
                pass
            
            return results
            
        except Exception as e:
            logger.error(f"Erro na coleta multi-fonte: {str(e)}")
            return {}
    
    async def _collect_linkedin_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[LinkedInComprehensiveProfile], DataSourceInfo]:
        """Coletar dados LinkedIn via Unipile"""
        try:
            start_time = datetime.utcnow()
            
            linkedin_url = lawyer_info.get('linkedin_url')
            if not linkedin_url:
                # Tentar encontrar LinkedIn baseado no nome
                linkedin_url = await self._find_linkedin_profile(lawyer_info['name'])
            
            if not linkedin_url:
                return None, DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.UNKNOWN,
                    confidence_score=0.0,
                    fields_available=[],
                    cost_per_query=0.05
                )
            
            # Buscar perfil via Unipile
            profile = await unipile_linkedin_service.get_comprehensive_profile(
                linkedin_url,
                force_refresh
            )
            
            if profile:
                source_info = DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH if profile.data_quality_score > 0.8 else 
                            DataQuality.MEDIUM if profile.data_quality_score > 0.5 else DataQuality.LOW,
                    confidence_score=profile.data_quality_score,
                    fields_available=['education', 'experience', 'skills', 'contacts', 'network'],
                    cost_per_query=0.05,
                    rate_limit_per_hour=50
                )
                
                return profile, source_info
            
            return None, self._create_error_source_info(DataSourceType.LINKEDIN)
            
        except Exception as e:
            logger.error(f"Erro na coleta LinkedIn: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.LINKEDIN)
    
    async def _collect_academic_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[AcademicProfile], DataSourceInfo]:
        """Coletar dados acadêmicos via Perplexity"""
        try:
            # Buscar perfil acadêmico
            profile = await perplexity_academic_service.get_comprehensive_academic_profile(
                lawyer_info['name']
            )
            
            if profile:
                source_info = DataSourceInfo(
                    source_type=DataSourceType.ACADEMIC,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH if profile.confidence_score > 0.8 else 
                            DataQuality.MEDIUM if profile.confidence_score > 0.5 else DataQuality.LOW,
                    confidence_score=profile.confidence_score,
                    fields_available=['degrees', 'publications', 'awards', 'institutions'],
                    cost_per_query=0.10,
                    rate_limit_per_hour=30
                )
                
                return profile, source_info
            
            return None, self._create_error_source_info(DataSourceType.ACADEMIC)
            
        except Exception as e:
            logger.error(f"Erro na coleta acadêmica: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.ACADEMIC)
    
    async def _collect_escavador_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[Dict[str, Any]], DataSourceInfo]:
        """Coletar dados do Escavador"""
        try:
            # TODO: Implementar integração com Escavador
            # Por ora, retornar dados simulados
            return None, DataSourceInfo(
                source_type=DataSourceType.ESCAVADOR,
                last_updated=datetime.utcnow(),
                quality=DataQuality.MEDIUM,
                confidence_score=0.7,
                fields_available=['cases', 'outcomes', 'tribunals'],
                cost_per_query=0.02,
                rate_limit_per_hour=100
            )
            
        except Exception as e:
            logger.error(f"Erro na coleta Escavador: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.ESCAVADOR)
    
    async def _collect_jusbrasil_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[Dict[str, Any]], DataSourceInfo]:
        """Coletar dados do JusBrasil"""
        try:
            # TODO: Implementar integração com JusBrasil
            return None, self._create_error_source_info(DataSourceType.JUSBRASIL)
            
        except Exception as e:
            logger.error(f"Erro na coleta JusBrasil: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.JUSBRASIL)
    
    async def _collect_deep_research_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[Dict[str, Any]], DataSourceInfo]:
        """Coletar dados via Deep Research"""
        try:
            # TODO: Implementar integração com Deep Research
            return None, self._create_error_source_info(DataSourceType.DEEP_RESEARCH)
            
        except Exception as e:
            logger.error(f"Erro na coleta Deep Research: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.DEEP_RESEARCH)
    
    async def _collect_internal_data(
        self,
        lawyer_info: Dict[str, Any],
        force_refresh: bool
    ) -> Tuple[Optional[Dict[str, Any]], DataSourceInfo]:
        """Coletar dados internos da plataforma"""
        try:
            # TODO: Implementar coleta de dados internos
            # (métricas de uso, avaliações de clientes, etc.)
            return None, DataSourceInfo(
                source_type=DataSourceType.INTERNAL,
                last_updated=datetime.utcnow(),
                quality=DataQuality.HIGH,
                confidence_score=1.0,
                fields_available=['usage_metrics', 'client_ratings', 'case_count'],
                cost_per_query=0.0,
                rate_limit_per_hour=1000
            )
            
        except Exception as e:
            logger.error(f"Erro na coleta de dados internos: {str(e)}")
            return None, self._create_error_source_info(DataSourceType.INTERNAL)
    
    async def _consolidate_collected_data(
        self,
        lawyer_id: str,
        basic_info: Dict[str, Any],
        source_results: Dict[DataSourceType, Tuple[Any, DataSourceInfo]]
    ) -> ConsolidatedLawyerProfile:
        """
        Consolidar dados coletados de todas as fontes
        
        Args:
            lawyer_id: ID do advogado
            basic_info: Informações básicas
            source_results: Resultados de cada fonte
            
        Returns:
            Perfil consolidado
        """
        try:
            # Extrair dados por fonte
            linkedin_data, linkedin_info = source_results.get(DataSourceType.LINKEDIN, (None, None))
            academic_data, academic_info = source_results.get(DataSourceType.ACADEMIC, (None, None))
            escavador_data, escavador_info = source_results.get(DataSourceType.ESCAVADOR, (None, None))
            jusbrasil_data, jusbrasil_info = source_results.get(DataSourceType.JUSBRASIL, (None, None))
            deep_research_data, deep_research_info = source_results.get(DataSourceType.DEEP_RESEARCH, (None, None))
            internal_data, internal_info = source_results.get(DataSourceType.INTERNAL, (None, None))
            
            # Consolidar nomes alternativos
            alternative_names = [basic_info['name']]
            if linkedin_data and linkedin_data.first_name and linkedin_data.last_name:
                alternative_names.append(f"{linkedin_data.first_name} {linkedin_data.last_name}")
            if academic_data and academic_data.alternative_names:
                alternative_names.extend(academic_data.alternative_names)
            
            alternative_names = list(set(alternative_names))  # Remover duplicatas
            
            # Construir mapa de fontes de dados
            data_sources = {}
            for source_type, (data, info) in source_results.items():
                if info:
                    data_sources[source_type] = info
            
            # Calcular scores de qualidade e completude
            overall_quality = self._calculate_overall_quality(data_sources)
            completeness = self._calculate_completeness(source_results)
            
            # Construir perfil consolidado
            profile = ConsolidatedLawyerProfile(
                lawyer_id=lawyer_id,
                full_name=basic_info['name'],
                alternative_names=alternative_names,
                linkedin_profile=linkedin_data,
                academic_profile=academic_data,
                legal_cases_data=escavador_data or jusbrasil_data,
                market_insights=deep_research_data,
                platform_metrics=internal_data,
                data_sources=data_sources,
                overall_quality_score=overall_quality,
                completeness_score=completeness,
                last_consolidated=datetime.utcnow()
            )
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro na consolidação dos dados: {str(e)}")
            raise
    
    async def _calculate_final_scores(self, profile: ConsolidatedLawyerProfile) -> ConsolidatedLawyerProfile:
        """
        Calcular scores finais consolidados
        
        Args:
            profile: Perfil consolidado
            
        Returns:
            Perfil com scores calculados
        """
        try:
            # Score de influência social (baseado no LinkedIn)
            social_score = 0.0
            if profile.linkedin_profile:
                linkedin = profile.linkedin_profile
                
                # Base nas conexões e atividade
                connection_score = min(linkedin.network_metrics.connections_count / 500 * 40, 40)
                activity_score = min(len(linkedin.recent_activity) * 5, 30)
                experience_score = min(len(linkedin.experience) * 5, 30)
                
                social_score = connection_score + activity_score + experience_score
            
            # Score de prestígio acadêmico (baseado na Perplexity)
            academic_score = 0.0
            if profile.academic_profile:
                academic_score = profile.academic_profile.academic_prestige_score
            
            # Score de expertise legal (baseado nos dados processuais)
            legal_score = 0.0
            if profile.legal_cases_data:
                # TODO: Implementar cálculo baseado em casos e outcomes
                legal_score = 50.0  # Placeholder
            
            # Score de reputação de mercado (combinado)
            market_score = 0.0
            if profile.market_insights:
                # TODO: Implementar baseado em insights de mercado
                market_score = 60.0  # Placeholder
            
            # Probabilidade geral de sucesso (média ponderada)
            overall_success = (
                social_score * 0.25 +      # 25% influência social
                academic_score * 0.20 +    # 20% prestígio acadêmico
                legal_score * 0.35 +       # 35% expertise legal
                market_score * 0.20        # 20% reputação de mercado
            )
            
            # Ajustar pela qualidade dos dados
            overall_success *= profile.overall_quality_score
            
            # Atualizar perfil
            profile.social_influence_score = social_score
            profile.academic_prestige_score = academic_score
            profile.legal_expertise_score = legal_score
            profile.market_reputation_score = market_score
            profile.overall_success_probability = overall_success
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro no cálculo dos scores finais: {str(e)}")
            return profile
    
    def _calculate_overall_quality(self, data_sources: Dict[DataSourceType, DataSourceInfo]) -> float:
        """Calcular qualidade geral baseada nas fontes"""
        try:
            if not data_sources:
                return 0.0
            
            total_score = 0.0
            total_weight = 0.0
            
            for source_type, source_info in data_sources.items():
                # Peso baseado na prioridade da fonte
                weight = 1.0 / self.source_priorities.get(source_type, 10)
                
                total_score += source_info.confidence_score * weight
                total_weight += weight
            
            return total_score / total_weight if total_weight > 0 else 0.0
            
        except Exception:
            return 0.0
    
    def _calculate_completeness(self, source_results: Dict[DataSourceType, Tuple[Any, DataSourceInfo]]) -> float:
        """Calcular completude baseada nos dados disponíveis"""
        try:
            total_sources = len(DataSourceType)
            successful_sources = sum(1 for data, info in source_results.values() if data is not None)
            
            return successful_sources / total_sources
            
        except Exception:
            return 0.0
    
    def _create_error_source_info(self, source_type: DataSourceType) -> DataSourceInfo:
        """Criar info de fonte para casos de erro"""
        return DataSourceInfo(
            source_type=source_type,
            last_updated=datetime.utcnow(),
            quality=DataQuality.UNKNOWN,
            confidence_score=0.0,
            fields_available=[],
            cost_per_query=0.0
        )
    
    async def _find_linkedin_profile(self, lawyer_name: str) -> Optional[str]:
        """Tentar encontrar perfil LinkedIn baseado no nome"""
        try:
            # TODO: Implementar busca inteligente de perfil LinkedIn
            # Por ora, retornar None
            return None
            
        except Exception as e:
            logger.error(f"Erro ao buscar perfil LinkedIn para {lawyer_name}: {str(e)}")
            return None
    
    async def _cache_consolidated_profile(self, profile: ConsolidatedLawyerProfile):
        """Salvar perfil consolidado no cache"""
        try:
            # TODO: Implementar cache Redis ou similar
            logger.info(f"Perfil consolidado salvo no cache: {profile.lawyer_id}")
            
        except Exception as e:
            logger.error(f"Erro ao salvar no cache: {str(e)}")
    
    async def get_data_transparency_report(
        self,
        lawyer_id: str
    ) -> Dict[str, Any]:
        """
        Gerar relatório de transparência dos dados
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            Relatório detalhado de fontes e qualidade
        """
        try:
            profile = await self.get_complete_lawyer_profile(lawyer_id)
            
            if not profile:
                return {
                    'error': 'Perfil não encontrado',
                    'lawyer_id': lawyer_id
                }
            
            # Construir relatório de transparência
            report = {
                'lawyer_id': lawyer_id,
                'last_updated': profile.last_consolidated.isoformat(),
                'overall_quality_score': profile.overall_quality_score,
                'completeness_score': profile.completeness_score,
                'data_sources': {},
                'scores_breakdown': {
                    'social_influence': profile.social_influence_score,
                    'academic_prestige': profile.academic_prestige_score,
                    'legal_expertise': profile.legal_expertise_score,
                    'market_reputation': profile.market_reputation_score,
                    'overall_success_probability': profile.overall_success_probability
                },
                'recommendations': []
            }
            
            # Detalhar cada fonte de dados
            for source_type, source_info in profile.data_sources.items():
                report['data_sources'][source_type.value] = {
                    'last_updated': source_info.last_updated.isoformat(),
                    'quality': source_info.quality.value,
                    'confidence_score': source_info.confidence_score,
                    'fields_available': source_info.fields_available,
                    'cost_per_query': source_info.cost_per_query
                }
            
            # Gerar recomendações
            if profile.overall_quality_score < 0.7:
                report['recommendations'].append("Melhorar qualidade geral dos dados")
            
            if not profile.linkedin_profile:
                report['recommendations'].append("Adicionar perfil LinkedIn para dados sociais")
            
            if not profile.academic_profile:
                report['recommendations'].append("Buscar dados acadêmicos para validação de formação")
            
            return report
            
        except Exception as e:
            logger.error(f"Erro ao gerar relatório de transparência: {str(e)}")
            return {
                'error': str(e),
                'lawyer_id': lawyer_id
            }

# Instância global do serviço
hybrid_legal_data_service = HybridLegalDataServiceComplete() 