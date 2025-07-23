#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/services/review_service.py

Serviço para gerenciar as avaliações (reviews) de contratos.
"""
import uuid
import logging
from typing import Dict, Any

from fastapi import HTTPException, status
from supabase import Client

from api.schemas import ReviewCreate

logger = logging.getLogger(__name__)

class ReviewService:
    """Service for handling reviews."""

    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client

    async def create_review(
        self,
        *,
        contract_id: uuid.UUID,
        review_data: ReviewCreate,
        client_id: uuid.UUID,
        lawyer_id: uuid.UUID,
    ) -> Dict[str, Any]:
        """
        Creates a new review for a closed contract.
        RLS policies in Supabase enforce that only the client from the
        contract can create a review and only for contracts with 'closed' status.
        """
        logger.info(f"Client '{client_id}' is creating a review for contract '{contract_id}'.")

        review_dict = review_data.dict()
        review_dict["contract_id"] = str(contract_id)
        review_dict["client_id"] = str(client_id)
        review_dict["lawyer_id"] = str(lawyer_id)

        try:
            # The RLS policy handles authorization.
            # It checks if client_id matches auth.uid() and if contract is closed.
            data, count = self.supabase.table("reviews").insert(review_dict).execute()
            
            if not data or not data[1]:
                logger.error("Failed to insert review, no data returned from db.")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Could not create the review. The contract may not be closed or you may not be the client.",
                )

            created_review = data[1][0]
            logger.info(f"Review '{created_review['id']}' created for contract '{contract_id}'.")
            
            # Note: The average rating update is handled by a nightly job
            # as defined in the 20250724000000_create_reviews_table.sql migration.
            # No need to trigger it here.

            return created_review
        except Exception as e:
            logger.error(f"Error creating review for contract '{contract_id}': {e}")
            # This might catch exceptions from Supabase if RLS fails, etc.
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"An unexpected error occurred: {e}",
            ) 