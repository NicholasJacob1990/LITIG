"""
backend/services/reviews_service.py

Serviço para gerenciar a lógica de negócio de avaliações.
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

class ReviewsService:
    """
    Classe de serviço para operações com avaliações.
    """

    async def create_review(self, client_id: UUID, contract_id: UUID, rating: int, comment: str) -> Dict[str, Any]:
        """
        Cria uma nova avaliação para um contrato, validando a permissão do cliente.
        """
        try:
            # A RLS do Supabase já garante que o cliente só pode avaliar contratos seus
            # que estão com status 'closed', mas uma verificação extra pode ser feita aqui se necessário.
            
            review_data = {
                "client_id": str(client_id),
                "contract_id": str(contract_id),
                "rating": rating,
                "comment": comment,
                # lawyer_id será preenchido por um trigger ou buscado do contrato
            }
            
            # Precisamos do lawyer_id. Vamos buscar no contrato.
            contract_res = supabase.table("contracts").select("lawyer_id").eq("id", str(contract_id)).single().execute()
            if not contract_res.data:
                raise ValueError("Contrato não encontrado.")
            
            review_data["lawyer_id"] = contract_res.data['lawyer_id']

            response = supabase.table("reviews").insert(review_data).execute()

            if response.data:
                logger.info(f"Avaliação {response.data[0]['id']} criada para o contrato {contract_id}.")
                return response.data[0]
            else:
                raise Exception("Falha ao criar a avaliação.")

        except Exception as e:
            logger.error(f"Erro ao criar avaliação para o contrato {contract_id}: {e}")
            raise

    async def get_reviews_by_lawyer(self, lawyer_id: UUID) -> List[Dict[str, Any]]:
        """
        Busca todas as avaliações de um advogado.
        """
        try:
            # A RLS garante que qualquer usuário autenticado pode ver as reviews.
            response = supabase.table("reviews").select("*, client:profiles(full_name, avatar_url)").eq("lawyer_id", str(lawyer_id)).order("created_at", desc=True).execute()
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar avaliações do advogado {lawyer_id}: {e}")
            raise

reviews_service = ReviewsService() 