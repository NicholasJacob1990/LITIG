# backend/auth.py
import os

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from gotrue.errors import AuthApiError

from supabase import Client, create_client

# Carregar variáveis de ambiente
load_dotenv()

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


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependência do FastAPI para validar o token JWT e obter os dados do usuário.
    É injetado nos endpoints que requerem autenticação.
    """
    if IS_TESTING:
        # Em modo de teste, pulamos a validação e retornamos um usuário mock.
        return {"id": "test-user-id", "role": "authenticated"}

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
        return user
    except AuthApiError:
        # Se a API do Supabase retornar um erro (ex: token inválido/expirado)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não foi possível validar as credenciais",
            headers={"WWW-Authenticate": "Bearer"},
        )
