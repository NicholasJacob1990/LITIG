# -*- coding: utf-8 -*-
"""Webhooks – recebe eventos externos (DocuSign, etc.)."""
from fastapi import APIRouter, HTTPException, Request, status

from backend.config import settings
from supabase import create_client

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)


@router.post("/docusign", status_code=status.HTTP_204_NO_CONTENT)
async def docusign_webhook(req: Request):
    """Webhook DocuSign Connect – atualiza status de contratos.
    Aceitamos payload simplificado: {
        "envelopeId": "...",
        "status": "completed",
        "contract_id": "uuid"
    }
    """
    body = await req.json()
    envelope_id = body.get("envelopeId")
    status_event = body.get("status")
    contract_id = body.get("contract_id")

    if not envelope_id or not status_event or not contract_id:
        raise HTTPException(status_code=400, detail="Payload inválido")

    # Apenas tratamos eventos finalizados
    if status_event.lower() not in {"completed", "voided", "declined"}:
        return  # ignoramos outros eventos

    new_status = {
        "completed": "active",
        "voided": "canceled",
        "declined": "canceled",
    }.get(status_event.lower(), "pending-signature")

    try:
        supabase.table("contracts").update(
            {"status": new_status}).eq("id", contract_id).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
