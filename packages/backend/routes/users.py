"""
Rotas relacionadas a usuários - perfil, permissões e dados do usuário autenticado
"""
import logging
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


class UserMeResponse(BaseModel):
    """Schema de resposta para o endpoint /me"""
    id: str
    email: str
    user_role: str
    permissions: List[str]
    user_metadata: Dict[str, Any] = {}
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    
    class Config:
        from_attributes = True


@router.get("/me", response_model=UserMeResponse)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna o perfil do usuário autenticado com suas permissões.
    
    Este endpoint é fundamental para o sistema de navegação baseado em permissões
    e para determinar quais funcionalidades o usuário pode acessar.
    
    Returns:
        UserMeResponse: Dados do usuário com permissões e metadata
    """
    try:
        # Extrair dados essenciais do usuário
        user_data = {
            "id": current_user.get("id"),
            "email": current_user.get("email", ""),
            "user_role": current_user.get("user_role", "client"),
            "permissions": current_user.get("permissions", []),
            "user_metadata": current_user.get("user_metadata", {}),
            "created_at": current_user.get("created_at"),
            "updated_at": current_user.get("updated_at")
        }
        
        logger.info(f"Usuário {user_data['id']} acessou perfil com {len(user_data['permissions'])} permissões")
        
        return UserMeResponse(**user_data)
        
    except Exception as e:
        logger.error(f"Erro ao buscar perfil do usuário: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar perfil do usuário"
        )


@router.get("/me/permissions", response_model=List[str])
async def get_user_permissions(
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna apenas as permissões do usuário autenticado.
    
    Endpoint otimizado para verificações rápidas de permissões.
    """
    try:
        permissions = current_user.get("permissions", [])
        
        logger.debug(f"Usuário {current_user.get('id')} consultou permissões: {permissions}")
        
        return permissions
        
    except Exception as e:
        logger.error(f"Erro ao buscar permissões do usuário: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar permissões do usuário"
        )


@router.get("/me/role", response_model=Dict[str, str])
async def get_user_role(
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna apenas o role do usuário autenticado.
    
    Endpoint otimizado para verificações rápidas de role.
    """
    try:
        user_role = current_user.get("user_role", "client")
        
        return {"role": user_role}
        
    except Exception as e:
        logger.error(f"Erro ao buscar role do usuário: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar role do usuário"
        ) 