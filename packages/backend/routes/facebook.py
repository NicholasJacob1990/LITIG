from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

from services.unipile_app_service import get_unipile_app_service
from auth import get_current_user
from models.user import User
# Funções de banco de dados que precisam ser criadas:
# from database import save_user_social_account

router = APIRouter(prefix="/api/v1/facebook", tags=["facebook"])

class FacebookConnectionRequest(BaseModel):
    username: str
    password: str

# --- Funções Auxiliares (Simuladas/A Implementar) ---

async def save_user_social_account(user_id: str, provider: str, account_id: str, username: str):
    """Salva a associação da conta social do usuário no banco de dados."""
    print(f"[Simulação DB] Salvando conta {provider} para usuário {user_id}: AccountID={account_id}, Username={username}")
    # Aqui iria a lógica de inserção/update no banco de dados na tabela `user_social_accounts`
    pass

# --- Endpoints da API ---

@router.post("/connect")
async def connect_facebook_account(
    request: FacebookConnectionRequest,
    current_user: User = Depends(get_current_user)
):
    """Conecta a conta Facebook/Messenger do usuário."""
    try:
        unipile_service = get_unipile_app_service()
        # Usa a função `connect_facebook_simple` que já existe no service
        result = await unipile_service.connect_facebook_simple(
            request.username, 
            request.password
        )
        
        if result and result.get("success"):
            account = result.get("data", {})
            account_id = account.get("id")

            if not account_id:
                raise HTTPException(status_code=500, detail="ID da conta não retornado pela Unipile.")

            # Salva a associação no banco de dados
            await save_user_social_account(
                user_id=current_user.id,
                provider="facebook",
                account_id=account_id,
                username=request.username
            )
            
            return {
                "success": True,
                "message": "Conta Facebook conectada com sucesso",
                "account_id": account_id
            }
        else:
            error_detail = result.get("error") if result else "Erro desconhecido"
            raise HTTPException(status_code=400, detail=f"Falha ao conectar Facebook: {error_detail}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno do servidor: {str(e)}") 