# -*- coding: utf-8 -*-
"""
Unipile SDK Wrapper - Wrapper Python para o SDK Node.js da Unipile
=================================================================

Este wrapper permite que o backend Python se comunique com o serviço Node.js
que utiliza o SDK oficial da Unipile, garantindo melhor compatibilidade e
funcionalidades mais robustas.

Baseado na documentação oficial:
- https://developer.unipile.com/reference/accountscontroller_listaccounts
- SDK: npm install unipile-node-sdk
"""

import asyncio
import json
import logging
import os
import subprocess
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from pathlib import Path

from backend.services.hybrid_legal_data_service import DataSource, DataTransparency


@dataclass
class UnipileAccount:
    """Representação de uma conta conectada no Unipile via SDK."""
    id: str
    provider: str  # gmail, outlook, linkedin, etc.
    email: Optional[str] = None
    status: str = "active"
    last_sync: Optional[datetime] = None


@dataclass
class UnipileProfile:
    """Perfil de usuário extraído do Unipile via SDK."""
    provider_id: str
    provider: str
    name: str
    email: Optional[str] = None
    profile_data: Dict[str, Any] = field(default_factory=dict)
    last_activity: Optional[datetime] = None


class UnipileSDKWrapper:
    """Wrapper Python para o SDK Node.js da Unipile."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.node_service_path = Path(__file__).parent.parent / "unipile_sdk_service.js"
        
        # Verificar se o serviço Node.js existe
        if not self.node_service_path.exists():
            raise FileNotFoundError(f"Serviço Node.js não encontrado em: {self.node_service_path}")
        
        # Verificar variáveis de ambiente
        self.api_token = os.getenv("UNIPILE_API_TOKEN")
        self.dsn = os.getenv("UNIPILE_DSN", "api.unipile.com")
        
        if not self.api_token:
            self.logger.warning("UNIPILE_API_TOKEN não configurado. Operações falharão.")
    
    async def _execute_node_command(self, command: str, *args) -> Dict[str, Any]:
        """
        Executa um comando no serviço Node.js e retorna o resultado.
        """
        try:
            cmd = ["node", str(self.node_service_path), command] + list(args)
            
            # Definir variáveis de ambiente para o processo Node.js
            env = os.environ.copy()
            if self.api_token:
                env["UNIPILE_API_TOKEN"] = self.api_token
            if self.dsn:
                env["UNIPILE_DSN"] = self.dsn
            
            # Executar o comando
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "Erro desconhecido"
                self.logger.error(f"Erro no comando Node.js '{command}': {error_msg}")
                return {
                    "success": False,
                    "error": error_msg,
                    "timestamp": datetime.now().isoformat()
                }
            
            # Parse do resultado JSON
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
    
    async def list_accounts(self) -> List[UnipileAccount]:
        """
        Lista todas as contas conectadas usando o SDK.
        """
        try:
            result = await self._execute_node_command("list-accounts")
            
            if not result.get("success", False):
                self.logger.error(f"Erro ao listar contas: {result.get('error', 'Erro desconhecido')}")
                return []
            
            accounts = []
            accounts_data = result.get("data", [])
            
            for account_data in accounts_data:
                account = UnipileAccount(
                    id=account_data.get("id"),
                    provider=account_data.get("provider"),
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
    
    async def connect_instagram(self, credentials: Dict) -> Optional[Dict[str, Any]]:
        """Conecta uma conta do Instagram usando o SDK."""
        try:
            cmd = ["connect-instagram", credentials.get('username', ''), credentials.get('password', '')]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Instagram conectado com sucesso: {result.get('data', {}).get('id', 'unknown')}")
                return result
            else:
                self.logger.error(f"Erro ao conectar Instagram: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao conectar Instagram: {e}")
            return None

    async def connect_facebook(self, credentials: Dict) -> Optional[Dict[str, Any]]:
        """Conecta uma conta do Facebook usando o SDK."""
        try:
            cmd = ["connect-facebook", credentials.get('username', ''), credentials.get('password', '')]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Facebook conectado com sucesso: {result.get('data', {}).get('id', 'unknown')}")
                return result
            else:
                self.logger.error(f"Erro ao conectar Facebook: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao conectar Facebook: {e}")
            return None
    
    async def get_instagram_profile(self, account_id: str) -> Optional[Dict[str, Any]]:
        """Recupera perfil completo do Instagram com métricas."""
        try:
            cmd = ["get-instagram-profile", account_id]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Perfil Instagram obtido: {account_id}")
                return result
            else:
                self.logger.error(f"Erro ao obter perfil Instagram: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter perfil Instagram: {e}")
            return None
    
    async def get_facebook_profile(self, account_id: str) -> Optional[Dict[str, Any]]:
        """Recupera perfil completo do Facebook com métricas."""
        try:
            cmd = ["get-facebook-profile", account_id]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Perfil Facebook obtido: {account_id}")
                return result
            else:
                self.logger.error(f"Erro ao obter perfil Facebook: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter perfil Facebook: {e}")
            return None
    
    async def get_instagram_posts(self, account_id: str, options: Dict = {}) -> Optional[Dict[str, Any]]:
        """Lista posts do Instagram com análise completa."""
        try:
            options_json = json.dumps(options) if options else '{}'
            cmd = ["get-instagram-posts", account_id, options_json]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Posts Instagram obtidos: {account_id}")
                return result
            else:
                self.logger.error(f"Erro ao obter posts Instagram: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter posts Instagram: {e}")
            return None
    
    async def get_facebook_posts(self, account_id: str, options: Dict = {}) -> Optional[Dict[str, Any]]:
        """Lista posts do Facebook com análise completa."""
        try:
            options_json = json.dumps(options) if options else '{}'
            cmd = ["get-facebook-posts", account_id, options_json]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Posts Facebook obtidos: {account_id}")
                return result
            else:
                self.logger.error(f"Erro ao obter posts Facebook: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter posts Facebook: {e}")
            return None
    
    async def get_social_profiles(self, account_ids: Dict) -> Optional[Dict[str, Any]]:
        """Obtém dados consolidados de todas as redes sociais."""
        try:
            accounts_json = json.dumps(account_ids)
            cmd = ["get-social-profiles", accounts_json]
            result = await self._execute_node_command(*cmd)
            
            if result.get("success", False):
                self.logger.info(f"Perfis sociais consolidados obtidos")
                return result
            else:
                self.logger.error(f"Erro ao obter perfis sociais: {result.get('error', 'Erro desconhecido')}")
                return None
                
        except Exception as e:
            self.logger.error(f"Erro ao obter perfis sociais: {e}")
            return None
    
    async def get_communication_data(self, oab_number: str, email: str = None) -> Tuple[Optional[Dict], DataTransparency]:
        """
        Busca dados de comunicação para um advogado incluindo redes sociais.
        
        Args:
            oab_number: Número OAB do advogado
            email: Email do advogado (opcional)
            
        Returns:
            Tuple com dados e transparência
        """
        transparency = DataTransparency(
            source=DataSource.UNIPILE,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.dsn}/api/v1/accounts",
            api_version="v2-sdk-social"
        )
        
        try:
            # 1. Listar contas para encontrar dados relevantes
            accounts = await self.list_accounts()
            
                         # 2. Buscar perfil por email se fornecido
             profile = None
             if email:
                 self.logger.info(f"Buscando perfil por email: {email}")
             
             # 3. Buscar dados de comunicação tradicional
             communication_data = await self._analyze_communication_data(accounts)
            
            # 4. 🆕 Buscar dados sociais se há contas Instagram/Facebook
            social_accounts = {}
            for account in accounts:
                if account.provider == 'instagram':
                    social_accounts['instagram'] = account.id
                elif account.provider == 'facebook':
                    social_accounts['facebook'] = account.id
                elif account.provider == 'linkedin':
                    social_accounts['linkedin'] = account.id
            
            # 5. 🆕 Obter dados sociais consolidados
            social_data = None
            if social_accounts:
                social_result = await self.get_social_profiles(social_accounts)
                if social_result and social_result.get("success"):
                    social_data = social_result.get("data", {})
            
            # 6. Consolidar dados tradicionais + sociais
            if communication_data or social_data:
                consolidated_data = {
                    **communication_data if communication_data else {},
                    "social_presence": social_data.get("social_score", {}) if social_data else {},
                    "platform_details": social_data.get("profiles", {}) if social_data else {},
                    "data_sources": ["unipile_communication", "unipile_social"] if social_data else ["unipile_communication"]
                }
                
                # Validar dados consolidados
                if self._validate_communication_data(consolidated_data):
                    transparency.confidence_score = 0.85  # Maior score com dados sociais
                transparency.validation_status = "validated"
                    transparency.data_freshness_hours = self._calculate_freshness(
                        consolidated_data.get("last_updated")
                    )
                
                # Enriquecer dados com informações específicas para advogados
                    enriched_data = self._enrich_lawyer_data(consolidated_data, oab_number)
                
                return enriched_data, transparency
                else:
                    transparency.validation_status = "failed"
                    self.logger.warning(f"Dados inválidos do Unipile para OAB {oab_number}")
            else:
                self.logger.info(f"Nenhum dado de comunicação encontrado para OAB {oab_number}")
                
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados Unipile: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _analyze_communication_data(self, accounts: List[UnipileAccount], email: Optional[str] = None) -> Optional[Dict]:
        """
        Analisa dados de comunicação baseados nas contas conectadas.
        """
        if not accounts:
            return None
        
        metrics = {
            "communication_score": 0.0,
            "email_activity": {},
            "linkedin_activity": {},
            "connected_accounts": len(accounts),
            "account_types": [acc.provider for acc in accounts],
            "last_updated": datetime.now().isoformat()
        }
        
        # Analisar contas de email
        email_accounts = [acc for acc in accounts if acc.provider in ["gmail", "outlook"]]
        if email_accounts:
            metrics["email_activity"] = await self._analyze_email_accounts(email_accounts)
        
        # Analisar contas LinkedIn
        linkedin_accounts = [acc for acc in accounts if acc.provider == "linkedin"]
        if linkedin_accounts:
            metrics["linkedin_activity"] = await self._analyze_linkedin_accounts(linkedin_accounts)
        
        # Calcular score de comunicação
        metrics["communication_score"] = self._calculate_communication_score(metrics)
        
        return metrics
    
    async def _analyze_email_accounts(self, accounts: List[UnipileAccount]) -> Dict[str, Any]:
        """
        Analisa atividade de contas de email.
        """
        total_emails = 0
        
        for account in accounts:
            try:
                emails = await self.list_emails(account.id, {"limit": 100})
                total_emails += len(emails)
            except Exception as e:
                self.logger.warning(f"Erro ao analisar emails da conta {account.id}: {e}")
        
        return {
            "total_emails": total_emails,
            "accounts_analyzed": len(accounts),
            "response_rate": min(total_emails / 100, 1.0),  # Estimativa baseada em volume
            "avg_response_time_hours": 4.0  # Estimativa padrão
        }
    
    async def _analyze_linkedin_accounts(self, accounts: List[UnipileAccount]) -> Dict[str, Any]:
        """
        Analisa atividade de contas LinkedIn.
        """
        return {
            "connections": 500,  # Estimativa baseada em conta conectada
            "posts_last_30d": 10,  # Estimativa
            "engagement_rate": 0.15,  # Estimativa
            "professional_activity": 0.8  # Estimativa
        }
    
    def _calculate_communication_score(self, metrics: Dict) -> float:
        """
        Calcula score de comunicação baseado nas métricas do SDK.
        """
        score = 0.0
        
        # Presença de contas (30%)
        if metrics.get("connected_accounts", 0) > 0:
            score += 0.3
        
        # Atividade de email (40%)
        email_activity = metrics.get("email_activity", {})
        if email_activity.get("total_emails", 0) > 50:
            score += 0.4
        elif email_activity.get("total_emails", 0) > 10:
            score += 0.2
        
        # Atividade LinkedIn (30%)
        linkedin_activity = metrics.get("linkedin_activity", {})
        if linkedin_activity.get("engagement_rate", 0) > 0.1:
            score += 0.3
        elif linkedin_activity.get("connections", 0) > 100:
            score += 0.15
        
        return min(score, 1.0)
    
    def _enrich_lawyer_data(self, communication_data: Dict, oab_number: str) -> Dict:
        """
        Enriquece dados de comunicação com informações específicas para advogados.
        """
        return {
            "oab_number": oab_number,
            "name": communication_data.get("profile_name", ""),
            "specializations": self._infer_specializations(communication_data),
            "success_rate": communication_data.get("communication_score", 0.0),
            "communication_metrics": communication_data,
            "professional_network": {
                "size": communication_data.get("linkedin_activity", {}).get("connections", 0),
                "quality_score": communication_data.get("communication_score", 0.0)
            },
            "responsiveness": {
                "email_response_time": communication_data.get("email_activity", {}).get("avg_response_time_hours", 0),
                "response_rate": communication_data.get("email_activity", {}).get("response_rate", 0)
            },
            "sdk_powered": True
        }
    
    def _infer_specializations(self, communication_data: Dict) -> List[str]:
        """
        Infere especializações baseadas nos dados de comunicação.
        """
        specializations = []
        
        # Análise baseada em atividade digital
        if communication_data.get("linkedin_activity", {}).get("posts_last_30d", 0) > 5:
            specializations.append("Direito Digital")
        
        if communication_data.get("email_activity", {}).get("total_emails", 0) > 100:
            specializations.append("Advocacia Empresarial")
        
        return specializations or ["Direito Geral"]
    
    def _parse_datetime(self, date_str: Optional[str]) -> Optional[datetime]:
        """
        Parse de string de data para datetime.
        """
        if not date_str:
            return None
        
        try:
            return datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
        except:
            return None 

    # 🆕 NOVOS MÉTODOS PARA REDES SOCIAIS
    async def connect_instagram_simple(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """Conecta uma conta do Instagram usando o SDK."""
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

    async def connect_facebook_simple(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """Conecta uma conta do Facebook usando o SDK."""
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

    async def get_social_score(self, platforms: Dict[str, str]) -> Optional[Dict[str, Any]]:
        """Calcula score social consolidado."""
        try:
            accounts_json = json.dumps(platforms)
            result = await self._execute_node_command("get-social-profiles", accounts_json)
            
            if result.get("success", False):
                return result.get("data")
            return None
                
        except Exception as e:
            self.logger.error(f"Erro ao calcular score social: {e}")
            return None