#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/routes/partnerships.py

Rotas da API para o sistema de parcerias jurídicas.
Implementa CRUD completo para propostas de parceria entre advogados.
"""

from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from supabase import Client
import uuid

from api.schemas import (
    PartnershipCreateSchema,
    PartnershipResponseSchema,
    PartnershipListResponseSchema,
    PartnershipStatsSchema,
    ContractGenerationSchema,
    ContractResponseSchema,
    PartnerSearchSchema,
    MatchedLawyerSchema,
    ErrorResponseSchema
)
from services.partnership_service import PartnershipService
from services.contract_service import ContractService
from services.match_service import MatchService
from services.partnership_recommendation_service import PartnershipRecommendationService

router = APIRouter(prefix="/partnerships", tags=["Parcerias"])
security = HTTPBearer()

def get_current_user_id(token: str = Depends(security)) -> str:
    """Extrai o user_id do token JWT (implementação simplificada)"""
    # TODO: Implementar validação JWT completa
    # Por enquanto, retorna um ID mock para testes
    return "user_123"


@router.post("/", response_model=PartnershipResponseSchema)
async def create_partnership(
    partnership_data: PartnershipCreateSchema,
    current_user: str = Depends(get_current_user_id)
):
    """
    Cria uma nova proposta de parceria jurídica.
    
    O usuário atual será o 'creator' da parceria.
    """
    try:
        partnership_service = PartnershipService()
        partnership = await partnership_service.create_partnership(
            creator_id=current_user,
            partner_id=partnership_data.partner_id,
            case_id=partnership_data.case_id,
            partnership_type=partnership_data.type.value,
            honorarios=partnership_data.honorarios,
            proposal_message=partnership_data.proposal_message
        )
        
        return partnership
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro interno do servidor: {str(e)}"
        )


@router.get("/", response_model=List[PartnershipResponseSchema])
async def list_partnerships(
    status_filter: Optional[str] = None,
    type_filter: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: str = Depends(get_current_user_id)
):
    """
    Lista todas as parcerias do usuário (enviadas e recebidas).
    """
    try:
        partnership_service = PartnershipService()
        partnerships = await partnership_service.get_user_partnerships(
            user_id=current_user,
            status_filter=status_filter,
            type_filter=type_filter,
            limit=limit,
            offset=offset
        )
        
        return partnerships
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar parcerias: {str(e)}"
        )


@router.get("/separated", response_model=PartnershipListResponseSchema)
async def list_partnerships_separated(
    current_user: str = Depends(get_current_user_id)
):
    """
    Lista parcerias separadas em 'enviadas' e 'recebidas'.
    Útil para interfaces com abas separadas.
    """
    try:
        partnership_service = PartnershipService()
        
        sent = await partnership_service.get_sent_partnerships(current_user)
        received = await partnership_service.get_received_partnerships(current_user)
        
        return PartnershipListResponseSchema(sent=sent, received=received)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar parcerias: {str(e)}"
        )


@router.get("/statistics", response_model=PartnershipStatsSchema)
async def get_partnership_statistics(
    current_user: str = Depends(get_current_user_id)
):
    """
    Retorna estatísticas de parcerias do usuário.
    """
    try:
        partnership_service = PartnershipService()
        stats = await partnership_service.get_user_statistics(current_user)
        
        return stats
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular estatísticas: {str(e)}"
        )


@router.get("/history/{lawyer_id}", response_model=List[PartnershipResponseSchema])
async def get_partnership_history(
    lawyer_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Retorna histórico de parcerias entre o usuário atual e um advogado específico.
    Útil para avaliar colaborações anteriores.
    """
    try:
        partnership_service = PartnershipService()
        history = await partnership_service.get_partnership_history(
            user1_id=current_user,
            user2_id=lawyer_id
        )
        
        return history
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar histórico: {str(e)}"
        )


