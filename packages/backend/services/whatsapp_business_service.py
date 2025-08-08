"""
WhatsApp Business Cloud API Service
===================================

Integração com a WhatsApp Business Cloud API (Meta).
Requer:
- WABA_PHONE_NUMBER_ID
- WABA_WHATSAPP_TOKEN (permanent access token)

Documentação: https://developers.facebook.com/docs/whatsapp/cloud-api
"""

from __future__ import annotations

import os
import logging
from typing import Any, Dict, Optional

import requests

logger = logging.getLogger(__name__)


class WhatsAppBusinessService:
    def __init__(self):
        self.phone_number_id = os.getenv("WABA_PHONE_NUMBER_ID", "")
        self.token = os.getenv("WABA_WHATSAPP_TOKEN", "")
        self._base_url = f"https://graph.facebook.com/v20.0/{self.phone_number_id}"

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }

    def send_text(self, to_phone_e164: str, message: str) -> bool:
        url = f"{self._base_url}/messages"
        payload = {
            "messaging_product": "whatsapp",
            "to": to_phone_e164,
            "type": "text",
            "text": {"body": message},
        }
        resp = requests.post(url, headers=self._headers(), json=payload, timeout=20)
        if resp.status_code in (200, 201):
            return True
        logger.error("WABA send_text error: %s %s", resp.status_code, resp.text)
        return False

    def send_audio(self, to_phone_e164: str, audio_url: str) -> bool:
        url = f"{self._base_url}/messages"
        payload = {
            "messaging_product": "whatsapp",
            "to": to_phone_e164,
            "type": "audio",
            "audio": {"link": audio_url},
        }
        resp = requests.post(url, headers=self._headers(), json=payload, timeout=20)
        if resp.status_code in (200, 201):
            return True
        logger.error("WABA send_audio error: %s %s", resp.status_code, resp.text)
        return False


waba_service = WhatsAppBusinessService()


