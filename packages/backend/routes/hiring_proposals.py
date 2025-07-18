from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime, timedelta
import logging
import os
from supabase import create_client, Client
from ..auth import get_current_user

# Setup Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://test.supabase.co")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "test-service-key")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

router = APIRouter(prefix="/hiring-proposals", tags=["hiring-proposals"])
logger = logging.getLogger(__name__)

class CreateHiringProposalRequest(BaseModel):
    lawyer_id: str
    case_id: str
    contract_type: str
    budget: float = Field(..., gt=0)
    notes: Optional[str] = None

    @validator('contract_type')
    def validate_contract_type(cls, v):
        if v not in ['hourly', 'fixed', 'success']:
            raise ValueError('contract_type deve ser hourly, fixed ou success')
        return v

class RespondToProposalRequest(BaseModel):
    response_message: Optional[str] = None

class HiringProposalResponse(BaseModel):
    id: str
    client_id: str
    lawyer_id: str
    case_id: str
    contract_type: str
    budget: float
    notes: Optional[str]
    status: str
    created_at: str
    responded_at: Optional[str]
    response_message: Optional[str]
    expires_at: str
    client_name: str
    lawyer_name: str
    case_title: str
    case_description: Optional[str]

@router.post("/", response_model=dict)
async def create_hiring_proposal(
    request: CreateHiringProposalRequest,
    current_user = Depends(get_current_user)
):
    """
    Cria uma nova proposta de contratação de advogado
    """
    try:
        # Verificar se o caso existe e pertence ao cliente
        case_result = supabase.table("cases") \
            .select("id, title, description, client_id") \
            .eq("id", request.case_id) \
            .eq("client_id", current_user["id"]) \
            .execute()
        
        if not case_result.data:
            raise HTTPException(
                status_code=404,
                detail="Caso não encontrado ou você não tem permissão"
            )
        
        case = case_result.data[0]
        
        # Verificar se o advogado existe
        lawyer_result = supabase.table("users") \
            .select("id, name, user_type") \
            .eq("id", request.lawyer_id) \
            .in_("user_type", ["lawyer_individual", "lawyer_office"]) \
            .execute()
        
        if not lawyer_result.data:
            raise HTTPException(
                status_code=404,
                detail="Advogado não encontrado"
            )
        
        lawyer = lawyer_result.data[0]
        
        # Verificar se já existe proposta pendente
        existing_proposal = supabase.table("hiring_proposals") \
            .select("id") \
            .eq("client_id", current_user["id"]) \
            .eq("lawyer_id", request.lawyer_id) \
            .eq("case_id", request.case_id) \
            .eq("status", "pending") \
            .execute()
        
        if existing_proposal.data:
            raise HTTPException(
                status_code=400,
                detail="Já existe uma proposta pendente para este advogado e caso"
            )
        
        # Criar proposta
        proposal_data = {
            "client_id": current_user["id"],
            "lawyer_id": request.lawyer_id,
            "case_id": request.case_id,
            "contract_type": request.contract_type,
            "budget": request.budget,
            "notes": request.notes,
            "status": "pending",
            "expires_at": (datetime.utcnow() + timedelta(days=7)).isoformat()
        }
        
        result = supabase.table("hiring_proposals").insert(proposal_data).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao criar proposta"
            )
        
        proposal = result.data[0]
        
        # TODO: Implementar notificação para o advogado
        # Será implementado após configurar o serviço de notificações
        
        return {
            "success": True,
            "proposal_id": proposal["id"],
            "message": "Proposta enviada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/", response_model=List[HiringProposalResponse])
