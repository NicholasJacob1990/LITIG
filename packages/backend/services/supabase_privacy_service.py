"""
Serviço de Privacidade Universal com Supabase
============================================

Implementa a nova política corporativa usando RLS (Row Level Security):
"Qualquer caso – premium ou não – só expõe dados do cliente 
 depois que o advogado/escritório clica em Aceitar."

Este serviço usa:
- View cases_preview para listagem segura
- RPC accept_case() para aceites
- RLS policies para controle automático
"""

import logging
from typing import Dict, Any, List, Optional
from supabase import Client
from ..config import get_supabase_client

logger = logging.getLogger(__name__)


class SupabasePrivacyService:
    """Serviço de privacidade usando Supabase RLS e views"""
    
    def __init__(self, supabase_client: Optional[Client] = None):
        self.supabase = supabase_client or get_supabase_client()
    
    async def list_cases_preview(self, filters: Optional[Dict] = None) -> List[Dict[str, Any]]:
        """
        Lista casos usando a view cases_preview (dados não-sensíveis apenas).
        
        Args:
            filters: Filtros opcionais (area, subarea, etc.)
            
        Returns:
            Lista de casos com preview (sem dados sensíveis)
        """
        try:
            # Query base na view segura
            query = self.supabase.table("cases_preview").select("*")
            
            # Aplicar filtros se fornecidos
            if filters:
                if "area" in filters:
                    query = query.eq("area", filters["area"])
                if "subarea" in filters:
                    query = query.eq("subarea", filters["subarea"])
                if "is_premium" in filters:
                    query = query.eq("is_premium", filters["is_premium"])
                if "location_state" in filters:
                    query = query.eq("location_state", filters["location_state"])
            
            # Ordenar por data de criação (mais recentes primeiro)
            query = query.order("created_at", desc=True)
            
            # Executar query
            response = query.execute()
            
            return response.data or []
            
        except Exception as e:
            logger.error(f"Erro ao listar casos preview: {str(e)}")
            raise
    
    async def accept_case(self, case_id: str) -> Dict[str, Any]:
        """
        Aceita um caso usando a RPC function do Supabase.
        
        Args:
            case_id: ID do caso a ser aceito
            
        Returns:
            Resultado da operação (success, error, etc.)
        """
        try:
            # Chamar RPC function que já implementa toda a lógica
            response = self.supabase.rpc("accept_case", {"_case_id": case_id}).execute()
            
            return response.data
            
        except Exception as e:
            logger.error(f"Erro ao aceitar caso {case_id}: {str(e)}")
            raise
    
    async def abandon_case(self, case_id: str, reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Abandona um caso aceito.
        
        Args:
            case_id: ID do caso a ser abandonado
            reason: Motivo do abandono (opcional)
            
        Returns:
            Resultado da operação
        """
        try:
            # Chamar RPC function para abandonar
            response = self.supabase.rpc("abandon_case", {
                "_case_id": case_id,
                "_reason": reason
            }).execute()
            
            return response.data
            
        except Exception as e:
            logger.error(f"Erro ao abandonar caso {case_id}: {str(e)}")
            raise
    
    async def get_case_full_details(self, case_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca detalhes completos de um caso.
        
        Só retorna dados se o usuário atual tiver permissão (aceitou o caso).
        A RLS policy do Supabase controla automaticamente o acesso.
        
        Args:
            case_id: ID do caso
            
        Returns:
            Dados completos do caso ou None se sem permissão
        """
        try:
            # Query na tabela cases (protegida por RLS)
            response = self.supabase.table("cases").select("*").eq("id", case_id).single().execute()
            
            return response.data
            
        except Exception as e:
            # Se der erro de permissão, retorna None (não tem acesso)
            if "permission" in str(e).lower() or "policy" in str(e).lower():
                return None
            
            logger.error(f"Erro ao buscar caso {case_id}: {str(e)}")
            raise
    
    async def get_user_accepted_cases(self) -> List[Dict[str, Any]]:
        """
        Lista casos aceitos pelo usuário atual.
        
        Returns:
            Lista de casos aceitos pelo usuário
        """
        try:
            # Buscar assignments do usuário
            assignments_response = self.supabase.table("case_assignments").select("""
                case_id,
                accepted_at,
                cases!inner(*)
            """).is_("abandoned_at", "null").execute()
            
            # Extrair os casos das assignments
            cases = []
            for assignment in assignments_response.data or []:
                case_data = assignment["cases"]
                case_data["accepted_at"] = assignment["accepted_at"]
                cases.append(case_data)
            
            return cases
            
        except Exception as e:
            logger.error(f"Erro ao buscar casos aceitos: {str(e)}")
            raise
    
    async def can_accept_case(self, case_id: str) -> bool:
        """
        Verifica se um caso pode ser aceito.
        
        Args:
            case_id: ID do caso
            
        Returns:
            True se pode aceitar, False caso contrário
        """
        try:
            # Verificar se caso existe na view preview (casos disponíveis)
            preview_response = self.supabase.table("cases_preview").select("is_accepted").eq("id", case_id).single().execute()
            
            if not preview_response.data:
                return False
            
            # Se já foi aceito, não pode aceitar novamente
            return not preview_response.data.get("is_accepted", False)
            
        except Exception as e:
            logger.error(f"Erro ao verificar se pode aceitar caso {case_id}: {str(e)}")
            return False
    
    async def get_case_documents(self, case_id: str) -> List[Dict[str, Any]]:
        """
        Lista documentos de um caso.
        
        Só retorna se o usuário tiver permissão (Storage RLS policy).
        
        Args:
            case_id: ID do caso
            
        Returns:
            Lista de documentos do caso
        """
        try:
            # Listar arquivos do bucket case-files com prefixo do case_id
            response = self.supabase.storage.from_("case-files").list(f"{case_id}/")
            
            return response or []
            
        except Exception as e:
            logger.error(f"Erro ao listar documentos do caso {case_id}: {str(e)}")
            return []
    
    async def download_case_document(self, case_id: str, file_path: str) -> Optional[bytes]:
        """
        Baixa um documento do caso.
        
        Args:
            case_id: ID do caso
            file_path: Caminho do arquivo
            
        Returns:
            Conteúdo do arquivo ou None se sem permissão
        """
        try:
            # Download do arquivo (protegido por Storage RLS policy)
            response = self.supabase.storage.from_("case-files").download(f"{case_id}/{file_path}")
            
            return response
            
        except Exception as e:
            logger.error(f"Erro ao baixar documento {file_path} do caso {case_id}: {str(e)}")
            return None


# Instância global do serviço
supabase_privacy_service = SupabasePrivacyService() 