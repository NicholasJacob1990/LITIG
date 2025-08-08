# -*- coding: utf-8 -*-
"""
Communications Routes (Direct APIs)
===================================

Endpoints diretos para WhatsApp Business, Microsoft Graph (Outlook) e Gmail,
substituindo o uso do SDK Unipile.

Prefixo: /api/v2/communications
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Body

from datetime import datetime
import logging

from auth import get_current_user
from services.whatsapp_business_service import waba_service
from services.microsoft_graph_service import graph_service
from services.gmail_service import gmail_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v2/communications", tags=["Communications"])


# ===== WhatsApp Business =====

@router.post("/whatsapp/send-text")
async def whatsapp_send_text(
    to: str = Body(..., embed=True, description="Telefone em formato E.164"),
    message: str = Body(..., embed=True),
    current_user = Depends(get_current_user)
):
    try:
        ok = waba_service.send_text(to, message)
        if not ok:
            raise HTTPException(status_code=502, detail="Falha ao enviar mensagem WhatsApp")
        return {"success": True, "timestamp": datetime.now().isoformat()}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro WhatsApp send_text: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/whatsapp/send-audio")
async def whatsapp_send_audio(
    to: str = Body(..., embed=True),
    audio_url: str = Body(..., embed=True),
    current_user = Depends(get_current_user)
):
    try:
        ok = waba_service.send_audio(to, audio_url)
        if not ok:
            raise HTTPException(status_code=502, detail="Falha ao enviar áudio WhatsApp")
        return {"success": True, "timestamp": datetime.now().isoformat()}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro WhatsApp send_audio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== Microsoft Graph (Outlook mail & calendar) =====

@router.get("/graph/{user_upn}/messages")
async def graph_list_messages(
    user_upn: str,
    top: int = Query(25, ge=1, le=100),
    current_user = Depends(get_current_user)
):
    try:
        messages = graph_service.list_messages(user_upn, top)
        return {"messages": messages, "total": len(messages), "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"Erro Graph list_messages: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/graph/{user_upn}/sendMail")
async def graph_send_mail(
    user_upn: str,
    to: List[str] = Body(..., embed=True),
    subject: str = Body(..., embed=True),
    body_html: str = Body(..., embed=True),
    current_user = Depends(get_current_user)
):
    try:
        ok = graph_service.send_mail(user_upn, to, subject, body_html)
        if not ok:
            raise HTTPException(status_code=502, detail="Falha ao enviar email Graph")
        return {"success": True, "timestamp": datetime.now().isoformat()}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro Graph send_mail: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/graph/{user_upn}/events")
async def graph_list_events(
    user_upn: str,
    top: int = Query(50, ge=1, le=100),
    current_user = Depends(get_current_user)
):
    try:
        events = graph_service.list_events(user_upn, top)
        return {"events": events, "total": len(events), "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"Erro Graph list_events: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/graph/{user_upn}/events")
async def graph_create_event(
    user_upn: str,
    subject: str = Body(..., embed=True),
    start_iso: str = Body(..., embed=True),
    end_iso: str = Body(..., embed=True),
    body_html: str = Body("", embed=True),
    location: Optional[str] = Body(None, embed=True),
    attendees: Optional[List[str]] = Body(None, embed=True),
    current_user = Depends(get_current_user)
):
    try:
        result = graph_service.create_event(user_upn, subject, start_iso, end_iso, body_html, location, attendees)
        if not result:
            raise HTTPException(status_code=502, detail="Falha ao criar evento Graph")
        return {"success": True, "event": result, "timestamp": datetime.now().isoformat()}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro Graph create_event: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== Gmail (requires delegated access_token managed elsewhere) =====

@router.get("/gmail/messages")
async def gmail_list_messages(
    access_token: str = Query(..., description="OAuth2 access token"),
    max_results: int = Query(25, ge=1, le=100),
    current_user = Depends(get_current_user)
):
    try:
        items = gmail_service.list_messages(access_token, max_results=max_results)
        return {"messages": items, "total": len(items), "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"Erro Gmail list_messages: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/gmail/send")
async def gmail_send_message_raw(
    access_token: str = Body(..., embed=True),
    raw_base64: str = Body(..., embed=True, description="RFC 2822 MIME message Base64 URL-safe"),
    current_user = Depends(get_current_user)
):
    try:
        ok = gmail_service.send_message_raw(access_token, raw_base64)
        if not ok:
            raise HTTPException(status_code=502, detail="Falha ao enviar email Gmail")
        return {"success": True, "timestamp": datetime.now().isoformat()}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro Gmail send_message: {e}")
        raise HTTPException(status_code=500, detail=str(e))


