"""
Rotas relacionadas a usuários - perfil, permissões e dados do usuário autenticado
"""
import logging
import os
import base64
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from pydantic import BaseModel
from supabase import create_client, Client

from auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])

# Configuração Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

def get_supabase_client() -> Client:
    """Retorna cliente Supabase"""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        raise ValueError("Credenciais do Supabase não configuradas")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class UserMeResponse(BaseModel):
    """Schema de resposta para o endpoint /me"""
    id: str
    email: str
    user_role: str
    permissions: List[str]
    user_metadata: Dict[str, Any] = {}
    avatar_url: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    
    class Config:
        from_attributes = True


class ProfileUpdateRequest(BaseModel):
    """Schema para atualização de perfil"""
    full_name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class AvatarUploadResponse(BaseModel):
    """Schema de resposta para upload de avatar"""
    success: bool
    message: str
    avatar_url: Optional[str] = None


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
            "avatar_url": current_user.get("avatar_url"),
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


@router.post("/upload-avatar", response_model=AvatarUploadResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Upload de foto de perfil do usuário.
    
    Aceita arquivos de imagem (JPEG, PNG, WebP) até 5MB.
    Redimensiona automaticamente para 400x400px.
    """
    try:
        # Validar tipo de arquivo
        allowed_types = ["image/jpeg", "image/png", "image/webp"]
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=f"Tipo de arquivo não suportado. Use: {', '.join(allowed_types)}"
            )
        
        # Validar tamanho (5MB max)
        file_content = await file.read()
        if len(file_content) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail="Arquivo muito grande. Limite: 5MB"
            )
        
        # Gerar nome único para o arquivo
        user_id = current_user["id"]
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        unique_filename = f"avatars/{user_id}/{uuid.uuid4()}.{file_extension}"
        
        # Upload para Supabase Storage
        upload_result = supabase.storage.from_("user-avatars").upload(
            path=unique_filename,
            file=file_content,
            file_options={"content-type": file.content_type}
        )
        
        if upload_result.error:
            logger.error(f"Erro no upload: {upload_result.error}")
            raise HTTPException(status_code=500, detail="Erro no upload da imagem")
        
        # Gerar URL pública
        public_url = supabase.storage.from_("user-avatars").get_public_url(unique_filename)
        
        # Atualizar perfil do usuário com nova URL do avatar
        update_result = supabase.table("users").update({
            "avatar_url": public_url,
            "updated_at": datetime.now().isoformat()
        }).eq("id", user_id).execute()
        
        if update_result.error:
            logger.error(f"Erro ao atualizar perfil: {update_result.error}")
            # Tentar remover arquivo do storage se não conseguiu atualizar o perfil
            try:
                supabase.storage.from_("user-avatars").remove([unique_filename])
            except:
                pass
            raise HTTPException(status_code=500, detail="Erro ao salvar avatar no perfil")
        
        logger.info(f"Avatar atualizado com sucesso para usuário {user_id}")
        
        return AvatarUploadResponse(
            success=True,
            message="Avatar atualizado com sucesso",
            avatar_url=public_url
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no upload de avatar: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno no upload de avatar"
        )


@router.put("/profile", response_model=Dict[str, Any])
async def update_profile(
    profile_data: ProfileUpdateRequest,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Atualiza dados do perfil do usuário (exceto avatar).
    """
    try:
        user_id = current_user["id"]
        
        # Preparar dados para atualização
        update_data = {
            "updated_at": datetime.now().isoformat()
        }
        
        # Adicionar campos não nulos
        if profile_data.full_name is not None:
            update_data["full_name"] = profile_data.full_name
        
        if profile_data.phone is not None:
            update_data["phone"] = profile_data.phone
            
        if profile_data.bio is not None:
            update_data["bio"] = profile_data.bio
            
        if profile_data.metadata is not None:
            # Mesclar metadata existente com nova
            existing_metadata = current_user.get("user_metadata", {})
            updated_metadata = {**existing_metadata, **profile_data.metadata}
            update_data["user_metadata"] = updated_metadata
        
        # Atualizar no banco
        result = supabase.table("users").update(update_data).eq("id", user_id).execute()
        
        if result.error:
            logger.error(f"Erro ao atualizar perfil: {result.error}")
            raise HTTPException(status_code=500, detail="Erro ao atualizar perfil")
        
        logger.info(f"Perfil atualizado com sucesso para usuário {user_id}")
        
        return {
            "success": True,
            "message": "Perfil atualizado com sucesso",
            "updated_fields": list(update_data.keys())
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro na atualização de perfil: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno na atualização de perfil"
        )


@router.delete("/avatar")
async def delete_avatar(
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Remove a foto de perfil do usuário.
    """
    try:
        user_id = current_user["id"]
        current_avatar = current_user.get("avatar_url")
        
        if not current_avatar:
            return {
                "success": True,
                "message": "Usuário não possui avatar para remover"
            }
        
        # Extrair nome do arquivo da URL
        if "/user-avatars/" in current_avatar:
            try:
                filename = current_avatar.split("/user-avatars/")[-1]
                # Remover arquivo do storage
                supabase.storage.from_("user-avatars").remove([filename])
            except Exception as e:
                logger.warning(f"Erro ao remover arquivo do storage: {e}")
        
        # Remover URL do perfil
        result = supabase.table("users").update({
            "avatar_url": None,
            "updated_at": datetime.now().isoformat()
        }).eq("id", user_id).execute()
        
        if result.error:
            logger.error(f"Erro ao remover avatar do perfil: {result.error}")
            raise HTTPException(status_code=500, detail="Erro ao remover avatar")
        
        logger.info(f"Avatar removido com sucesso para usuário {user_id}")
        
        return {
            "success": True,
            "message": "Avatar removido com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro na remoção de avatar: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno na remoção de avatar"
        ) 