@router.patch("/{partnership_id}/accept", response_model=PartnershipResponseSchema)
async def accept_partnership(
    partnership_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Aceita uma proposta de parceria.
    Apenas o 'partner' (destinatário) pode aceitar.
    """
    try:
        partnership_service = PartnershipService()
        partnership = await partnership_service.accept_partnership(
            partnership_id=partnership_id,
            partner_id=current_user
        )
        
        return partnership
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except PermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o destinatário pode aceitar a parceria"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao aceitar parceria: {str(e)}"
        )


@router.patch("/{partnership_id}/reject", response_model=PartnershipResponseSchema)
async def reject_partnership(
    partnership_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Rejeita uma proposta de parceria.
    Apenas o 'partner' (destinatário) pode rejeitar.
    """
    try:
        partnership_service = PartnershipService()
        partnership = await partnership_service.reject_partnership(
            partnership_id=partnership_id,
            partner_id=current_user
        )
        
        return partnership
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except PermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o destinatário pode rejeitar a parceria"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao rejeitar parceria: {str(e)}"
        )


@router.post("/{partnership_id}/generate-contract", response_model=ContractResponseSchema)
async def generate_contract(
    partnership_id: str,
    contract_data: ContractGenerationSchema,
    current_user: str = Depends(get_current_user_id)
):
    """
    Gera contrato para uma parceria aceita.
    Disponível após o aceite da proposta.
    """
    try:
        partnership_service = PartnershipService()
        contract_service = ContractService()
        
        # Verifica se a parceria existe e foi aceita
        partnership = await partnership_service.get_partnership_by_id(partnership_id)
        if not partnership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parceria não encontrada"
            )
        
        if partnership.status != "aceita":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contrato só pode ser gerado após aceite da parceria"
            )
        
        # Gera o contrato
        contract = await contract_service.generate_partnership_contract(
            partnership=partnership,
            template_type=contract_data.template_type,
            custom_clauses=contract_data.custom_clauses
        )
        
        # Atualiza status da parceria
        await partnership_service.update_partnership_status(
            partnership_id=partnership_id,
            new_status="contrato_pendente",
            contract_url=contract.contract_url
        )
        
        return contract
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao gerar contrato: {str(e)}"
        )


@router.patch("/{partnership_id}/accept-contract", response_model=PartnershipResponseSchema)
async def accept_contract(
    partnership_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Aceita e assina digitalmente o contrato da parceria.
    Ativa a parceria oficialmente.
    """
    try:
        partnership_service = PartnershipService()
        partnership = await partnership_service.accept_contract(
            partnership_id=partnership_id,
            signer_id=current_user
        )
        
        return partnership
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except PermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário não autorizado a assinar este contrato"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao aceitar contrato: {str(e)}"
        )


@router.post("/find-matches", response_model=List[MatchedLawyerSchema])
async def find_partnership_matches(
    search_data: PartnerSearchSchema,
    current_user: str = Depends(get_current_user_id)
):
    """
    Busca parceiros jurídicos usando o algoritmo de matching.
    Reutiliza a lógica de IA existente para encontrar advogados compatíveis.
    """
    try:
        match_service = MatchService()
        
        # Converte busca de parceria para formato de caso fictício
        matches = await match_service.find_partners(
            description=search_data.description,
            area=search_data.area,
            coordinates=search_data.coordinates,
            radius_km=search_data.radius_km,
            urgency_hours=search_data.urgency_hours,
            limit=search_data.limit,
            exclude_user_id=current_user  # Exclui o próprio usuário
        )
        
        return matches
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro na busca de parceiros: {str(e)}"
        )


@router.get("/{partnership_id}", response_model=PartnershipResponseSchema)
async def get_partnership_details(
    partnership_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Retorna detalhes de uma parceria específica.
    """
    try:
        partnership_service = PartnershipService()
        partnership = await partnership_service.get_partnership_by_id(
            partnership_id=partnership_id,
            user_id=current_user  # Verifica se usuário tem acesso
        )
        
        if not partnership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parceria não encontrada"
            )
        
        return partnership
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar parceria: {str(e)}"
        )


@router.delete("/{partnership_id}", response_model=dict)
async def cancel_partnership(
    partnership_id: str,
    current_user: str = Depends(get_current_user_id)
):
    """
    Cancela uma parceria (apenas se ainda estiver pendente).
    """
    try:
        partnership_service = PartnershipService()
        await partnership_service.cancel_partnership(
            partnership_id=partnership_id,
            user_id=current_user
        )
        
        return {"message": "Parceria cancelada com sucesso"}
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except PermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para cancelar esta parceria"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao cancelar parceria: {str(e)}"
        ) 