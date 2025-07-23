"""
Serviço de Integração: Busca e Contextualização
Conecta o sistema de busca com o sistema de contextualização para registrar allocation_type
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import logging
import json

from services.contextual_case_service import ContextualCaseService
from services.case_allocation_service import CaseAllocationService
from services.contextual_metrics_service import ContextualMetricsService
from services.feature_flag_service import FeatureFlagService
from models.case import Case
from models.user import User
from models.lawyer import Lawyer
from database import get_db_connection
from utils.cache import cache_result

logger = logging.getLogger(__name__)

class SearchMatchType(Enum):
    """Tipos de match de busca"""
    SEMANTIC_MATCH = "semantic_match"
    DIRECTORY_MATCH = "directory_match"
    HYBRID_MATCH = "hybrid_match"
    PRESET_MATCH = "preset_match"
    AI_RECOMMENDATION = "ai_recommendation"
    PROXIMITY_MATCH = "proximity_match"

class SearchOrigin(Enum):
    """Origem da busca"""
    CLIENT_SEARCH = "client_search"
    LAWYER_SEARCH = "lawyer_search"
    FIRM_SEARCH = "firm_search"
    PLATFORM_SUGGESTION = "platform_suggestion"
    PARTNERSHIP_SEARCH = "partnership_search"
    PROACTIVE_SEARCH = "proactive_search"

@dataclass
class SearchMatchResult:
    """Resultado de match da busca"""
    match_id: str
    lawyer_id: str
    client_id: str
    match_type: SearchMatchType
    search_origin: SearchOrigin
    match_score: float
    search_query: str
    search_filters: Dict[str, Any]
    search_context: Dict[str, Any]
    preset_used: Optional[str]
    coordinates: Optional[Dict[str, float]]
    proximity_radius: Optional[float]
    partnership_id: Optional[str]
    firm_id: Optional[str]
    created_at: datetime

@dataclass
class SearchContextualMapping:
    """Mapeamento entre busca e allocation_type"""
    search_origin: SearchOrigin
    match_type: SearchMatchType
    allocation_type: str
    requires_partnership: bool
    requires_firm_context: bool
    sla_hours: int
    priority_level: int

class SearchContextualIntegrationService:
    """Serviço de integração entre busca e contextualização"""
    
    def __init__(self):
        self.db = get_db_connection()
        self.contextual_service = ContextualCaseService()
        self.allocation_service = CaseAllocationService()
        self.metrics_service = ContextualMetricsService()
        self.feature_flag_service = FeatureFlagService()
        
        # Mapeamentos entre busca e allocation_type
        self.search_mappings = {
            # Busca direta do cliente
            (SearchOrigin.CLIENT_SEARCH, SearchMatchType.SEMANTIC_MATCH): 
                SearchContextualMapping(
                    search_origin=SearchOrigin.CLIENT_SEARCH,
                    match_type=SearchMatchType.SEMANTIC_MATCH,
                    allocation_type="platform_match_direct",
                    requires_partnership=False,
                    requires_firm_context=False,
                    sla_hours=24,  # Corrigido para 24 horas
                    priority_level=1
                ),
            
            # Busca do advogado por parceria
            (SearchOrigin.LAWYER_SEARCH, SearchMatchType.DIRECTORY_MATCH):
                SearchContextualMapping(
                    search_origin=SearchOrigin.LAWYER_SEARCH,
                    match_type=SearchMatchType.DIRECTORY_MATCH,
                    allocation_type="partnership_proactive_search",
                    requires_partnership=True,
                    requires_firm_context=False,
                    sla_hours=72,
                    priority_level=2
                ),
            
            # Sugestão da plataforma
            (SearchOrigin.PLATFORM_SUGGESTION, SearchMatchType.AI_RECOMMENDATION):
                SearchContextualMapping(
                    search_origin=SearchOrigin.PLATFORM_SUGGESTION,
                    match_type=SearchMatchType.AI_RECOMMENDATION,
                    allocation_type="partnership_platform_suggestion",
                    requires_partnership=True,
                    requires_firm_context=False,
                    sla_hours=48,
                    priority_level=3
                ),
            
            # Busca com parceria
            (SearchOrigin.PARTNERSHIP_SEARCH, SearchMatchType.HYBRID_MATCH):
                SearchContextualMapping(
                    search_origin=SearchOrigin.PARTNERSHIP_SEARCH,
                    match_type=SearchMatchType.HYBRID_MATCH,
                    allocation_type="platform_match_partnership",
                    requires_partnership=True,
                    requires_firm_context=False,
                    sla_hours=48,
                    priority_level=2
                ),
            
            # Busca proativa
            (SearchOrigin.PROACTIVE_SEARCH, SearchMatchType.PRESET_MATCH):
                SearchContextualMapping(
                    search_origin=SearchOrigin.PROACTIVE_SEARCH,
                    match_type=SearchMatchType.PRESET_MATCH,
                    allocation_type="partnership_proactive_search",
                    requires_partnership=True,
                    requires_firm_context=False,
                    sla_hours=72,
                    priority_level=3
                ),
            
            # Busca do escritório
            (SearchOrigin.FIRM_SEARCH, SearchMatchType.DIRECTORY_MATCH):
                SearchContextualMapping(
                    search_origin=SearchOrigin.FIRM_SEARCH,
                    match_type=SearchMatchType.DIRECTORY_MATCH,
                    allocation_type="internal_delegation",
                    requires_partnership=False,
                    requires_firm_context=True,
                    sla_hours=48,  # SLA customizável - padrão 48h, mas pode ser sobrescrito
                    priority_level=2
                ),
        }
    
    async def process_search_match(
        self,
        search_result: SearchMatchResult,
        user: User,
        case_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Processa um match de busca e registra contexto de alocação"""
        try:
            # Verifica se contextualização está habilitada
            contextual_enabled = await self.feature_flag_service.is_feature_enabled(
                'contextual_case_view', user
            )
            
            if not contextual_enabled:
                return await self._process_legacy_match(search_result, user, case_id)
            
            # Determina allocation_type baseado na busca
            mapping = self._get_allocation_mapping(search_result)
            
            if not mapping:
                logger.warning(f"No mapping found for search: {search_result.search_origin}, {search_result.match_type}")
                return await self._process_legacy_match(search_result, user, case_id)
            
            # Cria ou atualiza caso com contexto
            if case_id:
                case = await self._get_case(case_id)
                if not case:
                    raise ValueError(f"Case {case_id} not found")
                
                # Atualiza caso existente com allocation_type
                await self._update_case_allocation(case, mapping, search_result)
            else:
                # Cria novo caso com contexto
                case = await self._create_contextual_case(mapping, search_result, user)
            
            # Registra métricas de busca
            await self._record_search_metrics(search_result, mapping, user)
            
            # Enriquece dados contextuais
            contextual_data = await self.contextual_service.get_contextual_case_data(
                case.id, user.id
            )
            
            # Registra evento de alocação
            await self.metrics_service.record_allocation_event(
                case_id=case.id,
                allocation_type=mapping.allocation_type,
                match_score=search_result.match_score,
                sla_hours=mapping.sla_hours,
                user_id=user.id,
                metadata={
                    'search_origin': search_result.search_origin.value,
                    'match_type': search_result.match_type.value,
                    'search_query': search_result.search_query,
                    'preset_used': search_result.preset_used,
                    'coordinates': search_result.coordinates,
                    'proximity_radius': search_result.proximity_radius
                }
            )
            
            return {
                'case_id': case.id,
                'allocation_type': mapping.allocation_type,
                'match_score': search_result.match_score,
                'sla_hours': mapping.sla_hours,
                'priority_level': mapping.priority_level,
                'contextual_data': contextual_data,
                'search_context': {
                    'origin': search_result.search_origin.value,
                    'type': search_result.match_type.value,
                    'query': search_result.search_query,
                    'filters': search_result.search_filters,
                    'preset': search_result.preset_used
                }
            }
            
        except Exception as e:
            logger.error(f"Error processing search match: {e}")
            # Fallback para processamento legacy
            return await self._process_legacy_match(search_result, user, case_id)
    
    async def process_bulk_search_matches(
        self,
        search_results: List[SearchMatchResult],
        user: User
    ) -> List[Dict[str, Any]]:
        """Processa múltiplos matches de busca em lote"""
        try:
            processed_results = []
            
            for search_result in search_results:
                try:
                    result = await self.process_search_match(search_result, user)
                    processed_results.append(result)
                except Exception as e:
                    logger.error(f"Error processing search match {search_result.match_id}: {e}")
                    # Continua processando outros matches
                    continue
            
            return processed_results
            
        except Exception as e:
            logger.error(f"Error processing bulk search matches: {e}")
            return []
    
    async def get_search_allocation_analytics(
        self,
        start_date: datetime,
        end_date: datetime,
        search_origin: Optional[SearchOrigin] = None,
        match_type: Optional[SearchMatchType] = None
    ) -> Dict[str, Any]:
        """Obtém analytics de alocação por busca"""
        try:
            query = """
            SELECT 
                data->>'search_origin' as search_origin,
                data->>'match_type' as match_type,
                data->>'allocation_type' as allocation_type,
                COUNT(*) as total_matches,
                AVG(CAST(data->>'match_score' AS FLOAT)) as avg_match_score,
                AVG(CAST(data->>'sla_hours' AS INT)) as avg_sla_hours,
                COUNT(DISTINCT entity_id) as unique_cases,
                COUNT(DISTINCT user_id) as unique_users
            FROM metric_events
            WHERE category = 'allocation_performance'
            AND timestamp BETWEEN %s AND %s
            AND data->>'search_origin' IS NOT NULL
            """
            
            params = [start_date, end_date]
            
            if search_origin:
                query += " AND data->>'search_origin' = %s"
                params.append(search_origin.value)
            
            if match_type:
                query += " AND data->>'match_type' = %s"
                params.append(match_type.value)
            
            query += " GROUP BY search_origin, match_type, allocation_type ORDER BY total_matches DESC"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                analytics = {
                    'period': {
                        'start': start_date.isoformat(),
                        'end': end_date.isoformat()
                    },
                    'total_matches': sum(row[3] for row in rows),
                    'breakdown': [],
                    'summary': {
                        'by_search_origin': {},
                        'by_match_type': {},
                        'by_allocation_type': {}
                    }
                }
                
                for row in rows:
                    breakdown_item = {
                        'search_origin': row[0],
                        'match_type': row[1],
                        'allocation_type': row[2],
                        'total_matches': row[3],
                        'avg_match_score': round(row[4], 2) if row[4] else 0,
                        'avg_sla_hours': row[5] if row[5] else 0,
                        'unique_cases': row[6],
                        'unique_users': row[7]
                    }
                    analytics['breakdown'].append(breakdown_item)
                    
                    # Agrupa por origem
                    origin = row[0]
                    if origin not in analytics['summary']['by_search_origin']:
                        analytics['summary']['by_search_origin'][origin] = {
                            'total_matches': 0,
                            'avg_match_score': 0,
                            'unique_cases': 0
                        }
                    analytics['summary']['by_search_origin'][origin]['total_matches'] += row[3]
                    analytics['summary']['by_search_origin'][origin]['unique_cases'] += row[6]
                    
                    # Agrupa por tipo de match
                    match_type_str = row[1]
                    if match_type_str not in analytics['summary']['by_match_type']:
                        analytics['summary']['by_match_type'][match_type_str] = {
                            'total_matches': 0,
                            'avg_match_score': 0,
                            'unique_cases': 0
                        }
                    analytics['summary']['by_match_type'][match_type_str]['total_matches'] += row[3]
                    analytics['summary']['by_match_type'][match_type_str]['unique_cases'] += row[6]
                    
                    # Agrupa por tipo de alocação
                    allocation_type = row[2]
                    if allocation_type not in analytics['summary']['by_allocation_type']:
                        analytics['summary']['by_allocation_type'][allocation_type] = {
                            'total_matches': 0,
                            'avg_match_score': 0,
                            'unique_cases': 0
                        }
                    analytics['summary']['by_allocation_type'][allocation_type]['total_matches'] += row[3]
                    analytics['summary']['by_allocation_type'][allocation_type]['unique_cases'] += row[6]
                
                return analytics
                
        except Exception as e:
            logger.error(f"Error getting search allocation analytics: {e}")
            return {}
    
    async def update_search_preset_allocation(
        self,
        preset_name: str,
        allocation_type: str,
        sla_hours: int,
        priority_level: int
    ) -> bool:
        """Atualiza configuração de alocação para preset de busca"""
        try:
            query = """
            INSERT INTO search_preset_allocations (preset_name, allocation_type, sla_hours, priority_level, updated_at)
            VALUES (%s, %s, %s, %s, NOW())
            ON DUPLICATE KEY UPDATE
                allocation_type = VALUES(allocation_type),
                sla_hours = VALUES(sla_hours),
                priority_level = VALUES(priority_level),
                updated_at = NOW()
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (preset_name, allocation_type, sla_hours, priority_level))
                self.db.commit()
                
                logger.info(f"Updated preset allocation: {preset_name} -> {allocation_type}")
                return True
                
        except Exception as e:
            logger.error(f"Error updating preset allocation: {e}")
            self.db.rollback()
            return False
    
    def _get_allocation_mapping(self, search_result: SearchMatchResult) -> Optional[SearchContextualMapping]:
        """Obtém mapeamento de alocação baseado na busca"""
        key = (search_result.search_origin, search_result.match_type)
        
        # Verifica mapeamento específico
        if key in self.search_mappings:
            return self.search_mappings[key]
        
        # Fallback para mapeamentos genéricos
        if search_result.search_origin == SearchOrigin.CLIENT_SEARCH:
            return SearchContextualMapping(
                search_origin=search_result.search_origin,
                match_type=search_result.match_type,
                allocation_type="platform_match_direct",
                requires_partnership=False,
                requires_firm_context=False,
                sla_hours=24,  # Corrigido para 24 horas
                priority_level=1
            )
        
        if search_result.search_origin in [SearchOrigin.LAWYER_SEARCH, SearchOrigin.PARTNERSHIP_SEARCH]:
            return SearchContextualMapping(
                search_origin=search_result.search_origin,
                match_type=search_result.match_type,
                allocation_type="partnership_proactive_search",
                requires_partnership=True,
                requires_firm_context=False,
                sla_hours=72,
                priority_level=2
            )
        
        if search_result.search_origin == SearchOrigin.FIRM_SEARCH:
            return SearchContextualMapping(
                search_origin=search_result.search_origin,
                match_type=search_result.match_type,
                allocation_type="internal_delegation",
                requires_partnership=False,
                requires_firm_context=True,
                sla_hours=48,
                priority_level=2
            )
        
        return None
    
    async def _get_case(self, case_id: str) -> Optional[Case]:
        """Obtém caso pelo ID"""
        try:
            query = "SELECT * FROM cases WHERE id = %s"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (case_id,))
                row = cursor.fetchone()
                
                if row:
                    return Case.from_db_row(row)
                
                return None
                
        except Exception as e:
            logger.error(f"Error getting case: {e}")
            return None
    
    async def _update_case_allocation(
        self,
        case: Case,
        mapping: SearchContextualMapping,
        search_result: SearchMatchResult
    ) -> None:
        """Atualiza alocação de caso existente"""
        try:
            context_metadata = {
                'search_origin': search_result.search_origin.value,
                'match_type': search_result.match_type.value,
                'search_query': search_result.search_query,
                'match_score': search_result.match_score,
                'preset_used': search_result.preset_used,
                'coordinates': search_result.coordinates,
                'proximity_radius': search_result.proximity_radius
            }
            
            query = """
            UPDATE cases 
            SET 
                allocation_type = %s,
                match_score = %s,
                response_deadline = %s,
                context_metadata = %s,
                partner_id = %s,
                updated_at = NOW()
            WHERE id = %s
            """
            
            response_deadline = datetime.utcnow() + timedelta(hours=mapping.sla_hours)
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (
                    mapping.allocation_type,
                    search_result.match_score,
                    response_deadline,
                    json.dumps(context_metadata),
                    search_result.partnership_id,
                    case.id
                ))
                self.db.commit()
                
        except Exception as e:
            logger.error(f"Error updating case allocation: {e}")
            self.db.rollback()
            raise
    
    async def _create_contextual_case(
        self,
        mapping: SearchContextualMapping,
        search_result: SearchMatchResult,
        user: User
    ) -> Case:
        """Cria novo caso com contexto de alocação"""
        try:
            # Usa o serviço de alocação para criar caso
            if mapping.allocation_type == "platform_match_direct":
                case = await self.allocation_service.allocate_case_from_algorithm_match(
                    client_id=search_result.client_id,
                    lawyer_id=search_result.lawyer_id,
                    match_score=search_result.match_score,
                    search_query=search_result.search_query,
                    search_filters=search_result.search_filters
                )
            elif mapping.allocation_type == "platform_match_partnership":
                case = await self.allocation_service.allocate_case_from_partnership_match(
                    client_id=search_result.client_id,
                    lawyer_id=search_result.lawyer_id,
                    partnership_id=search_result.partnership_id,
                    match_score=search_result.match_score,
                    partnership_terms={'revenue_split': 0.3}
                )
            elif mapping.allocation_type == "partnership_proactive_search":
                case = await self.allocation_service.allocate_case_from_proactive_search(
                    lawyer_id=search_result.lawyer_id,
                    client_id=search_result.client_id,
                    search_criteria=search_result.search_filters,
                    match_score=search_result.match_score
                )
            else:
                # Fallback para criação genérica
                case = await self._create_generic_case(mapping, search_result, user)
            
            return case
            
        except Exception as e:
            logger.error(f"Error creating contextual case: {e}")
            raise
    
    async def _create_generic_case(
        self,
        mapping: SearchContextualMapping,
        search_result: SearchMatchResult,
        user: User
    ) -> Case:
        """Cria caso genérico quando não há método específico"""
        try:
            context_metadata = {
                'search_origin': search_result.search_origin.value,
                'match_type': search_result.match_type.value,
                'search_query': search_result.search_query,
                'match_score': search_result.match_score,
                'preset_used': search_result.preset_used,
                'coordinates': search_result.coordinates,
                'proximity_radius': search_result.proximity_radius
            }
            
            response_deadline = datetime.utcnow() + timedelta(hours=mapping.sla_hours)
            
            query = """
            INSERT INTO cases (
                client_id, lawyer_id, allocation_type, match_score, 
                response_deadline, context_metadata, partner_id, 
                created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (
                    search_result.client_id,
                    search_result.lawyer_id,
                    mapping.allocation_type,
                    search_result.match_score,
                    response_deadline,
                    json.dumps(context_metadata),
                    search_result.partnership_id
                ))
                
                case_id = cursor.lastrowid
                self.db.commit()
                
                # Busca o caso criado
                return await self._get_case(str(case_id))
                
        except Exception as e:
            logger.error(f"Error creating generic case: {e}")
            self.db.rollback()
            raise
    
    async def _record_search_metrics(
        self,
        search_result: SearchMatchResult,
        mapping: SearchContextualMapping,
        user: User
    ) -> None:
        """Registra métricas de busca"""
        try:
            # Registra engajamento de busca
            await self.metrics_service.record_engagement_event(
                user_id=user.id,
                user_role=user.role,
                interaction_type='search_match',
                case_id=None,
                duration=None,
                metadata={
                    'search_origin': search_result.search_origin.value,
                    'match_type': search_result.match_type.value,
                    'search_query': search_result.search_query,
                    'match_score': search_result.match_score,
                    'preset_used': search_result.preset_used
                }
            )
            
        except Exception as e:
            logger.error(f"Error recording search metrics: {e}")
    
    async def _process_legacy_match(
        self,
        search_result: SearchMatchResult,
        user: User,
        case_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Processa match usando lógica legacy quando contextualização não está disponível"""
        try:
            # Lógica legacy simplificada
            return {
                'case_id': case_id or 'legacy_case_id',
                'allocation_type': 'platform_match_direct',
                'match_score': search_result.match_score,
                'sla_hours': 24,
                'priority_level': 1,
                'contextual_data': None,
                'search_context': {
                    'origin': search_result.search_origin.value,
                    'type': search_result.match_type.value,
                    'query': search_result.search_query,
                    'legacy_mode': True
                }
            }
            
        except Exception as e:
            logger.error(f"Error processing legacy match: {e}")
            return {} 