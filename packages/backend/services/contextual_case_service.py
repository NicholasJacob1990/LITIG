"""
Serviço para gerenciar alocação contextual de casos
Implementa o sistema de Contextual Case View conforme ARQUITETURA_GERAL_DO_SISTEMA.md
"""

from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from uuid import UUID
import logging

from ..config import get_supabase_client
from ..auth import get_current_user

logger = logging.getLogger(__name__)

class ContextualCaseService:
    """Serviço para gerenciar alocação contextual de casos"""
    
    def __init__(self, supabase_client=None):
        self.supabase = supabase_client or get_supabase_client()
    
    async def get_contextual_case_data(self, case_id: str, user_id: str) -> Dict[str, Any]:
        """
        Busca dados contextuais de um caso específico
        
        Args:
            case_id: ID do caso
            user_id: ID do usuário atual
            
        Returns:
            Dict com dados contextuais completos
        """
        try:
            # Buscar dados básicos do caso
            case_response = self.supabase.table("cases")\
                .select("*")\
                .eq("id", case_id)\
                .single()\
                .execute()
            
            if not case_response.data:
                raise ValueError("Caso não encontrado")
            
            case_data = case_response.data
            
            # Determinar role do usuário em relação ao caso
            user_role = self._determine_user_role(case_data, user_id)
            
            # Buscar dados contextuais específicos
            contextual_data = await self._build_contextual_data(case_data, user_role)
            
            # Gerar KPIs específicos por contexto
            kpis = await self._generate_contextual_kpis(case_data, contextual_data, user_role)
            
            # Gerar ações contextuais
            actions = await self._generate_contextual_actions(case_data, contextual_data, user_role)
            
            # Gerar destaque contextual
            highlight = await self._generate_contextual_highlight(case_data, contextual_data, user_role)
            
            return {
                "case": case_data,
                "contextual_data": contextual_data,
                "kpis": kpis,
                "actions": actions,
                "highlight": highlight,
                "user_role": user_role
            }
            
        except Exception as e:
            logger.error(f"Erro ao buscar dados contextuais do caso {case_id}: {e}")
            raise
    
    def _determine_user_role(self, case_data: Dict[str, Any], user_id: str) -> str:
        """Determina o papel do usuário em relação ao caso"""
        if case_data.get("client_id") == user_id:
            return "client"
        elif case_data.get("lawyer_id") == user_id:
            return "lawyer"
        elif case_data.get("partner_id") == user_id:
            return "partner"
        elif case_data.get("delegated_by") == user_id:
            return "delegator"
        else:
            return "viewer"
    
    async def _build_contextual_data(self, case_data: Dict[str, Any], user_role: str) -> Dict[str, Any]:
        """Constrói dados contextuais específicos por tipo de alocação"""
        allocation_type = case_data.get("allocation_type", "platform_match_direct")
        
        contextual_data = {
            "allocation_type": allocation_type,
            "match_score": case_data.get("match_score"),
            "response_deadline": case_data.get("response_deadline"),
            "partner_id": case_data.get("partner_id"),
            "delegated_by": case_data.get("delegated_by"),
            "context_metadata": case_data.get("context_metadata", {})
        }
        
        # Enriquecer com dados específicos por contexto
        if allocation_type == "platform_match_direct":
            contextual_data.update(await self._enrich_direct_match_data(case_data))
        elif allocation_type == "platform_match_partnership":
            contextual_data.update(await self._enrich_partnership_match_data(case_data))
        elif allocation_type == "partnership_proactive_search":
            contextual_data.update(await self._enrich_proactive_partnership_data(case_data, user_role))
        elif allocation_type == "partnership_platform_suggestion":
            contextual_data.update(await self._enrich_ai_partnership_data(case_data))
        elif allocation_type == "internal_delegation":
            contextual_data.update(await self._enrich_delegation_data(case_data))
        
        return contextual_data
    
    async def _enrich_direct_match_data(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """Enriquece dados para matches diretos"""
        return {
            "response_time_left": self._calculate_response_time_left(case_data.get("response_deadline")),
            "distance": case_data.get("context_metadata", {}).get("distance", 0),
            "estimated_value": case_data.get("context_metadata", {}).get("estimated_value", 0),
            "conversion_rate": case_data.get("context_metadata", {}).get("conversion_rate", 0)
        }
    
    async def _enrich_partnership_match_data(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """Enriquece dados para matches via parceria"""
        partner_id = case_data.get("partner_id")
        if partner_id:
            partner_data = await self._get_user_data(partner_id)
            return {
                "partner_name": partner_data.get("full_name", "N/A"),
                "partner_specialization": partner_data.get("specialization", "N/A"),
                "partner_rating": partner_data.get("rating", 0),
                "your_share": case_data.get("context_metadata", {}).get("your_share", 50),
                "partner_share": case_data.get("context_metadata", {}).get("partner_share", 50)
            }
        return {}
    
    async def _enrich_proactive_partnership_data(self, case_data: Dict[str, Any], user_role: str) -> Dict[str, Any]:
        """Enriquece dados para parcerias proativas"""
        metadata = case_data.get("context_metadata", {})
        
        if user_role == "lawyer" and metadata.get("initiated_by") == case_data.get("lawyer_id"):
            # Usuário iniciou a parceria
            partner_id = case_data.get("partner_id")
            if partner_id:
                partner_data = await self._get_user_data(partner_id)
                return {
                    "partner_name": partner_data.get("full_name", "N/A"),
                    "partner_specialization": partner_data.get("specialization", "N/A"),
                    "partner_rating": partner_data.get("rating", 0),
                    "your_share": metadata.get("your_share", 70),
                    "partner_share": metadata.get("partner_share", 30)
                }
        else:
            # Usuário foi convidado
            initiator_id = metadata.get("initiated_by")
            if initiator_id:
                initiator_data = await self._get_user_data(initiator_id)
                return {
                    "initiator_name": initiator_data.get("full_name", "N/A"),
                    "your_share": metadata.get("your_share", 30),
                    "collaboration_area": metadata.get("collaboration_area", "N/A"),
                    "response_time_left": self._calculate_response_time_left(case_data.get("response_deadline"))
                }
        
        return {}
    
    async def _enrich_ai_partnership_data(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """Enriquece dados para parcerias sugeridas por IA"""
        partner_id = case_data.get("partner_id")
        if partner_id:
            partner_data = await self._get_user_data(partner_id)
            metadata = case_data.get("context_metadata", {})
            return {
                "partner_name": partner_data.get("full_name", "N/A"),
                "partner_specialization": partner_data.get("specialization", "N/A"),
                "match_score": case_data.get("match_score", 0),
                "ai_success_rate": metadata.get("ai_success_rate", 0),
                "ai_reason": metadata.get("ai_reason", "Especialista recomendado")
            }
        return {}
    
    async def _enrich_delegation_data(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """Enriquece dados para delegações internas"""
        delegated_by = case_data.get("delegated_by")
        if delegated_by:
            delegator_data = await self._get_user_data(delegated_by)
            metadata = case_data.get("context_metadata", {})
            return {
                "delegated_by_name": delegator_data.get("full_name", "N/A"),
                "hours_budgeted": metadata.get("hours_budgeted", 0),
                "hourly_rate": metadata.get("hourly_rate", 0),
                "deadline_days": metadata.get("deadline_days", 0)
            }
        return {}
    
    async def _get_user_data(self, user_id: str) -> Dict[str, Any]:
        """Busca dados básicos de um usuário"""
        try:
            response = self.supabase.table("profiles")\
                .select("*")\
                .eq("id", user_id)\
                .single()\
                .execute()
            
            return response.data or {}
        except Exception as e:
            logger.error(f"Erro ao buscar dados do usuário {user_id}: {e}")
            return {}
    
    def _calculate_response_time_left(self, deadline: Optional[str]) -> str:
        """Calcula tempo restante para resposta"""
        if not deadline:
            return "Sem prazo"
        
        try:
            deadline_dt = datetime.fromisoformat(deadline.replace('Z', '+00:00'))
            now = datetime.now(deadline_dt.tzinfo)
            
            if deadline_dt <= now:
                return "Expirado"
            
            time_left = deadline_dt - now
            hours = int(time_left.total_seconds() // 3600)
            minutes = int((time_left.total_seconds() % 3600) // 60)
            
            return f"{hours}h {minutes}min"
        except Exception:
            return "Indefinido"
    
    async def _generate_contextual_kpis(self, case_data: Dict[str, Any], contextual_data: Dict[str, Any], user_role: str) -> List[Dict[str, Any]]:
        """Gera KPIs específicos por contexto"""
        allocation_type = contextual_data.get("allocation_type")
        
        if allocation_type == "platform_match_direct":
            return [
                {"icon": "🎯", "label": "Match Score", "value": f"{contextual_data.get('match_score', 0)}%"},
                {"icon": "📍", "label": "Distância", "value": f"{contextual_data.get('distance', 0)}km"},
                {"icon": "💰", "label": "Valor", "value": f"R$ {contextual_data.get('estimated_value', 0):,.2f}"},
                {"icon": "⏱️", "label": "SLA", "value": contextual_data.get('response_time_left', 'N/A')}
            ]
        elif allocation_type == "internal_delegation":
            return [
                {"icon": "👨‍💼", "label": "Delegado por", "value": contextual_data.get('delegated_by_name', 'N/A')},
                {"icon": "⏰", "label": "Prazo", "value": f"{contextual_data.get('deadline_days', 0)} dias"},
                {"icon": "📈", "label": "Horas Orçadas", "value": f"{contextual_data.get('hours_budgeted', 0)}h"},
                {"icon": "💼", "label": "Valor/h", "value": f"R$ {contextual_data.get('hourly_rate', 0)}"}
            ]
        elif allocation_type == "partnership_proactive_search":
            if user_role == "lawyer":
                return [
                    {"icon": "🤝", "label": "Parceiro", "value": contextual_data.get('partner_name', 'N/A')},
                    {"icon": "📋", "label": "Divisão", "value": f"{contextual_data.get('your_share', 0)}/{contextual_data.get('partner_share', 0)}%"},
                    {"icon": "📊", "label": "Especialização", "value": contextual_data.get('partner_specialization', 'N/A')},
                    {"icon": "⭐", "label": "Rating", "value": f"{contextual_data.get('partner_rating', 0)}"}
                ]
            else:
                return [
                    {"icon": "📧", "label": "Convite de", "value": contextual_data.get('initiator_name', 'N/A')},
                    {"icon": "💰", "label": "Sua parte", "value": f"{contextual_data.get('your_share', 0)}%"},
                    {"icon": "🎯", "label": "Área", "value": contextual_data.get('collaboration_area', 'N/A')},
                    {"icon": "📅", "label": "Prazo", "value": contextual_data.get('response_time_left', 'N/A')}
                ]
        
        # KPIs padrão
        return [
            {"icon": "📊", "label": "Status", "value": case_data.get('status', 'N/A')},
            {"icon": "📅", "label": "Criado em", "value": case_data.get('created_at', 'N/A')[:10]},
            {"icon": "🎯", "label": "Tipo", "value": allocation_type},
            {"icon": "⚖️", "label": "Categoria", "value": case_data.get('category', 'N/A')}
        ]
    
    async def _generate_contextual_actions(self, case_data: Dict[str, Any], contextual_data: Dict[str, Any], user_role: str) -> Dict[str, Any]:
        """Gera ações contextuais específicas"""
        allocation_type = contextual_data.get("allocation_type")
        
        if allocation_type == "platform_match_direct":
            return {
                "primary_action": {"label": "Aceitar Caso", "action": "accept_case"},
                "secondary_actions": [
                    {"label": "Ver Perfil do Cliente", "action": "view_client_profile"},
                    {"label": "Solicitar Informações", "action": "request_info"}
                ]
            }
        elif allocation_type == "internal_delegation":
            return {
                "primary_action": {"label": "Registrar Horas", "action": "log_hours"},
                "secondary_actions": [
                    {"label": "Atualizar Status", "action": "update_status"},
                    {"label": "Reportar Progresso", "action": "report_progress"}
                ]
            }
        elif allocation_type == "partnership_proactive_search":
            if user_role == "lawyer":
                return {
                    "primary_action": {"label": "Alinhar Estratégia", "action": "align_strategy"},
                    "secondary_actions": [
                        {"label": "Ver Contrato", "action": "view_contract"},
                        {"label": "Contatar Parceiro", "action": "contact_partner"}
                    ]
                }
            else:
                return {
                    "primary_action": {"label": "Aceitar Parceria", "action": "accept_partnership"},
                    "secondary_actions": [
                        {"label": "Recusar", "action": "decline_partnership"},
                        {"label": "Negociar Termos", "action": "negotiate_terms"}
                    ]
                }
        
        # Ações padrão
        return {
            "primary_action": {"label": "Ver Detalhes", "action": "view_details"},
            "secondary_actions": [
                {"label": "Adicionar Comentário", "action": "add_comment"}
            ]
        }
    
    async def _generate_contextual_highlight(self, case_data: Dict[str, Any], contextual_data: Dict[str, Any], user_role: str) -> Dict[str, str]:
        """Gera destaque contextual"""
        allocation_type = contextual_data.get("allocation_type")
        
        if allocation_type == "platform_match_direct":
            return {
                "text": "🎯 Match direto para você",
                "color": "blue"
            }
        elif allocation_type == "internal_delegation":
            delegated_by_name = contextual_data.get('delegated_by_name', 'N/A')
            return {
                "text": f"👨‍💼 Delegado por {delegated_by_name}",
                "color": "orange"
            }
        elif allocation_type == "partnership_proactive_search":
            if user_role == "lawyer":
                partner_name = contextual_data.get('partner_name', 'N/A')
                return {
                    "text": f"🤝 Parceria iniciada com {partner_name}",
                    "color": "green"
                }
            else:
                initiator_name = contextual_data.get('initiator_name', 'N/A')
                return {
                    "text": f"📧 Convite de parceria de {initiator_name}",
                    "color": "purple"
                }
        elif allocation_type == "partnership_platform_suggestion":
            partner_name = contextual_data.get('partner_name', 'N/A')
            return {
                "text": f"🤖 Parceria sugerida pela IA com {partner_name}",
                "color": "teal"
            }
        
        return {
            "text": "⚖️ Caso jurídico",
            "color": "gray"
        }
    
    async def set_case_allocation(self, case_id: str, allocation_type: str, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Define o tipo de alocação e metadados de um caso"""
        try:
            update_data = {
                "allocation_type": allocation_type,
                "context_metadata": metadata,
                "updated_at": datetime.now().isoformat()
            }
            
            # Campos específicos por tipo
            if allocation_type == "platform_match_direct":
                update_data.update({
                    "match_score": metadata.get("match_score"),
                    "response_deadline": metadata.get("response_deadline")
                })
            elif allocation_type in ["platform_match_partnership", "partnership_proactive_search"]:
                update_data.update({
                    "partner_id": metadata.get("partner_id"),
                    "partnership_id": metadata.get("partnership_id")
                })
            elif allocation_type == "internal_delegation":
                update_data.update({
                    "delegated_by": metadata.get("delegated_by"),
                    "response_deadline": metadata.get("deadline")
                })
            
            response = self.supabase.table("cases")\
                .update(update_data)\
                .eq("id", case_id)\
                .execute()
            
            return response.data[0] if response.data else {}
            
        except Exception as e:
            logger.error(f"Erro ao definir alocação do caso {case_id}: {e}")
            raise


def create_contextual_case_service(supabase_client=None) -> ContextualCaseService:
    """Factory para criar instância do serviço"""
    return ContextualCaseService(supabase_client) 