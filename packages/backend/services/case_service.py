"""
Case Service - Migração de lógica do banco para Python
Centraliza a lógica de negócio relacionada a casos, anteriormente em funções PostgreSQL
"""
import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from services.cache_service_simple import simple_cache_service
from supabase import Client

logger = logging.getLogger(__name__)


class CaseService:
    """
    Serviço centralizado para operações de casos.
    Migra lógica complexa do PostgreSQL para Python para melhor manutenibilidade.
    """

    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client

    async def get_user_cases(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Substitui a função PostgreSQL get_user_cases.
        Retorna todos os casos de um usuário (cliente ou advogado) com informações enriquecidas.

        Esta implementação em Python é mais fácil de:
        - Testar
        - Debugar
        - Modificar
        - Otimizar com cache
        """
        try:
            # Tentar buscar do cache primeiro
            cache_key = simple_cache_service._generate_key("user_cases", user_id)
            cached_result = await simple_cache_service.get(cache_key)
            if cached_result is not None:
                logger.debug(f"Cache hit para casos do usuário {user_id}")
                return cached_result

            # Se não estiver no cache, buscar do banco
            logger.debug(f"Cache miss para casos do usuário {user_id}")

            # Primeiro, determinar o papel do usuário
            profile = self.supabase.table("profiles").select(
                "role").eq("id", user_id).single().execute()
            user_role = profile.data.get("role") if profile.data else None

            if not user_role:
                logger.warning(f"Usuário {user_id} não tem role definido")
                return []

            # Buscar casos baseado no papel
            if user_role == "client":
                cases_query = self.supabase.table(
                    "cases").select("*").eq("client_id", user_id)
            else:  # lawyer
                cases_query = self.supabase.table(
                    "cases").select("*").eq("lawyer_id", user_id)

            cases_response = cases_query.execute()
            cases = cases_response.data if cases_response.data else []

            # Enriquecer cada caso com informações adicionais
            enriched_cases = []
            for case in cases:
                enriched_case = await self._enrich_case_data(case, user_role)
                enriched_cases.append(enriched_case)

            # Ordenar por data de criação (mais recente primeiro)
            enriched_cases.sort(key=lambda x: x.get("created_at", ""), reverse=True)

            # Armazenar no cache
            await simple_cache_service.set(
                cache_key,
                enriched_cases,
                cache_type='api_response'
            )

            return enriched_cases

        except Exception as e:
            logger.error(f"Erro ao buscar casos do usuário {user_id}: {e}")
            return []

    async def _enrich_case_data(
            self, case: Dict[str, Any], viewer_role: str) -> Dict[str, Any]:
        """
        Enriquece dados de um caso com informações adicionais.
        Substitui JOINs complexos do PostgreSQL.
        """
        enriched = case.copy()

        # Buscar dados do cliente
        if case.get("client_id"):
            client_data = await self._get_profile_data(case["client_id"])
            
            # Determinar tipo de cliente (PF/PJ) baseado nos dados
            from ..schemas.user_types import normalize_entity_type
            from ..services.user_type_migration_service import UserTypeMigrationService
            
            raw_client_type = client_data.get("user_type", "client")
            normalized_client_type = normalize_entity_type(raw_client_type)
            
            # Se for cliente genérico, tentar determinar PF/PJ
            if raw_client_type == "client":
                migration_service = UserTypeMigrationService(None)  # Sem DB para análise simples
                client_type_enum = migration_service._determine_client_type(client_data)
                if client_type_enum.value == "PF":
                    normalized_client_type = "client_pf"
                else:
                    normalized_client_type = "client_pj"
            
            enriched.update({
                "client_name": client_data.get("full_name", ""),
                "client_type": normalized_client_type,  # Tipo normalizado
                "client_type_display": "Pessoa Física" if "pf" in normalized_client_type else "Pessoa Jurídica" if "pj" in normalized_client_type else "Cliente",
                "client_avatar": client_data.get("avatar_url", "")
            })

        # Buscar dados do advogado
        if case.get("lawyer_id"):
            lawyer_data = await self._get_lawyer_data(case["lawyer_id"])
            enriched.update({
                "lawyer_name": lawyer_data.get("full_name", ""),
                "lawyer_specialty": lawyer_data.get("specialization", ""),
                "lawyer_avatar": lawyer_data.get("avatar_url", ""),
                "lawyer_oab": lawyer_data.get("oab_number", ""),
                "lawyer_rating": lawyer_data.get("rating", 0),
                "lawyer_experience_years": lawyer_data.get("experience_years", 0)
            })

        # Contar mensagens não lidas
        unread_count = await self._count_unread_messages(case["id"], viewer_role)
        enriched["unread_messages"] = unread_count

        # Adicionar próximo prazo/deadline
        next_deadline = await self._get_next_deadline(case["id"])
        if next_deadline:
            enriched["next_deadline"] = next_deadline

        # Calcular progresso do caso
        progress = self._calculate_case_progress(case)
        enriched["progress_percentage"] = progress

        return enriched

    async def _get_profile_data(self, profile_id: str) -> Dict[str, Any]:
        """Busca dados de perfil com cache"""
        try:
            response = self.supabase.table("profiles").select(
                "*").eq("id", profile_id).single().execute()
            return response.data if response.data else {}
        except BaseException:
            return {}

    async def _get_lawyer_data(self, lawyer_id: str) -> Dict[str, Any]:
        """Busca dados de advogado com cache"""
        try:
            # Primeiro busca no profiles
            profile_data = await self._get_profile_data(lawyer_id)

            # Depois busca dados específicos de advogado
            lawyer_response = self.supabase.table("lawyers").select(
                "*").eq("id", lawyer_id).single().execute()
            lawyer_specific = lawyer_response.data if lawyer_response.data else {}

            # Combina os dados
            return {**profile_data, **lawyer_specific}
        except BaseException:
            return {}

    async def _count_unread_messages(self, case_id: str, viewer_role: str) -> int:
        """Conta mensagens não lidas para um caso"""
        try:
            # Esta é uma simplificação - em produção, você teria uma tabela de mensagens
            # com campo 'read_at' e faria a contagem baseada no viewer
            return 0  # Placeholder
        except BaseException:
            return 0

    async def _get_next_deadline(self, case_id: str) -> Optional[Dict[str, Any]]:
        """Busca o próximo prazo/deadline do caso"""
        try:
            # Buscar na tabela de tasks
            response = self.supabase.table("tasks")\
                .select("due_date, title")\
                .eq("case_id", case_id)\
                .eq("status", "pending")\
                .gte("due_date", datetime.now(timezone.utc).isoformat())\
                .order("due_date")\
                .limit(1)\
                .execute()

            if response.data and len(response.data) > 0:
                task = response.data[0]
                return {
                    "date": task["due_date"],
                    "description": task["title"]
                }
            return None
        except BaseException:
            return None

    def _calculate_case_progress(self, case: Dict[str, Any]) -> int:
        """
        Calcula o progresso do caso baseado no status e outros fatores.
        Substitui lógica que estava em triggers do PostgreSQL.
        """
        status = case.get("status", "")

        # Mapeamento básico de status para progresso
        progress_map = {
            "triagem": 10,
            "summary_generated": 20,
            "matching": 30,
            "offer_sent": 40,
            "offer_accepted": 50,
            "contract_pending": 60,
            "contract_signed": 70,
            "in_progress": 80,
            "completed": 100,
            "cancelled": 0
        }

        base_progress = progress_map.get(status, 0)

        # Ajustes baseados em outros fatores
        if case.get("lawyer_id"):
            base_progress = max(base_progress, 30)

        if case.get("contract_id"):
            base_progress = max(base_progress, 60)

        if case.get("service_scope_defined_at"):
            base_progress = max(base_progress, 75)

        return min(base_progress, 100)

    async def update_case_status(
            self, case_id: str, new_status: str, user_id: str) -> Dict[str, Any]:
        """
        Atualiza o status de um caso com validações.
        Substitui triggers do PostgreSQL com lógica em Python.
        """
        try:
            # Buscar caso atual
            current_case = self.supabase.table("cases")\
                .select("*")\
                .eq("id", case_id)\
                .single()\
                .execute()

            if not current_case.data:
                raise ValueError(f"Caso {case_id} não encontrado")

            case_data = current_case.data

            # Validar transição de status
            if not self._is_valid_status_transition(case_data["status"], new_status):
                raise ValueError(
                    f"Transição inválida de {
                        case_data['status']} para {new_status}")

            # Atualizar caso
            update_data = {
                "status": new_status,
                "updated_at": datetime.now(timezone.utc).isoformat()
            }

            # Adicionar campos específicos baseado no novo status
            if new_status == "completed":
                update_data["completed_at"] = datetime.now(timezone.utc).isoformat()
            elif new_status == "cancelled":
                update_data["cancelled_at"] = datetime.now(timezone.utc).isoformat()

            # Executar update
            updated = self.supabase.table("cases")\
                .update(update_data)\
                .eq("id", case_id)\
                .execute()

            # Invalidar cache
            await simple_cache_service.delete_pattern(f"user_cases:*")
            await simple_cache_service.delete_pattern(f"case_matches:{case_id}*")

            # Registrar evento (substitui trigger)
            await self._create_case_event(case_id, "status_changed", {
                "old_status": case_data["status"],
                "new_status": new_status,
                "changed_by": user_id
            })

            return updated.data[0] if updated.data else {}

        except Exception as e:
            logger.error(f"Erro ao atualizar status do caso {case_id}: {e}")
            raise

    def _is_valid_status_transition(self, current_status: str, new_status: str) -> bool:
        """
        Valida se uma transição de status é permitida.
        Substitui constraints do PostgreSQL.
        """
        valid_transitions = {
            "triagem": ["summary_generated", "cancelled"],
            "summary_generated": ["matching", "cancelled"],
            "matching": ["offer_sent", "cancelled"],
            "offer_sent": ["offer_accepted", "offer_rejected", "cancelled"],
            "offer_accepted": ["contract_pending", "cancelled"],
            "contract_pending": ["contract_signed", "cancelled"],
            "contract_signed": ["in_progress", "cancelled"],
            "in_progress": ["completed", "cancelled"],
            "completed": [],  # Estado final
            "cancelled": []   # Estado final
        }

        allowed = valid_transitions.get(current_status, [])
        return new_status in allowed

    async def _create_case_event(
            self, case_id: str, event_type: str, data: Dict[str, Any]):
        """Cria um evento de caso (substitui trigger do PostgreSQL)"""
        try:
            event_data = {
                "case_id": case_id,
                "event_type": event_type,
                "data": json.dumps(data),
                "created_at": datetime.now(timezone.utc).isoformat()
            }

            self.supabase.table("case_events").insert(event_data).execute()
        except Exception as e:
            logger.error(f"Erro ao criar evento de caso: {e}")

    async def get_case_statistics(self, user_id: str) -> Dict[str, Any]:
        """
        Retorna estatísticas agregadas dos casos de um usuário.
        Substitui views materializadas do PostgreSQL.
        """
        cases = await self.get_user_cases(user_id)

        # Calcular estatísticas
        total = len(cases)
        by_status = {}
        by_area = {}
        total_value = 0

        for case in cases:
            # Por status
            status = case.get("status", "unknown")
            by_status[status] = by_status.get(status, 0) + 1

            # Por área
            area = case.get("area", "unknown")
            by_area[area] = by_area.get(area, 0) + 1

            # Valor total
            if case.get("estimated_cost"):
                total_value += case["estimated_cost"]

        # Calcular taxa de sucesso
        completed = by_status.get("completed", 0)
        cancelled = by_status.get("cancelled", 0)
        success_rate = (completed / (completed + cancelled) *
                        100) if (completed + cancelled) > 0 else 0

        return {
            "total_cases": total,
            "active_cases": total - by_status.get("completed", 0) - by_status.get("cancelled", 0),
            "completed_cases": completed,
            "cancelled_cases": cancelled,
            "success_rate": round(success_rate, 2),
            "by_status": by_status,
            "by_area": by_area,
            "total_value": total_value,
            "average_value": total_value / total if total > 0 else 0
        }


# Factory function para criar instância do serviço
def create_case_service(supabase_client: Client) -> CaseService:
    """Cria uma instância do CaseService"""
    return CaseService(supabase_client)
