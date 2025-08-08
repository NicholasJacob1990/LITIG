"""
Gmail Service (REST API)
=======================

Integração básica para listar e enviar emails via Gmail REST API.
Este módulo assume que tokens OAuth 2.0 de cada usuário serão gerenciados
por outra camada (ex.: Supabase/DB) e injetados como access_token válidos.

Para flows completos (device code / web), ver google-auth-oauthlib.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

import requests

logger = logging.getLogger(__name__)


class GmailService:
    BASE_URL = "https://www.googleapis.com/gmail/v1"

    def list_messages(self, access_token: str, user_id: str = "me", max_results: int = 25) -> List[Dict[str, Any]]:
        headers = {"Authorization": f"Bearer {access_token}"}
        params = {"maxResults": min(max_results, 100)}
        url = f"{self.BASE_URL}/users/{user_id}/messages"
        resp = requests.get(url, headers=headers, params=params, timeout=20)
        if resp.status_code != 200:
            logger.error("Gmail list_messages error: %s %s", resp.status_code, resp.text)
            return []
        data = resp.json()
        return data.get("messages", [])

    def send_message_raw(self, access_token: str, raw_base64: str, user_id: str = "me") -> bool:
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        url = f"{self.BASE_URL}/users/{user_id}/messages/send"
        payload = {"raw": raw_base64}
        resp = requests.post(url, headers=headers, json=payload, timeout=20)
        if resp.status_code in (200, 202):
            return True
        logger.error("Gmail send_message error: %s %s", resp.status_code, resp.text)
        return False


gmail_service = GmailService()


