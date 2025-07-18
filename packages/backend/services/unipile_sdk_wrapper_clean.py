# -*- coding: utf-8 -*-
"""
Unipile SDK Wrapper - Wrapper Python LIMPO para o SDK Node.js da Unipile
=======================================================================

Versão corrigida e funcional do wrapper Python que se comunica com o serviço Node.js
usando o SDK oficial da Unipile.

Funcionalidades:
- LinkedIn: conectar, perfil empresa
- Instagram: conectar, perfil, posts, métricas  
- Facebook: conectar, perfil, posts, métricas
- Score social consolidado
"""

import asyncio
import json
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from pathlib import Path

from backend.services.hybrid_legal_data_service import DataSource, DataTransparency


@dataclass
class UnipileAccount:
    """Conta conectada no Unipile."""
    id: str
    provider: str
    email: Optional[str] = None
    status: str = "active"
    last_sync: Optional[datetime] = None


class UnipileSDKWrapper:
    """Wrapper Python para comunicação com SDK Node.js da Unipile."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.node_service_path = Path(__file__).parent.parent / "unipile_sdk_service.js"
        self.api_token = os.getenv("UNIPILE_API_TOKEN")
        self.dsn = os.getenv("UNIPILE_DSN", "api.unipile.com")
        
        if not self.node_service_path.exists():
            raise FileNotFoundError(f"Serviço Node.js não encontrado: {self.node_service_path}")
        
        if not self.api_token:
            self.logger.warning("UNIPILE_API_TOKEN não configurado")
    
    async def _execute_node_command(self, command: str, *args) -> Dict[str, Any]:
        """Executa comando no serviço Node.js e retorna resultado."""
        try:
            cmd = ["node", str(self.node_service_path), command] + list(args)
            
            env = os.environ.copy()
            if self.api_token:
                env["UNIPILE_API_TOKEN"] = self.api_token
            if self.dsn:
                env["UNIPILE_DSN"] = self.dsn
            
            # Executar comando com timeout
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env
            )
            
            # Aguardar resultado com timeout de 30 segundos
            try:
                stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30)
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return {
                    "success": False,
                    "error": "Timeout na execução do comando Node.js",
                    "timestamp": datetime.now().isoformat()
                }
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "Erro desconhecido"
                self.logger.error(f"Erro no comando Node.js '{command}': {error_msg}")
                return {
                    "success": False,
                    "error": error_msg,
                    "timestamp": datetime.now().isoformat()
                }
            
            try:
                result = json.loads(stdout.decode())
                return result
            except json.JSONDecodeError as e:
                self.logger.error(f"Erro ao fazer parse do JSON: {e}")
                return {
                    "success": False,
                    "error": f"JSON parse error: {e}",
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            self.logger.error(f"Erro ao executar comando Node.js: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

    # ===== MÉTODOS BÁSICOS =====
    
    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde da conexão com Unipile."""
        result = await self._execute_node_command("health-check")
        return result

    async def list_accounts(self) -> List[UnipileAccount]:
        """Lista todas as contas conectadas."""
        try:
            result = await self._execute_node_command("list-accounts")
            
            if not result.get("success", False):
                self.logger.error(f"Erro ao listar contas: {result.get('error')}")
                return []
            
            accounts = []
            accounts_data = result.get("data", [])
            
            for account_data in accounts_data:
                account = UnipileAccount(
                    id=account_data.get("id", ""),
                    provider=account_data.get("provider", ""),
                    email=account_data.get("email") or account_data.get("login"),
                    status=account_data.get("status", "active"),
                    last_sync=self._parse_datetime(account_data.get("last_sync_at"))
                )
                accounts.append(account)
            
            self.logger.info(f"Listadas {len(accounts)} contas via SDK Unipile")
            return accounts
            
        except Exception as e:
            self.logger.error(f"Erro ao listar contas: {e}")
            return []

    # ===== MÉTODOS INSTAGRAM =====
    
    async def connect_instagram_simple(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """Conecta conta Instagram."""
        try:
            result = await self._execute_node_command("connect-instagram", username, password)
            
            if result.get("success", False):
                self.logger.info(f"Instagram conectado: {username}")
                return result
            else:
                self.logger.error(f"Erro ao conectar Instagram: {result.get('error')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao conectar Instagram: {e}")
            return None

    async def get_instagram_data(self, account_id: str) -> Optional[Dict[str, Any]]:
        """Obtém dados completos do Instagram."""
        try:
            profile_result = await self._execute_node_command("get-instagram-profile", account_id)
            posts_result = await self._execute_node_command("get-instagram-posts", account_id, '{"limit":20}')
            
            if profile_result.get("success") and posts_result.get("success"):
                return {
                    "profile": profile_result.get("data"),
                    "posts": posts_result.get("data"),
                    "provider": "instagram"
                }
            return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter dados Instagram: {e}")
            return None

    # ===== MÉTODOS FACEBOOK =====
    
    async def connect_facebook_simple(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """Conecta conta Facebook."""
        try:
            result = await self._execute_node_command("connect-facebook", username, password)
            
            if result.get("success", False):
                self.logger.info(f"Facebook conectado: {username}")
                return result
            else:
                self.logger.error(f"Erro ao conectar Facebook: {result.get('error')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao conectar Facebook: {e}")
            return None

    async def get_facebook_data(self, account_id: str) -> Optional[Dict[str, Any]]:
        """Obtém dados completos do Facebook."""
        try:
            profile_result = await self._execute_node_command("get-facebook-profile", account_id)
            posts_result = await self._execute_node_command("get-facebook-posts", account_id, '{"limit":20}')
            
            if profile_result.get("success") and posts_result.get("success"):
                return {
                    "profile": profile_result.get("data"),
                    "posts": posts_result.get("data"),
                    "provider": "facebook"
                }
            return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter dados Facebook: {e}")
            return None

    # ===== SCORE SOCIAL CONSOLIDADO =====
    
    async def get_social_score(self, platforms: Dict[str, str]) -> Optional[Dict[str, Any]]:
        """Calcula score social consolidado de todas as plataformas."""
        try:
            accounts_json = json.dumps(platforms)
            result = await self._execute_node_command("get-social-profiles", accounts_json)
            
            if result.get("success", False):
                return result.get("data")
            return None
                
        except Exception as e:
            self.logger.error(f"Erro ao calcular score social: {e}")
            return None

    # ===== INTEGRAÇÃO COM HYBRID DATA SERVICE =====
    
    async def get_communication_data(self, oab_number: str, email: Optional[str] = None) -> Tuple[Optional[Dict], DataTransparency]:
        """
        Busca dados de comunicação + redes sociais para um advogado.
        """
        transparency = DataTransparency(
            source=DataSource.UNIPILE,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"https://{self.dsn}/api/v1/accounts",
            api_version="v2-sdk-social"
        )
        
        try:
            # 1. Listar contas disponíveis
            accounts = await self.list_accounts()
            
            # 2. Buscar dados sociais se há contas
            social_accounts = {}
            for account in accounts:
                if account.provider == 'instagram':
                    social_accounts['instagram'] = account.id
                elif account.provider == 'facebook':
                    social_accounts['facebook'] = account.id
                elif account.provider == 'linkedin':
                    social_accounts['linkedin'] = account.id
            
            # 3. Calcular score social
            social_data = None
            if social_accounts:
                social_data = await self.get_social_score(social_accounts)
            
            # 4. Dados básicos de comunicação
            communication_data = {
                "oab_number": oab_number,
                "email": email,
                "accounts_found": len(accounts),
                "social_platforms": list(social_accounts.keys()),
                "last_updated": datetime.now().isoformat()
            }
            
            # 5. Consolidar dados
            if social_data:
                communication_data.update({
                    "social_score": social_data.get("social_score", {}),
                    "platform_details": social_data.get("profiles", {}),
                    "data_sources": ["unipile_social"]
                })
                
                transparency.confidence_score = 0.85
                transparency.validation_status = "validated"
                transparency.data_freshness_hours = 1
                
                return communication_data, transparency
            else:
                # Dados básicos sem redes sociais
                transparency.confidence_score = 0.65
                transparency.validation_status = "partial"
                transparency.data_freshness_hours = 2
                
                return communication_data, transparency
                
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados Unipile: {e}")
            transparency.validation_status = "failed"
            return None, transparency

    # ===== UTILITÁRIOS =====
    
    def _parse_datetime(self, date_str: Optional[str]) -> Optional[datetime]:
        """Parse de string de data para datetime."""
        if not date_str:
            return None
        
        try:
            return datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
        except:
            return None 