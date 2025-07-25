"""
Serviço de Privacidade Universal
================================

Implementa a nova política corporativa:
"Qualquer caso – premium ou não – só expõe dados do cliente depois que o advogado/escritório clica em Aceitar."

Este serviço gerencia:
1. Mascaramento de dados pessoais do cliente
2. Preview com informações não-sensíveis
3. Aceite e revelação de dados completos
4. Auditoria de acesso a dados
"""

import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List
from uuid import UUID

from supabase import Client
from ..config import get_supabase_client

logger = logging.getLogger(__name__)


class PrivacyService:
    """Serviço centralizado para gerenciamento de privacidade de dados do cliente"""
    
    def __init__(self, supabase_client: Optional[Client] = None):
        self.supabase = supabase_client or get_supabase_client()
    
    def build_case_preview(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Constrói preview do caso com dados não-sensíveis apenas.
        
        Args:
            case_data: Dados completos do caso
            
        Returns:
            Dados do preview (sem informações pessoais do cliente)
        """
        preview = {
            "id": case_data.get("id"),
            "area": case_data.get("area"),
            "subarea": case_data.get("subarea"),
            "complexity": case_data.get("complexity", "MEDIUM"),
            "urgency_h": case_data.get("urgency_h"),
            "is_premium": case_data.get("is_premium", False),
            "valor_faixa": self._get_valor_faixa(case_data.get("valor_causa")),
            "created_at": case_data.get("created_at"),
            "status": case_data.get("status", "ABERTO"),
            # Localização apenas com cidade/estado, não endereço completo
            "location_city": case_data.get("location_city"),
            "location_state": case_data.get("location_state"),
        }
        
        # Adicionar contadores não-sensíveis
        if "documents_count" in case_data:
            preview["documents_count"] = case_data["documents_count"]
            
        return preview
    
    def _get_valor_faixa(self, valor_causa: Optional[float]) -> str:
        """Converte valor exato em faixa de valores para o preview"""
        if not valor_causa:
            return "Não informado"
        
        if valor_causa < 50000:
            return "Até R$ 50 mil"
        elif valor_causa < 100000:
            return "R$ 50-100 mil"
        elif valor_causa < 300000:
            return "R$ 100-300 mil"
        elif valor_causa < 500000:
            return "R$ 300-500 mil"
        else:
            return "Acima de R$ 500 mil"
    
    def mask_client_data(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Mascara dados sensíveis do cliente.
        
        Args:
            case_data: Dados completos do caso
            
        Returns:
            Caso com dados do cliente mascarados
        """
        masked_case = case_data.copy()
        
        # Substituir dados sensíveis por placeholders
        sensitive_fields = {
            "client_name": "Cliente (oculto até aceite)",
            "client_email": "***@***.com",
            "client_phone": "(***) ****-****",
            "client_cpf": "***.***.**-**",
            "client_cnpj": "**.***.***/****-**",
            "detailed_description": "Descrição completa disponível após aceite do caso",
            "client_address": "Endereço oculto por privacidade",
            "client_documents": [],  # Lista vazia
        }
        
        for field, placeholder in sensitive_fields.items():
            if field in masked_case:
                masked_case[field] = placeholder
        
        # Manter apenas preview de documentos (sem conteúdo)
        if "documents" in masked_case:
            masked_case["documents"] = [
                {
                    "id": doc.get("id"),
                    "type": doc.get("type", "Documento"),
                    "name": "Documento anexado (disponível após aceite)",
                    "size": doc.get("size"),
                    "created_at": doc.get("created_at")
                }
                for doc in masked_case.get("documents", [])
            ]
        
        return masked_case
    
    async def accept_case(self, case_id: str, lawyer_id: str) -> Dict[str, Any]:
        """
        Registra aceite do caso por um advogado/escritório.
        
        Args:
            case_id: ID do caso
            lawyer_id: ID do advogado/escritório que está aceitando
            
        Returns:
            Resultado da operação de aceite
        """
        try:
            # Verificar se caso existe e não foi aceito ainda
            case_response = self.supabase.table("cases").select("*").eq("id", case_id).single().execute()
            
            if not case_response.data:
                raise ValueError(f"Caso {case_id} não encontrado")
            
            case = case_response.data
            
            if case.get("accepted_by"):
                raise ValueError(f"Caso {case_id} já foi aceito por {case['accepted_by']}")
            
            # Registrar aceite
            update_data = {
                "accepted_by": lawyer_id,
                "accepted_at": datetime.utcnow().isoformat(),
                "status": "ACEITO"
            }
            
            update_response = self.supabase.table("cases").update(update_data).eq("id", case_id).execute()
            
            # Log de auditoria
            audit_data = {
                "case_id": case_id,
                "lawyer_id": lawyer_id,
                "action": "CASE_ACCEPTED",
                "timestamp": datetime.utcnow().isoformat(),
                "client_data_revealed": True
            }
            
            self.supabase.table("audit_logs").insert(audit_data).execute()
            
            logger.info(f"Caso {case_id} aceito por advogado {lawyer_id}")
            
            return {
                "success": True,
                "case_id": case_id,
                "accepted_by": lawyer_id,
                "accepted_at": update_data["accepted_at"]
            }
            
        except Exception as e:
            logger.error(f"Erro ao aceitar caso {case_id}: {str(e)}")
            raise
    
    async def get_case_for_user(self, case_id: str, user_id: str, user_role: str) -> Dict[str, Any]:
        """
        Retorna dados do caso respeitando política de privacidade.
        
        Args:
            case_id: ID do caso
            user_id: ID do usuário solicitando
            user_role: Papel do usuário (lawyer, admin, client)
            
        Returns:
            Dados do caso (completos ou mascarados conforme política)
        """
        try:
            # Buscar caso completo
            case_response = self.supabase.table("cases").select("*").eq("id", case_id).single().execute()
            
            if not case_response.data:
                raise ValueError(f"Caso {case_id} não encontrado")
            
            case_data = case_response.data
            
            # Verificar permissões de acesso completo
            can_access_full_data = (
                user_role == "admin" or  # Admins sempre podem ver
                case_data.get("client_id") == user_id or  # Cliente proprietário
                case_data.get("accepted_by") == user_id  # Advogado que aceitou
            )
            
            if can_access_full_data:
                # Log de auditoria para acesso a dados completos
                audit_data = {
                    "case_id": case_id,
                    "user_id": user_id,
                    "action": "FULL_DATA_ACCESS",
                    "timestamp": datetime.utcnow().isoformat(),
                    "client_data_visible": True
                }
                self.supabase.table("audit_logs").insert(audit_data).execute()
                
                return case_data
            else:
                # Retornar dados mascarados
                masked_data = self.mask_client_data(case_data)
                
                # Log de auditoria para acesso a preview
                audit_data = {
                    "case_id": case_id,
                    "user_id": user_id,
                    "action": "PREVIEW_ACCESS",
                    "timestamp": datetime.utcnow().isoformat(),
                    "client_data_visible": False
                }
                self.supabase.table("audit_logs").insert(audit_data).execute()
                
                return masked_data
                
        except Exception as e:
            logger.error(f"Erro ao buscar caso {case_id} para usuário {user_id}: {str(e)}")
            raise
    
    async def list_cases_for_discovery(self, user_id: str, filters: Optional[Dict] = None) -> List[Dict[str, Any]]:
        """
        Lista casos para descoberta (matching), sempre com dados mascarados até aceite.
        
        Args:
            user_id: ID do usuário (advogado/escritório)
            filters: Filtros opcionais (área, localização, etc.)
            
        Returns:
            Lista de casos com dados mascarados conforme política
        """
        try:
            # Query base
            query = self.supabase.table("cases").select("*")
            
            # Aplicar filtros se fornecidos
            if filters:
                if "area" in filters:
                    query = query.eq("area", filters["area"])
                if "subarea" in filters:
                    query = query.eq("subarea", filters["subarea"])
                if "status" in filters:
                    query = query.eq("status", filters["status"])
                else:
                    # Por padrão, só mostrar casos abertos
                    query = query.eq("status", "ABERTO")
            
            # Ordenar por data de criação (mais recentes primeiro)
            query = query.order("created_at", desc=True)
            
            cases_response = query.execute()
            cases = cases_response.data or []
            
            # Aplicar mascaramento universal
            masked_cases = []
            for case in cases:
                # Verificar se usuário já aceitou este caso
                if case.get("accepted_by") == user_id:
                    # Se já aceitou, pode ver dados completos
                    masked_cases.append(case)
                else:
                    # Senão, aplicar mascaramento
                    masked_cases.append(self.mask_client_data(case))
            
            # Log de auditoria para listagem
            audit_data = {
                "user_id": user_id,
                "action": "CASES_DISCOVERY",
                "timestamp": datetime.utcnow().isoformat(),
                "cases_count": len(masked_cases),
                "filters_applied": filters or {}
            }
            self.supabase.table("audit_logs").insert(audit_data).execute()
            
            return masked_cases
            
        except Exception as e:
            logger.error(f"Erro ao listar casos para usuário {user_id}: {str(e)}")
            raise
    
    async def can_user_accept_case(self, case_id: str, user_id: str) -> bool:
        """
        Verifica se usuário pode aceitar um caso específico.
        
        Args:
            case_id: ID do caso
            user_id: ID do usuário
            
        Returns:
            True se pode aceitar, False caso contrário
        """
        try:
            case_response = self.supabase.table("cases").select("accepted_by, status, client_id").eq("id", case_id).single().execute()
            
            if not case_response.data:
                return False
            
            case = case_response.data
            
            # Não pode aceitar se:
            # - Já foi aceito por outro
            # - Caso não está aberto
            # - É o próprio cliente tentando aceitar
            if (case.get("accepted_by") and case["accepted_by"] != user_id) or \
               case.get("status") != "ABERTO" or \
               case.get("client_id") == user_id:
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao verificar permissão de aceite para caso {case_id}, usuário {user_id}: {str(e)}")
            return False


# Instância global do serviço
privacy_service = PrivacyService() 