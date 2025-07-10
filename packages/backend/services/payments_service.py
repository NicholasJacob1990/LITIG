"""
backend/services/payments_service.py

Serviço para gerenciar a lógica de negócio relacionada a pagamentos,
faturas e transações.
"""
import os
import logging
from typing import Dict, Any, List
from uuid import UUID
from supabase import create_client, Client

# Configuração do Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

logger = logging.getLogger(__name__)

class PaymentsService:
    """
    Classe de serviço para operações financeiras.
    """

    async def create_invoice(self, user_id: UUID, case_id: UUID, amount_cents: int, description: str) -> Dict[str, Any]:
        """
        Cria uma nova fatura para um usuário e caso específico.
        """
        try:
            invoice_data = {
                "user_id": str(user_id),
                "case_id": str(case_id),
                "amount_cents": amount_cents,
                "description": description,
                "status": "pending"
            }
            response = supabase.table("invoices").insert(invoice_data).execute()
            
            if response.data:
                logger.info(f"Fatura {response.data[0]['id']} criada para o usuário {user_id}.")
                return response.data[0]
            else:
                raise Exception("Falha ao criar a fatura no banco de dados.")

        except Exception as e:
            logger.error(f"Erro ao criar fatura para usuário {user_id}: {e}")
            raise

    async def get_invoices_by_user(self, user_id: UUID) -> List[Dict[str, Any]]:
        """
        Busca todas as faturas de um usuário.
        """
        try:
            response = supabase.table("invoices").select("*").eq("user_id", str(user_id)).order("created_at", desc=True).execute()
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar faturas do usuário {user_id}: {e}")
            raise

payments_service = PaymentsService() 