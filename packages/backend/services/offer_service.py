"""
backend/services/offer_service.py

Serviço para gerenciar ofertas de casos para advogados.
"""
import os
import logging
from typing import Dict, Any, List, Optional
from uuid import UUID
from datetime import datetime, timedelta
from supabase import create_client, Client

from backend.models import Offer, OfferCreate, OfferStatusUpdate, OffersListResponse
from backend.algoritmo_match import Case, Lawyer

# Configuração
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

logger = logging.getLogger(__name__)

def get_supabase_client() -> Client:
    """Retorna cliente Supabase configurado"""
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

async def create_offers_from_ranking(case: Case, ranking: List[Lawyer]) -> List[str]:
    """
    Cria ofertas para advogados baseado no ranking do algoritmo de matching.
    
    Args:
        case: Caso para o qual as ofertas serão criadas
        ranking: Lista de advogados ranqueados
        
    Returns:
        Lista de IDs das ofertas criadas
    """
    if not ranking:
        return []
    
    try:
        supabase = get_supabase_client()
        
        # Preparar dados das ofertas
        offers_data = []
        for lawyer in ranking:
            offer_data = {
                "case_id": str(case.id),
                "lawyer_id": str(lawyer.id),
                "status": "pending",
                "sent_at": datetime.now().isoformat(),
                "expires_at": (datetime.now() + timedelta(hours=24)).isoformat(),
                "fair_score": lawyer.scores.get('fair', 0.0) if lawyer.scores else 0.0,
                "raw_score": lawyer.scores.get('raw', 0.0) if lawyer.scores else 0.0,
                "equity_weight": lawyer.scores.get('equity', 0.0) if lawyer.scores else 0.0,
                "last_offered_at": datetime.now().isoformat()
            }
            offers_data.append(offer_data)
        
        # Criar ofertas no banco
        response = supabase.table("offers").upsert(offers_data).execute()
        
        if response.data:
            offer_ids = [offer["id"] for offer in response.data]
            logger.info(f"Criadas {len(offer_ids)} ofertas para o caso {case.id}")
            return offer_ids
        else:
            logger.warning(f"Nenhuma oferta criada para o caso {case.id}")
            return []
            
    except Exception as e:
        logger.error(f"Erro ao criar ofertas para o caso {case.id}: {e}")
        raise

async def get_lawyer_offers(lawyer_id: str, status: Optional[str] = None) -> List[Offer]:
    """
    Busca ofertas de um advogado específico.
    
    Args:
        lawyer_id: ID do advogado
        status: Status das ofertas para filtrar (opcional)
        
    Returns:
        Lista de ofertas do advogado
    """
    try:
        supabase = get_supabase_client()
        
        query = supabase.table("offers").select("*").eq("lawyer_id", lawyer_id)
        
        if status:
            query = query.eq("status", status)
            
        response = query.order("created_at", desc=True).execute()
        
        if response.data:
            offers = [Offer(**offer_data) for offer_data in response.data]
            return offers
        else:
            return []
            
    except Exception as e:
        logger.error(f"Erro ao buscar ofertas do advogado {lawyer_id}: {e}")
        raise

