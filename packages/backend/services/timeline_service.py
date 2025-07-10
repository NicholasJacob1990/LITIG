"""
backend/services/timeline_service.py

Serviço para gerenciar a lógica de negócio da timeline de eventos de um caso.
"""
import os
import logging
from typing import Dict, Any, List
from uuid import UUID
from supabase import create_client, Client

# Configuração
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

logger = logging.getLogger(__name__)

class TimelineService:
    """
    Classe de serviço para operações com a timeline de eventos.
    """

    async def get_case_timeline(self, case_id: UUID, user_id: UUID) -> List[Dict[str, Any]]:
        """
        Busca a timeline de eventos de um caso específico.
        A RLS já garante que o usuário tem acesso ao caso.
        """
        try:
            response = (
                supabase.table("case_events")
                .select("*, author:profiles!created_by_id(full_name, avatar_url)")
                .eq("case_id", str(case_id))
                .order("created_at", desc=True)
                .execute()
            )
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar timeline do caso {case_id}: {e}")
            raise
    
    async def add_case_event(self, case_id: UUID, user_id: UUID, event_type: str, description: str, metadata: Dict = None) -> Dict[str, Any]:
        """
        Adiciona um novo evento à timeline de um caso.
        """
        try:
            event_data = {
                "case_id": str(case_id),
                "created_by_id": str(user_id),
                "event_type": event_type,
                "description": description,
                "metadata": metadata
            }
            response = supabase.table("case_events").insert(event_data).execute()

            if response.data:
                logger.info(f"Novo evento '{event_type}' adicionado ao caso {case_id} pelo usuário {user_id}.")
                return response.data[0]
            else:
                raise Exception("Falha ao adicionar evento na timeline.")

        except Exception as e:
            logger.error(f"Erro ao adicionar evento ao caso {case_id}: {e}")
            raise

timeline_service = TimelineService() 