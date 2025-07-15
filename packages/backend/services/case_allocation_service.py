"""
Serviço para gerenciar alocação automática de casos
Implementa a lógica para registrar automaticamente o allocation_type baseado na origem do caso
"""

from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from uuid import uuid4
import logging

from ..config import get_supabase_client
from ..services.contextual_case_service import create_contextual_case_service

logger = logging.getLogger(__name__)

class CaseAllocationService:
    """Serviço para gerenciar alocação automática de casos"""
    
    def __init__(self, supabase_client=None):
        self.supabase = supabase_client or get_supabase_client()
        self.contextual_service = create_contextual_case_service(supabase_client)
    
    async def allocate_case_from_algorithm_match(
        self, 
        case_id: str, 
        lawyer_id: str, 
        match_score: float,
        distance_km: float = 0,
        estimated_value: float = 0
    ) -> Dict[str, Any]:
        """
        Aloca caso proveniente de match direto do algoritmo
        
        Args:
            case_id: ID do caso
            lawyer_id: ID do advogado matched
            match_score: Score do match (0-100)
            distance_km: Distância em km
            estimated_value: Valor estimado do caso
            
        Returns:
            Dict com dados da alocação
        """
        try:
            # Verificar se o advogado é Super Associado
            lawyer_profile = await self._get_lawyer_profile(lawyer_id)
            
            if lawyer_profile.get('user_role') == 'lawyer_platform_associate':
                allocation_type = 'platform_match_direct'
                response_deadline = datetime.now() + timedelta(hours=1)  # 1h SLA para Super Associado
            else:
                allocation_type = 'platform_match_direct'
                response_deadline = datetime.now() + timedelta(hours=2)  # 2h SLA para outros
            
            metadata = {
                'match_score': match_score,
                'distance': distance_km,
                'estimated_value': estimated_value,
                'conversion_rate': await self._calculate_conversion_rate(lawyer_id),
                'complexity_score': await self._calculate_complexity_score(case_id),
                'origin': 'algorithm_match',
                'sla_hours': 1 if lawyer_profile.get('user_role') == 'lawyer_platform_associate' else 2
            }
            
            # Definir alocação no caso
            result = await self.contextual_service.set_case_allocation(
                case_id=case_id,
                allocation_type=allocation_type,
                metadata=metadata
            )
            
            # Atualizar caso com advogado
            await self._update_case_lawyer(case_id, lawyer_id, response_deadline)
            
            logger.info(f"Caso {case_id} alocado via algorithm match para advogado {lawyer_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Erro ao alocar caso {case_id} via algorithm match: {e}")
            raise
    
    async def allocate_case_from_partnership(
        self,
        case_id: str,
        partnership_id: str,
        partner_id: str,
        initiated_by: str,
        partnership_type: str = 'proactive_search'
    ) -> Dict[str, Any]:
        """
        Aloca caso proveniente de parceria
        
        Args:
            case_id: ID do caso
            partnership_id: ID da parceria
            partner_id: ID do parceiro
            initiated_by: ID de quem iniciou a parceria
            partnership_type: Tipo da parceria (proactive_search, platform_suggestion)
            
        Returns:
            Dict com dados da alocação
        """
        try:
            if partnership_type == 'proactive_search':
                allocation_type = 'partnership_proactive_search'
            elif partnership_type == 'platform_suggestion':
                allocation_type = 'partnership_platform_suggestion'
            else:
                allocation_type = 'partnership_proactive_search'
            
            # Buscar dados da parceria
            partnership_data = await self._get_partnership_data(partnership_id)
            
            metadata = {
                'partnership_id': partnership_id,
                'initiated_by': initiated_by,
                'partnership_type': partnership_type,
                'your_share': partnership_data.get('initiator_share', 70),
                'partner_share': partnership_data.get('partner_share', 30),
                'collaboration_area': partnership_data.get('collaboration_area', 'Geral'),
                'origin': 'partnership'
            }
            
            if partnership_type == 'platform_suggestion':
                metadata.update({
                    'ai_success_rate': partnership_data.get('ai_success_rate', 85),
                    'ai_reason': partnership_data.get('ai_reason', 'Especialista recomendado'),
                    'match_score': partnership_data.get('match_score', 0)
                })
            
            # Definir alocação no caso
            result = await self.contextual_service.set_case_allocation(
                case_id=case_id,
                allocation_type=allocation_type,
                metadata=metadata
            )
            
            # Atualizar caso com parceiro
            await self._update_case_partnership(case_id, partner_id, partnership_id)
            
            logger.info(f"Caso {case_id} alocado via parceria {partnership_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Erro ao alocar caso {case_id} via parceria: {e}")
            raise
    
    async def allocate_case_from_delegation(
        self,
        case_id: str,
        delegated_by: str,
        assigned_to: str,
        hours_budgeted: int = 0,
        hourly_rate: float = 0,
        deadline_days: int = 30
    ) -> Dict[str, Any]:
        """
        Aloca caso proveniente de delegação interna
        
        Args:
            case_id: ID do caso
            delegated_by: ID de quem delegou
            assigned_to: ID do advogado atribuído
            hours_budgeted: Horas orçadas
            hourly_rate: Valor por hora
            deadline_days: Prazo em dias
            
        Returns:
            Dict com dados da alocação
        """
        try:
            allocation_type = 'internal_delegation'
            deadline = datetime.now() + timedelta(days=deadline_days)
            
            metadata = {
                'delegated_by': delegated_by,
                'hours_budgeted': hours_budgeted,
                'hourly_rate': hourly_rate,
                'deadline_days': deadline_days,
                'origin': 'internal_delegation'
            }
            
            # Definir alocação no caso
            result = await self.contextual_service.set_case_allocation(
                case_id=case_id,
                allocation_type=allocation_type,
                metadata=metadata
            )
            
            # Atualizar caso com delegação
            await self._update_case_delegation(case_id, assigned_to, delegated_by, deadline)
            
            logger.info(f"Caso {case_id} delegado por {delegated_by} para {assigned_to}")
            
            return result
            
        except Exception as e:
            logger.error(f"Erro ao alocar caso {case_id} via delegação: {e}")
            raise
    
    async def allocate_case_from_algorithm_partnership(
        self,
        case_id: str,
        partnership_id: str,
        primary_lawyer_id: str,
        partner_id: str,
        match_score: float
    ) -> Dict[str, Any]:
        """
        Aloca caso proveniente de match algorítmico que resulta em parceria
        
        Args:
            case_id: ID do caso
            partnership_id: ID da parceria
            primary_lawyer_id: ID do advogado principal
            partner_id: ID do parceiro
            match_score: Score do match
            
        Returns:
            Dict com dados da alocação
        """
        try:
            allocation_type = 'platform_match_partnership'
            
            metadata = {
                'partnership_id': partnership_id,
                'match_score': match_score,
                'primary_lawyer_id': primary_lawyer_id,
                'your_share': 60,  # Padrão para matches algorítmicos
                'partner_share': 40,
                'origin': 'algorithm_partnership'
            }
            
            # Definir alocação no caso
            result = await self.contextual_service.set_case_allocation(
                case_id=case_id,
                allocation_type=allocation_type,
                metadata=metadata
            )
            
            # Atualizar caso com parceria algorítmica
            await self._update_case_algorithm_partnership(case_id, primary_lawyer_id, partner_id, partnership_id)
            
            logger.info(f"Caso {case_id} alocado via parceria algorítmica {partnership_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Erro ao alocar caso {case_id} via parceria algorítmica: {e}")
            raise
    
    async def _get_lawyer_profile(self, lawyer_id: str) -> Dict[str, Any]:
        """Busca dados do perfil do advogado"""
        try:
            response = self.supabase.table("profiles")\
                .select("*")\
                .eq("id", lawyer_id)\
                .single()\
                .execute()
            
            return response.data or {}
        except Exception as e:
            logger.error(f"Erro ao buscar perfil do advogado {lawyer_id}: {e}")
            return {}
    
    async def _get_partnership_data(self, partnership_id: str) -> Dict[str, Any]:
        """Busca dados da parceria"""
        try:
            response = self.supabase.table("partnerships")\
                .select("*")\
                .eq("id", partnership_id)\
                .single()\
                .execute()
            
            return response.data or {}
        except Exception as e:
            logger.error(f"Erro ao buscar dados da parceria {partnership_id}: {e}")
            return {}
    
    async def _calculate_conversion_rate(self, lawyer_id: str) -> float:
        """Calcula taxa de conversão do advogado"""
        try:
            # Buscar estatísticas do advogado
            response = self.supabase.table("lawyer_stats")\
                .select("conversion_rate")\
                .eq("lawyer_id", lawyer_id)\
                .single()\
                .execute()
            
            if response.data:
                return response.data.get("conversion_rate", 0)
            
            return 85.0  # Padrão
        except Exception:
            return 85.0  # Padrão em caso de erro
    
    async def _calculate_complexity_score(self, case_id: str) -> int:
        """Calcula score de complexidade do caso"""
        try:
            # Buscar dados do caso
            response = self.supabase.table("cases")\
                .select("ai_analysis")\
                .eq("id", case_id)\
                .single()\
                .execute()
            
            if response.data and response.data.get("ai_analysis"):
                ai_analysis = response.data["ai_analysis"]
                return ai_analysis.get("complexity_score", 5)
            
            return 5  # Padrão (média)
        except Exception:
            return 5  # Padrão em caso de erro
    
    async def _update_case_lawyer(self, case_id: str, lawyer_id: str, response_deadline: datetime):
        """Atualiza caso com advogado atribuído"""
        try:
            self.supabase.table("cases")\
                .update({
                    "lawyer_id": lawyer_id,
                    "response_deadline": response_deadline.isoformat(),
                    "status": "assigned",
                    "updated_at": datetime.now().isoformat()
                })\
                .eq("id", case_id)\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao atualizar caso {case_id} com advogado {lawyer_id}: {e}")
            raise
    
    async def _update_case_partnership(self, case_id: str, partner_id: str, partnership_id: str):
        """Atualiza caso com parceria"""
        try:
            self.supabase.table("cases")\
                .update({
                    "partner_id": partner_id,
                    "partnership_id": partnership_id,
                    "status": "assigned",
                    "updated_at": datetime.now().isoformat()
                })\
                .eq("id", case_id)\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao atualizar caso {case_id} com parceria {partnership_id}: {e}")
            raise
    
    async def _update_case_delegation(self, case_id: str, assigned_to: str, delegated_by: str, deadline: datetime):
        """Atualiza caso com delegação"""
        try:
            self.supabase.table("cases")\
                .update({
                    "lawyer_id": assigned_to,
                    "delegated_by": delegated_by,
                    "response_deadline": deadline.isoformat(),
                    "status": "assigned",
                    "updated_at": datetime.now().isoformat()
                })\
                .eq("id", case_id)\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao atualizar caso {case_id} com delegação: {e}")
            raise
    
    async def _update_case_algorithm_partnership(self, case_id: str, primary_lawyer_id: str, partner_id: str, partnership_id: str):
        """Atualiza caso com parceria algorítmica"""
        try:
            self.supabase.table("cases")\
                .update({
                    "lawyer_id": primary_lawyer_id,
                    "partner_id": partner_id,
                    "partnership_id": partnership_id,
                    "status": "assigned",
                    "updated_at": datetime.now().isoformat()
                })\
                .eq("id", case_id)\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao atualizar caso {case_id} com parceria algorítmica: {e}")
            raise


def create_case_allocation_service(supabase_client=None) -> CaseAllocationService:
    """Factory para criar instância do serviço"""
    return CaseAllocationService(supabase_client) 