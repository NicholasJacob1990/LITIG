"""
Microsoft Graph Service
=======================

Acesso a emails e calendário do Outlook via Microsoft Graph API.
Suporta modos:
- App-only (Client Credentials): requer permissões de aplicativo e consentimento admin
- Delegated (Authorization Code): tokens por usuário (não implementa o redirect aqui)

Variáveis de ambiente (app-only):
- MS_GRAPH_TENANT_ID
- MS_GRAPH_CLIENT_ID
- MS_GRAPH_CLIENT_SECRET

Notas:
- Este módulo evita dependências pesadas; usa requests para chamar Graph
- Para delegated flow, espera receber um access_token válido externamente
"""

from __future__ import annotations

import os
import time
import logging
from typing import Any, Dict, List, Optional

import requests

logger = logging.getLogger(__name__)


GRAPH_BASE = "https://graph.microsoft.com/v1.0"
AUTH_BASE = "https://login.microsoftonline.com"


class GraphAuthError(RuntimeError):
    pass


class MicrosoftGraphService:
    def __init__(self):
        self.tenant_id = os.getenv("MS_GRAPH_TENANT_ID", "")
        self.client_id = os.getenv("MS_GRAPH_CLIENT_ID", "")
        self.client_secret = os.getenv("MS_GRAPH_CLIENT_SECRET", "")
        self._cached_token: Optional[Dict[str, Any]] = None

    # ========== AUTH ==========
    def _get_app_token(self, scope: str = "https://graph.microsoft.com/.default") -> str:
        if not (self.tenant_id and self.client_id and self.client_secret):
            raise GraphAuthError(
                "MS Graph app credentials not configured: set MS_GRAPH_TENANT_ID, MS_GRAPH_CLIENT_ID, MS_GRAPH_CLIENT_SECRET"
            )

        if self._cached_token and self._cached_token.get("expires_at", 0) - 60 > time.time():
            return self._cached_token["access_token"]

        token_url = f"{AUTH_BASE}/{self.tenant_id}/oauth2/v2.0/token"
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "scope": scope,
            "grant_type": "client_credentials",
        }
        resp = requests.post(token_url, data=data, timeout=20)
        if resp.status_code != 200:
            raise GraphAuthError(f"Failed to get app token: {resp.status_code} {resp.text}")
        token = resp.json()
        token["expires_at"] = time.time() + int(token.get("expires_in", 3600))
        self._cached_token = token
        return token["access_token"]

    # ========== EMAIL ==========
    def list_messages(self, user_id_or_upn: str, top: int = 25) -> List[Dict[str, Any]]:
        access_token = self._get_app_token()
        url = f"{GRAPH_BASE}/users/{user_id_or_upn}/messages?$top={min(top, 100)}"
        headers = {"Authorization": f"Bearer {access_token}"}
        resp = requests.get(url, headers=headers, timeout=20)
        if resp.status_code != 200:
            logger.error("Graph list_messages error: %s %s", resp.status_code, resp.text)
            return []
        data = resp.json()
        return data.get("value", [])

    def send_mail(
        self,
        user_id_or_upn: str,
        to: List[str],
        subject: str,
        body_html: str,
    ) -> bool:
        access_token = self._get_app_token()
        url = f"{GRAPH_BASE}/users/{user_id_or_upn}/sendMail"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        message = {
            "message": {
                "subject": subject,
                "body": {"contentType": "HTML", "content": body_html},
                "toRecipients": [{"emailAddress": {"address": addr}} for addr in to],
            },
            "saveToSentItems": True,
        }
        resp = requests.post(url, headers=headers, json=message, timeout=20)
        if resp.status_code in (202, 200):
            return True
        logger.error("Graph send_mail error: %s %s", resp.status_code, resp.text)
        return False

    # ========== CALENDAR ==========
    def list_events(self, user_id_or_upn: str, top: int = 50) -> List[Dict[str, Any]]:
        access_token = self._get_app_token()
        url = f"{GRAPH_BASE}/users/{user_id_or_upn}/events?$top={min(top, 100)}&$orderby=start/dateTime"
        headers = {"Authorization": f"Bearer {access_token}"}
        resp = requests.get(url, headers=headers, timeout=20)
        if resp.status_code != 200:
            logger.error("Graph list_events error: %s %s", resp.status_code, resp.text)
            return []
        data = resp.json()
        return data.get("value", [])

    def create_event(
        self,
        user_id_or_upn: str,
        subject: str,
        start_iso: str,
        end_iso: str,
        body_html: str = "",
        location: Optional[str] = None,
        attendees: Optional[List[str]] = None,
    ) -> Optional[Dict[str, Any]]:
        access_token = self._get_app_token()
        url = f"{GRAPH_BASE}/users/{user_id_or_upn}/events"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        event: Dict[str, Any] = {
            "subject": subject,
            "start": {"dateTime": start_iso, "timeZone": "UTC"},
            "end": {"dateTime": end_iso, "timeZone": "UTC"},
            "body": {"contentType": "HTML", "content": body_html or ""},
        }
        if location:
            event["location"] = {"displayName": location}
        if attendees:
            event["attendees"] = [
                {"emailAddress": {"address": a}, "type": "required"} for a in attendees
            ]
        resp = requests.post(url, headers=headers, json=event, timeout=20)
        if resp.status_code in (201, 200):
            return resp.json()
        logger.error("Graph create_event error: %s %s", resp.status_code, resp.text)
        return None


# Helper singleton
graph_service = MicrosoftGraphService()