async def update_offer_status(offer_id: UUID, status_update: OfferStatusUpdate, lawyer_id: str) -> Optional[Offer]:
    """
    Atualiza o status de uma oferta.
    
    Args:
        offer_id: ID da oferta
        status_update: Dados de atualização do status
        lawyer_id: ID do advogado (para validação)
        
    Returns:
        Oferta atualizada ou None se não encontrada
    """
    try:
        supabase = get_supabase_client()
        
        # Verificar se a oferta existe e pertence ao advogado
        existing_offer = supabase.table("offers").select("*").eq("id", str(offer_id)).eq("lawyer_id", lawyer_id).single().execute()
        
        if not existing_offer.data:
            logger.warning(f"Oferta {offer_id} não encontrada ou não pertence ao advogado {lawyer_id}")
            return None
        
        # Atualizar status
        update_data = {
            "status": status_update.status,
            "responded_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        
        if status_update.message:
            update_data["message"] = status_update.message
        
        response = supabase.table("offers").update(update_data).eq("id", str(offer_id)).execute()
        
        if response.data:
            updated_offer = Offer(**response.data[0])
            logger.info(f"Oferta {offer_id} atualizada para status {status_update.status}")
            
            # Se foi aceita, fechar outras ofertas do mesmo caso
            if status_update.status == "interested":
                case_id = existing_offer.data["case_id"]
                await close_other_offers(case_id, str(offer_id))
            
            return updated_offer
        else:
            return None
            
    except Exception as e:
        logger.error(f"Erro ao atualizar oferta {offer_id}: {e}")
        raise

async def get_offers_by_case(case_id: str, client_id: str) -> OffersListResponse:
    """
    Busca ofertas de um caso específico para o cliente.
    
    Args:
        case_id: ID do caso
        client_id: ID do cliente (para validação)
        
    Returns:
        Lista de ofertas do caso
    """
    try:
        supabase = get_supabase_client()
        
        # Verificar se o caso pertence ao cliente
        case_response = supabase.table("cases").select("client_id").eq("id", case_id).single().execute()
        
        if not case_response.data or case_response.data["client_id"] != client_id:
            raise ValueError("Caso não encontrado ou não pertence ao cliente")
        
        # Buscar ofertas do caso
        response = supabase.table("offers").select("*").eq("case_id", case_id).order("created_at", desc=True).execute()
        
        offers = []
        interested_count = 0
        
        if response.data:
            for offer_data in response.data:
                offer = Offer(**offer_data)
                offers.append(offer)
                if offer.status == "interested":
                    interested_count += 1
        
        return OffersListResponse(
            case_id=UUID(case_id),
            offers=offers,
            total=len(offers),
            interested_count=interested_count
        )
        
    except Exception as e:
        logger.error(f"Erro ao buscar ofertas do caso {case_id}: {e}")
        raise

async def close_other_offers(case_id: str, accepted_offer_id: str) -> int:
    """
    Fecha outras ofertas quando uma é aceita.
    
    Args:
        case_id: ID do caso
        accepted_offer_id: ID da oferta aceita
        
    Returns:
        Número de ofertas fechadas
    """
    try:
        supabase = get_supabase_client()
        
        # Fechar outras ofertas pendentes do mesmo caso
        response = supabase.table("offers").update({
            "status": "closed",
            "updated_at": datetime.now().isoformat()
        }).eq("case_id", case_id).neq("id", accepted_offer_id).in_("status", ["pending", "interested"]).execute()
        
        closed_count = len(response.data) if response.data else 0
        logger.info(f"Fechadas {closed_count} ofertas para o caso {case_id}")
        
        return closed_count
        
    except Exception as e:
        logger.error(f"Erro ao fechar ofertas do caso {case_id}: {e}")
        raise

async def expire_pending_offers() -> int:
    """
    Expira ofertas pendentes que passaram do prazo.
    
    Returns:
        Número de ofertas expiradas
    """
    try:
        supabase = get_supabase_client()
        
        # Usar RPC para expirar ofertas
        response = supabase.rpc("expire_pending_offers").execute()
        
        expired_count = response.data if response.data else 0
        logger.info(f"Expiradas {expired_count} ofertas pendentes")
        
        return expired_count
        
    except Exception as e:
        logger.error(f"Erro ao expirar ofertas pendentes: {e}")
        raise

async def get_offer_stats(case_id: str) -> Dict[str, Any]:
    """
    Retorna estatísticas das ofertas de um caso.
    
    Args:
        case_id: ID do caso
        
    Returns:
        Estatísticas das ofertas
    """
    try:
        supabase = get_supabase_client()
        
        response = supabase.table("offers").select("status").eq("case_id", case_id).execute()
        
        stats = {
            "total": 0,
            "pending": 0,
            "interested": 0,
            "declined": 0,
            "expired": 0,
            "closed": 0
        }
        
        if response.data:
            stats["total"] = len(response.data)
            for offer in response.data:
                status = offer.get("status", "pending")
                if status in stats:
                    stats[status] += 1
        
        return stats
        
    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas do caso {case_id}: {e}")
        raise 