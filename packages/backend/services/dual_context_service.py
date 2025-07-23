"""
Serviço para gerenciar contexto duplo de advogados contratantes
Permite que advogados contratantes atuem como clientes criando casos próprios
"""

from typing import Dict, Any, Optional, List
from datetime import datetime
from uuid import uuid4
import logging

from config import get_supabase_client
from services.case_allocation_service import create_case_allocation_service

logger = logging.getLogger(__name__)

class DualContextService:
    """Serviço para gerenciar contexto duplo de advogados contratantes"""
    
    def __init__(self, supabase_client=None):
        self.supabase = supabase_client or get_supabase_client()
        self.allocation_service = create_case_allocation_service(supabase_client)
    
    async def create_case_as_client(
        self,
        contractor_id: str,
        case_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Cria caso com advogado contratante atuando como cliente
        
        Args:
            contractor_id: ID do advogado contratante
            case_data: Dados do caso
            
        Returns:
            Dict com dados do caso criado
        """
        try:
            # Verificar se é um advogado contratante válido
            if not await self._is_valid_contractor(contractor_id):
                raise ValueError("Usuário não é um advogado contratante válido")
            
            # Criar caso com contexto duplo
            case_id = str(uuid4())
            
            case_record = {
                "id": case_id,
                "client_id": contractor_id,  # Advogado atuando como cliente
                "title": case_data.get("title", ""),
                "description": case_data.get("description", ""),
                "category": case_data.get("category", ""),
                "urgency": case_data.get("urgency", "medium"),
                "estimated_value": case_data.get("estimated_value", 0),
                "status": "pending_assignment",
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
                "context_metadata": {
                    "dual_context": True,
                    "contractor_as_client": True,
                    "original_role": "contractor",
                    "client_context": "lawyer_acting_as_client"
                }
            }
            
            # Inserir caso no banco
            response = self.supabase.table("cases")\
                .insert(case_record)\
                .execute()
            
            if not response.data:
                raise ValueError("Erro ao criar caso")
            
            created_case = response.data[0]
            
            # Registrar contexto duplo
            await self._register_dual_context(contractor_id, case_id, "client")
            
            logger.info(f"Caso {case_id} criado com contexto duplo por advogado contratante {contractor_id}")
            
            return {
                "case": created_case,
                "dual_context": True,
                "acting_as": "client",
                "original_role": "contractor"
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar caso com contexto duplo: {e}")
            raise
    
    async def switch_context(
        self,
        user_id: str,
        target_context: str,
        case_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Alterna contexto do usuário (cliente <-> contratante)
        
        Args:
            user_id: ID do usuário
            target_context: Contexto alvo ("client" ou "contractor")
            case_id: ID do caso (opcional, para contexto específico)
            
        Returns:
            Dict com dados do contexto
        """
        try:
            # Verificar se é um advogado contratante válido
            if not await self._is_valid_contractor(user_id):
                raise ValueError("Usuário não pode alternar contexto")
            
            # Buscar contextos disponíveis
            available_contexts = await self._get_available_contexts(user_id)
            
            if target_context not in available_contexts:
                raise ValueError(f"Contexto {target_context} não disponível")
            
            # Registrar troca de contexto
            await self._register_context_switch(user_id, target_context, case_id)
            
            # Buscar dados do contexto
            context_data = await self._get_context_data(user_id, target_context)
            
            return {
                "user_id": user_id,
                "current_context": target_context,
                "available_contexts": available_contexts,
                "context_data": context_data,
                "case_id": case_id
            }
            
        except Exception as e:
            logger.error(f"Erro ao alternar contexto: {e}")
            raise
    
    async def get_cases_by_context(
        self,
        user_id: str,
        context: str = "all"
    ) -> Dict[str, Any]:
        """
        Busca casos por contexto (como cliente ou como contratante)
        
        Args:
            user_id: ID do usuário
            context: Contexto ("client", "contractor", "all")
            
        Returns:
            Dict com casos por contexto
        """
        try:
            if context == "all":
                client_cases = await self._get_cases_as_client(user_id)
                contractor_cases = await self._get_cases_as_contractor(user_id)
                
                return {
                    "client_cases": client_cases,
                    "contractor_cases": contractor_cases,
                    "total_client": len(client_cases),
                    "total_contractor": len(contractor_cases)
                }
            elif context == "client":
                cases = await self._get_cases_as_client(user_id)
                return {
                    "cases": cases,
                    "context": "client",
                    "total": len(cases)
                }
            elif context == "contractor":
                cases = await self._get_cases_as_contractor(user_id)
                return {
                    "cases": cases,
                    "context": "contractor",
                    "total": len(cases)
                }
            else:
                raise ValueError(f"Contexto inválido: {context}")
                
        except Exception as e:
            logger.error(f"Erro ao buscar casos por contexto: {e}")
            raise
    
    async def get_navigation_context(
        self,
        user_id: str,
        current_route: str
    ) -> Dict[str, Any]:
        """
        Obtém contexto de navegação para advogado contratante
        
        Args:
            user_id: ID do usuário
            current_route: Rota atual
            
        Returns:
            Dict com contexto de navegação
        """
        try:
            # Verificar se é um advogado contratante válido
            if not await self._is_valid_contractor(user_id):
                return {"dual_context": False}
            
            # Determinar contexto baseado na rota
            if current_route.startswith("/client"):
                current_context = "client"
            elif current_route.startswith("/contractor"):
                current_context = "contractor"
            else:
                current_context = "contractor"  # Padrão
            
            # Buscar estatísticas dos contextos
            client_stats = await self._get_client_context_stats(user_id)
            contractor_stats = await self._get_contractor_context_stats(user_id)
            
            return {
                "dual_context": True,
                "current_context": current_context,
                "available_contexts": ["client", "contractor"],
                "client_stats": client_stats,
                "contractor_stats": contractor_stats,
                "can_switch": True
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter contexto de navegação: {e}")
            return {"dual_context": False}
    
    async def _is_valid_contractor(self, user_id: str) -> bool:
        """Verifica se o usuário é um advogado contratante válido"""
        try:
            response = self.supabase.table("profiles")\
                .select("role, user_role")\
                .eq("id", user_id)\
                .single()\
                .execute()
            
            if response.data:
                role = response.data.get("role", "")
                user_role = response.data.get("user_role", "")
                
                # Verificar se é advogado individual ou escritório
                return user_role in ["lawyer_individual", "lawyer_office"]
            
            return False
            
        except Exception:
            return False
    
    async def _get_available_contexts(self, user_id: str) -> List[str]:
        """Obtém contextos disponíveis para o usuário"""
        contexts = ["contractor"]  # Sempre disponível para contratantes
        
        # Verificar se já criou casos como cliente
        client_cases = await self._get_cases_as_client(user_id)
        if client_cases:
            contexts.append("client")
        else:
            # Sempre permitir contexto cliente para contratantes
            contexts.append("client")
        
        return contexts
    
    async def _get_context_data(self, user_id: str, context: str) -> Dict[str, Any]:
        """Busca dados específicos do contexto"""
        if context == "client":
            return await self._get_client_context_data(user_id)
        elif context == "contractor":
            return await self._get_contractor_context_data(user_id)
        else:
            return {}
    
    async def _get_client_context_data(self, user_id: str) -> Dict[str, Any]:
        """Busca dados do contexto cliente"""
        try:
            cases = await self._get_cases_as_client(user_id)
            
            return {
                "total_cases": len(cases),
                "pending_cases": len([c for c in cases if c.get("status") == "pending_assignment"]),
                "active_cases": len([c for c in cases if c.get("status") == "in_progress"]),
                "recent_cases": cases[:5]  # 5 mais recentes
            }
        except Exception:
            return {}
    
    async def _get_contractor_context_data(self, user_id: str) -> Dict[str, Any]:
        """Busca dados do contexto contratante"""
        try:
            cases = await self._get_cases_as_contractor(user_id)
            
            return {
                "total_cases": len(cases),
                "pending_offers": len([c for c in cases if c.get("status") == "pending_assignment"]),
                "active_cases": len([c for c in cases if c.get("status") == "in_progress"]),
                "recent_cases": cases[:5]  # 5 mais recentes
            }
        except Exception:
            return {}
    
    async def _get_cases_as_client(self, user_id: str) -> List[Dict[str, Any]]:
        """Busca casos onde o usuário atua como cliente"""
        try:
            response = self.supabase.table("cases")\
                .select("*")\
                .eq("client_id", user_id)\
                .order("created_at", desc=True)\
                .execute()
            
            return response.data or []
        except Exception:
            return []
    
    async def _get_cases_as_contractor(self, user_id: str) -> List[Dict[str, Any]]:
        """Busca casos onde o usuário atua como contratante"""
        try:
            response = self.supabase.table("cases")\
                .select("*")\
                .eq("lawyer_id", user_id)\
                .order("created_at", desc=True)\
                .execute()
            
            return response.data or []
        except Exception:
            return []
    
    async def _get_client_context_stats(self, user_id: str) -> Dict[str, Any]:
        """Busca estatísticas do contexto cliente"""
        try:
            cases = await self._get_cases_as_client(user_id)
            
            return {
                "total_cases": len(cases),
                "pending": len([c for c in cases if c.get("status") == "pending_assignment"]),
                "in_progress": len([c for c in cases if c.get("status") == "in_progress"]),
                "completed": len([c for c in cases if c.get("status") == "completed"])
            }
        except Exception:
            return {}
    
    async def _get_contractor_context_stats(self, user_id: str) -> Dict[str, Any]:
        """Busca estatísticas do contexto contratante"""
        try:
            cases = await self._get_cases_as_contractor(user_id)
            
            return {
                "total_cases": len(cases),
                "pending": len([c for c in cases if c.get("status") == "pending_assignment"]),
                "in_progress": len([c for c in cases if c.get("status") == "in_progress"]),
                "completed": len([c for c in cases if c.get("status") == "completed"])
            }
        except Exception:
            return {}
    
    async def _register_dual_context(self, user_id: str, case_id: str, context: str):
        """Registra uso de contexto duplo"""
        try:
            self.supabase.table("dual_context_logs")\
                .insert({
                    "user_id": user_id,
                    "case_id": case_id,
                    "context": context,
                    "action": "create_case",
                    "timestamp": datetime.now().isoformat()
                })\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao registrar contexto duplo: {e}")
    
    async def _register_context_switch(self, user_id: str, target_context: str, case_id: Optional[str]):
        """Registra troca de contexto"""
        try:
            self.supabase.table("dual_context_logs")\
                .insert({
                    "user_id": user_id,
                    "case_id": case_id,
                    "context": target_context,
                    "action": "switch_context",
                    "timestamp": datetime.now().isoformat()
                })\
                .execute()
        except Exception as e:
            logger.error(f"Erro ao registrar troca de contexto: {e}")


def create_dual_context_service(supabase_client=None) -> DualContextService:
    """Factory para criar instância do serviço"""
    return DualContextService(supabase_client) 