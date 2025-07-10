"""
backend/services/availability_service.py

Serviço para gerenciar a disponibilidade dos advogados.
"""
import os
import logging
from typing import Dict, Any
from uuid import UUID
from supabase import create_client, Client

# Configuração
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

logger = logging.getLogger(__name__)

class AvailabilityService:
    """
    Classe de serviço para operações de disponibilidade.
    """

    async def update_lawyer_availability(self, lawyer_id: UUID, is_available: bool, reason: str = None) -> Dict[str, Any]:
        """
        Atualiza o status de disponibilidade de um advogado.
        """
        try:
            update_data = {
                "is_available": is_available,
                "availability_reason": reason,
                "updated_at": "now()"
            }
            
            response = supabase.table("lawyers").update(update_data).eq("id", str(lawyer_id)).execute()

            if response.data:
                logger.info(f"Disponibilidade do advogado {lawyer_id} atualizada para {is_available}.")
                return response.data[0]
            else:
                raise Exception("Advogado não encontrado ou falha ao atualizar.")

        except Exception as e:
            logger.error(f"Erro ao atualizar disponibilidade do advogado {lawyer_id}: {e}")
            raise

availability_service = AvailabilityService() 