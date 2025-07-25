from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

from services.unipile_app_service import get_unipile_app_service
from auth import get_current_user
from models.user import User
# Funções de banco de dados que precisam ser criadas:
# from database import save_user_social_account, get_user_social_account

router = APIRouter(prefix="/api/v1/instagram", tags=["instagram"])

class InstagramConnectionRequest(BaseModel):
    username: str
    password: str

# --- Funções Auxiliares (Simuladas/A Implementar) ---

async def save_user_social_account(user_id: str, provider: str, account_id: str, username: str):
    """Salva a associação da conta social do usuário no banco de dados."""
    print(f"[Simulação DB] Salvando conta {provider} para usuário {user_id}: AccountID={account_id}, Username={username}")
    # Aqui iria a lógica de inserção/update no banco de dados na tabela `user_social_accounts`
    pass

async def get_user_instagram_account(user_id: str) -> Dict[str, Any]:
    """Busca a conta Instagram conectada de um usuário."""
    print(f"[Simulação DB] Buscando conta Instagram para usuário {user_id}")
    # Lógica para buscar do banco de dados
    # Exemplo: SELECT * FROM user_social_accounts WHERE user_id = :user_id AND provider = 'instagram'
    # Retorno mockado para permitir o funcionamento do endpoint
    return {"account_id": "acc_mock_instagram_12345", "username": "mock_user"}

# --- Endpoints da API ---

@router.post("/connect")
async def connect_instagram_account(
    request: InstagramConnectionRequest,
    current_user: User = Depends(get_current_user)
):
    """Conecta a conta Instagram do usuário e a associa ao seu perfil."""
    try:
        unipile_service = get_unipile_app_service()
        # Usa a função `connect_instagram_simple` que já existe no service
        result = await unipile_service.connect_instagram_simple(
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
                provider="instagram",
                account_id=account_id,
                username=request.username
            )
            
            return {
                "success": True,
                "message": "Conta Instagram conectada com sucesso",
                "account_id": account_id
            }
        else:
            error_detail = result.get("error") if result else "Erro desconhecido"
            raise HTTPException(status_code=400, detail=f"Falha ao conectar Instagram: {error_detail}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno do servidor: {str(e)}")

@router.get("/profile/{username}")
async def get_instagram_profile(
    username: str,
    current_user: User = Depends(get_current_user)
):
    """Busca um perfil público do Instagram usando a conta conectada do usuário."""
    try:
        unipile_service = get_unipile_app_service()
        
        # Busca a conta Instagram conectada do usuário para autenticar a chamada
        user_account = await get_user_instagram_account(current_user.id)
        
        if not user_account or not user_account.get("account_id"):
            raise HTTPException(status_code=400, detail="Nenhuma conta Instagram conectada. Conecte uma conta primeiro.")
        
        # No SDK atual, get_instagram_profile não aceita username, ele pega o do próprio perfil.
        # Se a intenção é buscar QUALQUER perfil, precisaríamos de outro método no wrapper/node.
        # Assumindo por agora que queremos o perfil do próprio usuário conectado:
        profile_result = await unipile_service.get_instagram_profile(user_account["account_id"])
        
        if profile_result and profile_result.get("success"):
            return {
                "success": True,
                "profile": profile_result.get("data")
            }
        else:
            error_detail = profile_result.get("error") if profile_result else "Perfil não encontrado"
            raise HTTPException(status_code=404, detail=error_detail)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 