#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/routes/reviews_route.py

Rotas da API para criar e gerenciar avaliações (reviews).
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException, status

from backend.services import supabase
from backend.services.review_service import ReviewService
from backend.auth import get_current_user
from backend.api.schemas import ReviewCreate, ReviewResponse

router = APIRouter(
    prefix="/reviews",
    tags=["Reviews"],
    responses={404: {"description": "Not found"}},
)

@router.post(
    "/contracts/{contract_id}",
    response_model=ReviewResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar avaliação para um contrato"
)
async def create_review_for_contract(
    contract_id: uuid.UUID,
    review_data: ReviewCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Permite que um cliente crie uma avaliação para um contrato concluído.

    - **Verifica Permissão**: Apenas o cliente associado ao contrato pode criar a avaliação.
    - **Verifica Status**: O contrato deve ter o status 'closed'.
    - **RLS no Supabase**: As políticas de segurança no nível da linha do Supabase reforçam
      essas regras diretamente no banco de dados, garantindo a segurança dos dados.
    """
    client_id_str = current_user.get("id")
    if not client_id_str:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not authenticated or ID not found.")
    
    client_id = uuid.UUID(client_id_str)
    review_service = ReviewService(supabase)

    try:
        contract_res = supabase.table("contracts").select("lawyer_id, client_id").eq("id", str(contract_id)).single().execute()
        
        if not contract_res.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contract not found.")
        
        if str(contract_res.data['client_id']) != str(client_id):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not the client for this contract.")
            
        lawyer_id = uuid.UUID(contract_res.data['lawyer_id'])

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error fetching contract: {e}")

    created_review = await review_service.create_review(
        contract_id=contract_id,
        review_data=review_data,
        client_id=client_id,
        lawyer_id=lawyer_id
    )
    return created_review 