async def get_hiring_proposals(
    status: Optional[str] = Query(None, regex="^(pending|accepted|rejected|expired)$"),
    current_user = Depends(get_current_user)
):
    """
    Retorna propostas de contratação para o usuário atual
    """
    try:
        # Determinar campo de filtro baseado no tipo de usuário
        if current_user["user_type"] in ["lawyer_individual", "lawyer_office"]:
            user_field = "lawyer_id"
        else:
            user_field = "client_id"
        
        query = supabase.table("hiring_proposals") \
            .select("""
                *,
                clients:client_id(name),
                lawyers:lawyer_id(name),
                cases:case_id(title, description)
            """) \
            .eq(user_field, current_user["id"]) \
            .order("created_at", desc=True)
        
        if status:
            query = query.eq("status", status)
        
        result = query.execute()
        
        proposals = []
        for row in result.data:
            proposal = HiringProposalResponse(
                id=row["id"],
                client_id=row["client_id"],
                lawyer_id=row["lawyer_id"],
                case_id=row["case_id"],
                contract_type=row["contract_type"],
                budget=row["budget"],
                notes=row["notes"] or "",
                status=row["status"],
                created_at=row["created_at"],
                responded_at=row["responded_at"],
                response_message=row["response_message"],
                expires_at=row["expires_at"],
                client_name=row["clients"]["name"],
                lawyer_name=row["lawyers"]["name"],
                case_title=row["cases"]["title"],
                case_description=row["cases"]["description"]
            )
            proposals.append(proposal)
        
        return proposals
        
    except Exception as e:
        logger.error(f"Erro ao buscar propostas: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.patch("/{proposal_id}/accept")
async def accept_proposal(
    proposal_id: str,
    current_user = Depends(get_current_user)
):
    """
    Aceita uma proposta de contratação (apenas advogados)
    """
    try:
        if current_user["user_type"] not in ["lawyer_individual", "lawyer_office"]:
            raise HTTPException(
                status_code=403,
                detail="Apenas advogados podem aceitar propostas"
            )
        
        # Verificar se a proposta existe e pertence ao advogado
        proposal_result = supabase.table("hiring_proposals") \
            .select("*, clients:client_id(name), cases:case_id(title)") \
            .eq("id", proposal_id) \
            .eq("lawyer_id", current_user["id"]) \
            .eq("status", "pending") \
            .execute()
        
        if not proposal_result.data:
            raise HTTPException(
                status_code=404,
                detail="Proposta não encontrada ou já respondida"
            )
        
        proposal = proposal_result.data[0]
        
        # Atualizar status da proposta
        update_result = supabase.table("hiring_proposals") \
            .update({
            "status": "accepted",
            "responded_at": datetime.utcnow().isoformat()
            }) \
            .eq("id", proposal_id) \
            .execute()
        
        if not update_result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao atualizar proposta"
            )
        
        # Criar contrato
        contract_data = {
                "proposal_id": proposal_id,
            "client_id": proposal["client_id"],
            "lawyer_id": proposal["lawyer_id"],
            "case_id": proposal["case_id"],
            "contract_type": proposal["contract_type"],
            "budget": proposal["budget"],
            "status": "active",
            "signed_at": datetime.utcnow().isoformat()
        }
        
        contract_result = supabase.table("contracts").insert(contract_data).execute()
        contract_id = contract_result.data[0]["id"] if contract_result.data else None
        
        # TODO: Notificar cliente sobre aceitação
        
        return {
            "success": True,
            "message": "Proposta aceita com sucesso",
            "contract_id": contract_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao aceitar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.patch("/{proposal_id}/reject")
async def reject_proposal(
    proposal_id: str,
    request: RespondToProposalRequest,
    current_user = Depends(get_current_user)
):
    """
    Rejeita uma proposta de contratação (apenas advogados)
    """
    try:
        if current_user["user_type"] not in ["lawyer_individual", "lawyer_office"]:
            raise HTTPException(
                status_code=403,
                detail="Apenas advogados podem rejeitar propostas"
            )
        
        # Verificar se a proposta existe e pertence ao advogado
        proposal_result = supabase.table("hiring_proposals") \
            .select("*, clients:client_id(name), cases:case_id(title)") \
            .eq("id", proposal_id) \
            .eq("lawyer_id", current_user["id"]) \
            .eq("status", "pending") \
            .execute()
        
        if not proposal_result.data:
            raise HTTPException(
                status_code=404,
                detail="Proposta não encontrada ou já respondida"
            )
        
        proposal = proposal_result.data[0]
        
        # Atualizar status da proposta
        update_result = supabase.table("hiring_proposals") \
            .update({
            "status": "rejected",
            "responded_at": datetime.utcnow().isoformat(),
                "response_message": request.response_message
            }) \
            .eq("id", proposal_id) \
            .execute()
        
        if not update_result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao atualizar proposta"
            )
        
        # TODO: Notificar cliente sobre rejeição
        
        return {
            "success": True,
            "message": "Proposta rejeitada"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao rejeitar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.delete("/{proposal_id}")
async def cancel_proposal(
    proposal_id: str,
    current_user = Depends(get_current_user)
):
    """
    Cancela uma proposta de contratação (apenas clientes)
    """
    try:
        # Verificar se a proposta existe e pertence ao cliente
        proposal_result = supabase.table("hiring_proposals") \
            .select("*") \
            .eq("id", proposal_id) \
            .eq("client_id", current_user["id"]) \
            .eq("status", "pending") \
            .execute()
        
        if not proposal_result.data:
            raise HTTPException(
                status_code=404,
                detail="Proposta não encontrada ou já respondida"
            )
        
        # Marcar como cancelada ao invés de deletar
        update_result = supabase.table("hiring_proposals") \
            .update({
                "status": "cancelled",
                "responded_at": datetime.utcnow().isoformat()
            }) \
            .eq("id", proposal_id) \
            .execute()
    
        if not update_result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao cancelar proposta"
            )
        
        return {
            "success": True,
            "message": "Proposta cancelada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao cancelar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")