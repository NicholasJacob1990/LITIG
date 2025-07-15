# backend/auth.py
import logging
import os

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from gotrue.errors import AuthApiError

from supabase import Client, create_client

# Carregar variáveis de ambiente
load_dotenv()

# Configurar logger
logger = logging.getLogger(__name__)

# --- Configuração ---
# Estas variáveis são necessárias para que o cliente Supabase possa verificar o token.
SUPABASE_URL = os.getenv("SUPABASE_URL")
# Usando a chave anônima pública
SUPABASE_ANON_KEY = os.getenv("EXPO_PUBLIC_SUPABASE_ANON_KEY")

# Em um ambiente de teste ou desenvolvimento, usamos valores falsos para evitar erros de inicialização.
IS_TESTING = os.getenv("TESTING") == "true"
IS_DEVELOPMENT = os.getenv("ENVIRONMENT") == "development"

if IS_TESTING or IS_DEVELOPMENT or not SUPABASE_URL or not SUPABASE_ANON_KEY:
    SUPABASE_URL = "https://test.supabase.co"
    SUPABASE_ANON_KEY = "test-anon-key"
    print("AVISO: Rodando em modo de desenvolvimento/teste com credenciais Supabase mock")

# Cliente Supabase usando a chave anônima para validação do token.
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

# Define o esquema de autenticação. "tokenUrl" não é usado, mas é um campo obrigatório.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Dependência de Autenticação ---


async def _enrich_user_with_permissions(user):
    """
    Enriquece os dados do usuário com suas permissões baseado no perfil.
    """
    try:
        # Buscar perfil do usuário
        profile_response = supabase.table("profiles").select("user_role").eq("user_id", user.id).single().execute()
        
        if not profile_response.data:
            # Se não há perfil, usar role padrão
            user_role = "client"
        else:
            user_role = profile_response.data.get("user_role", "client")
        
        # Buscar permissões do usuário
        permissions_response = supabase.rpc("get_user_permissions", {"user_id": user.id}).execute()
        
        permissions = []
        if permissions_response.data:
            permissions = [perm["permission_key"] for perm in permissions_response.data]
        
        # Adicionar permissões aos dados do usuário
        user_dict = user.dict() if hasattr(user, 'dict') else user.__dict__
        user_dict["permissions"] = permissions
        user_dict["user_role"] = user_role
        
        return user_dict
        
    except Exception as e:
        # Em caso de erro, retornar usuário sem permissões
        logger.warning(f"Erro ao buscar permissões do usuário {user.id}: {e}")
        user_dict = user.dict() if hasattr(user, 'dict') else user.__dict__
        user_dict["permissions"] = []
        user_dict["user_role"] = "client"
        return user_dict


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependência do FastAPI para validar o token JWT e obter os dados do usuário.
    É injetado nos endpoints que requerem autenticação.
    
    Agora inclui as permissões do usuário baseado no seu perfil.
    """
    if IS_TESTING:
        # Em modo de teste, pulamos a validação e retornamos um usuário mock.
        return {
            "id": "test-user-id", 
            "role": "authenticated",
            "permissions": ["nav.view.dashboard", "nav.view.cases"]  # Permissões mock para teste
        }

    try:
        # A biblioteca do Supabase valida o token e retorna os dados do usuário.
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciais inválidas ou token expirado",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Enriquecer dados do usuário com permissões
        user_with_permissions = await _enrich_user_with_permissions(user)
        return user_with_permissions
        
    except AuthApiError:
        # Se a API do Supabase retornar um erro (ex: token inválido/expirado)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não foi possível validar as credenciais",
            headers={"WWW-Authenticate": "Bearer"},
        )
