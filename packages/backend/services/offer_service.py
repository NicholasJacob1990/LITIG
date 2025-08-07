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

from models import Offer, OfferCreate, OfferStatusUpdate, OffersListResponse
from algoritmo_match import Case, Lawyer

# Configuração
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

logger = logging.getLogger(__name__)

def get_supabase_client() -> Client:
    """Retorna cliente Supabase configurado"""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        raise ValueError("SUPABASE_URL e SUPABASE_SERVICE_KEY devem estar configurados")
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

async def create_offer_from_match(case_id: str, lawyer_id: str, choice_order: int, offer_details: Dict[str, Any]) -> str:
    """
    Cria uma oferta após o cliente escolher um advogado.
    
    Args:
        case_id: ID do caso
        lawyer_id: ID do advogado escolhido
        choice_order: Ordem de escolha do cliente (1 = primeira escolha)
        offer_details: Detalhes da oferta (resumo do caso, área jurídica, etc.)
        
    Returns:
        ID da oferta criada
    """
    try:
        supabase = get_supabase_client()
        
        # Calcular expiração (48h para aceitar)
        expires_at = datetime.now() + timedelta(hours=48)
        
        # Preparar dados da oferta
        offer_data = {
            "case_id": case_id,
            "lawyer_id": lawyer_id,
            "status": "pending",
            "sent_at": datetime.now().isoformat(),
            "expires_at": expires_at.isoformat(),
            "client_choice_order": choice_order,
            "offer_details": offer_details,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        
        # Inserir oferta no banco
        response = supabase.table("offers").insert(offer_data).execute()
        
        if response.data:
            offer_id = response.data[0]["id"]
            logger.info(f"Oferta criada com sucesso: {offer_id} para caso {case_id}")
            
            # Enviar notificação para o advogado sobre nova oferta
            try:
                from services.notify_service import send_notifications_to_lawyers
                
                notification_payload = {
                    "title": "📋 Nova Oferta de Caso",
                    "body": f"Você recebeu uma nova oferta na área de {offer_details.get('legal_area', 'Direito')}",
                    "data": {
                        "type": "new_offer",
                        "offer_id": offer_id,
                        "case_id": case_id,
                        "action": "view_offer"
                    }
                }
                
                await send_notifications_to_lawyers([lawyer_id], notification_payload)
                logger.info(f"Notificação de nova oferta enviada para advogado {lawyer_id}")
                
            except Exception as e:
                logger.error(f"Erro ao enviar notificação de nova oferta: {e}")
            
            return offer_id
        else:
            raise Exception("Erro ao criar oferta no banco de dados")
            
    except Exception as e:
        logger.error(f"Erro ao criar oferta para caso {case_id}: {e}")
        raise

async def get_pending_offers(lawyer_id: str) -> List[Offer]:
    """
    Busca ofertas pendentes para um advogado.
    
    Args:
        lawyer_id: ID do advogado
        
    Returns:
        Lista de ofertas pendentes
    """
    try:
        supabase = get_supabase_client()
        
        # Buscar ofertas pendentes não expiradas
        response = supabase.table("offers").select("*").eq("lawyer_id", lawyer_id).eq("status", "pending").gt("expires_at", datetime.now().isoformat()).order("created_at", desc=True).execute()
        
        if response.data:
            offers = [Offer(**offer_data) for offer_data in response.data]
            return offers
        else:
            return []
            
    except Exception as e:
        logger.error(f"Erro ao buscar ofertas pendentes do advogado {lawyer_id}: {e}")
        raise

async def accept_offer(offer_id: UUID, lawyer_id: str, notes: Optional[str] = None) -> Dict[str, Any]:
    """
    Aceita uma oferta de caso usando a stored procedure do banco.
    
    Args:
        offer_id: ID da oferta
        lawyer_id: ID do advogado
        notes: Notas opcionais
        
    Returns:
        Resultado da aceitação
    """
    try:
        supabase = get_supabase_client()
        
        # Chamar stored procedure para aceitar oferta
        response = supabase.rpc("accept_offer", {
            "p_offer_id": str(offer_id),
            "p_lawyer_id": lawyer_id,
            "p_notes": notes
        }).execute()
        
        if response.data and len(response.data) > 0:
            result = response.data[0]
            
            if result["success"]:
                logger.info(f"Oferta {offer_id} aceita com sucesso pelo advogado {lawyer_id}")
                
                # TODO: Ativar o caso
                # await CaseService.activate_case(result["case_id"], lawyer_id)
                
                # Notificar cliente sobre aceitação do caso
                try:
                    # Buscar dados do caso e cliente
                    case_response = supabase.table("cases").select("client_id, case_number, title").eq("id", result["case_id"]).single().execute()
                    
                    if case_response.data:
                        client_id = case_response.data["client_id"]
                        case_title = case_response.data.get("title", "Seu caso")
                        
                        # Buscar nome do advogado
                        lawyer_response = supabase.table("lawyers").select("name").eq("id", lawyer_id).single().execute()
                        lawyer_name = lawyer_response.data.get("name", "Advogado") if lawyer_response.data else "Advogado"
                        
                        notification_payload = {
                            "title": "🎉 Caso Aceito!",
                            "body": f"O advogado {lawyer_name} aceitou seu caso '{case_title}'. O contrato será enviado em breve.",
                            "data": {
                                "type": "offer_accepted",
                                "case_id": result["case_id"],
                                "lawyer_id": lawyer_id,
                                "action": "view_case"
                            }
                        }
                        
                        from services.notify_service import send_notification_to_client
                        await send_notification_to_client(client_id, "offer_accepted", notification_payload)
                        logger.info(f"Notificação de aceitação enviada para cliente {client_id}")
                        
                except Exception as e:
                    logger.error(f"Erro ao enviar notificação de aceitação para cliente: {e}")
                
                return {
                    "success": True,
                    "message": result["message"],
                    "case_id": result["case_id"],
                    "offer_id": str(offer_id)
                }
            else:
                raise ValueError(result["message"])
        else:
            raise Exception("Erro na resposta da stored procedure")
            
    except Exception as e:
        logger.error(f"Erro ao aceitar oferta {offer_id}: {e}")
        raise

async def reject_offer(offer_id: UUID, lawyer_id: str, reason: str) -> Dict[str, Any]:
    """
    Rejeita uma oferta de caso usando a stored procedure do banco.
    
    Args:
        offer_id: ID da oferta
        lawyer_id: ID do advogado
        reason: Motivo da rejeição
        
    Returns:
        Resultado da rejeição
    """
    try:
        supabase = get_supabase_client()
        
        # Chamar stored procedure para rejeitar oferta
        response = supabase.rpc("reject_offer", {
            "p_offer_id": str(offer_id),
            "p_lawyer_id": lawyer_id,
            "p_reason": reason
        }).execute()
        
        if response.data and len(response.data) > 0:
            result = response.data[0]
            
            if result["success"]:
                logger.info(f"Oferta {offer_id} rejeitada pelo advogado {lawyer_id}: {reason}")
                
                # TODO: Reativar matching para o próximo advogado
                # await MatchService.reactivate_matching_for_case(result["case_id"], [lawyer_id])
                
                return {
                    "success": True,
                    "message": result["message"],
                    "case_id": result["case_id"],
                    "offer_id": str(offer_id)
                }
            else:
                raise ValueError(result["message"])
        else:
            raise Exception("Erro na resposta da stored procedure")
            
    except Exception as e:
        logger.error(f"Erro ao rejeitar oferta {offer_id}: {e}")
        raise

async def get_lawyer_offer_statistics(lawyer_id: str) -> Dict[str, Any]:
    """
    Busca estatísticas de ofertas de um advogado.
    
    Args:
        lawyer_id: ID do advogado
        
    Returns:
        Estatísticas das ofertas
    """
    try:
        supabase = get_supabase_client()
        
        # Buscar todas as ofertas do advogado
        response = supabase.table("offers").select("*").eq("lawyer_id", lawyer_id).execute()
        
        if not response.data:
            return {
                "total_offers": 0,
                "accepted": 0,
                "rejected": 0,
                "expired": 0,
                "pending": 0,
                "acceptance_rate": 0.0,
                "avg_response_time_hours": 0.0
            }
        
        offers = response.data
        total = len(offers)
        accepted = len([o for o in offers if o["status"] == "accepted"])
        rejected = len([o for o in offers if o["status"] in ["rejected", "declined"]])
        expired = len([o for o in offers if o["status"] == "expired"])
        pending = len([o for o in offers if o["status"] == "pending"])
        
        # Calcular taxa de aceitação
        acceptance_rate = accepted / total if total > 0 else 0.0
        
        # Calcular tempo médio de resposta
        response_times = []
        for offer in offers:
            if offer.get("responded_at") and offer.get("sent_at"):
                try:
                    sent = datetime.fromisoformat(offer["sent_at"].replace('Z', '+00:00'))
                    responded = datetime.fromisoformat(offer["responded_at"].replace('Z', '+00:00'))
                    response_time = (responded - sent).total_seconds() / 3600  # em horas
                    response_times.append(response_time)
                except ValueError:
                    continue
        
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0.0
        
        return {
            "total_offers": total,
            "accepted": accepted,
            "rejected": rejected,
            "expired": expired,
            "pending": pending,
            "acceptance_rate": acceptance_rate,
            "avg_response_time_hours": avg_response_time
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas do advogado {lawyer_id}: {e}")
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