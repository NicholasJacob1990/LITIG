# packages/backend/routes/outlook.py

from fastapi import APIRouter, Depends, HTTPException, Body
from pydantic import BaseModel
from typing import Optional

# Supondo que essas funções de ajuda e dependências existam e sejam semelhantes a outras rotas
from backend.services.unipile_app_service import get_unipile_app_service
from backend.auth import get_current_user
from backend.models.user import User
from backend.database import (
    save_user_social_account,
    get_user_social_account
)


router = APIRouter(prefix="/api/v1/outlook", tags=["outlook"])

class OutlookConnectionRequest(BaseModel):
    # O Outlook geralmente usa OAuth2, então o fluxo pode não ser usuário/senha.
    # Por agora, vamos assumir que o frontend lida com o fluxo OAuth e nos envia um código de autorização.
    # Se o Unipile SDK abstrair isso, o corpo pode ser diferente.
    # Por simplicidade inicial, vamos modelar um fluxo de token/código.
    auth_code: Optional[str] = None
    access_token: Optional[str] = None


@router.post("/connect")
async def connect_outlook_account(
    # request: OutlookConnectionRequest, # O corpo pode não ser necessário se o Unipile usar um fluxo de redirecionamento.
    current_user: User = Depends(get_current_user)
):
    """
    Conecta uma conta Outlook (Email & Calendário) do usuário via Unipile.
    O Unipile SDK para Outlook provavelmente usa um fluxo OAuth2.
    Este endpoint pode ser o callback de redirecionamento ou iniciar o fluxo.
    """
    unipile_service = get_unipile_app_service()
    
    try:
        # A chamada no service pode precisar iniciar um fluxo OAuth
        # ou completar um com um código de autorização.
        # Exemplo:
        account_details = await unipile_service.connect_outlook() # Esta função precisará ser criada.

        if account_details and account_details.get("success"):
            account = account_details.get("data", {})
            
            # Salvar a associação da conta no nosso banco de dados
            await save_user_social_account(
                user_id=current_user.id,
                provider="outlook",
                account_id=account.get("id"),
                username=account.get("email"), # O email do usuário é um bom username
                social_data=account
            )

            return {
                "success": True,
                "message": "Conta Outlook conectada com sucesso. A sincronização de e-mails e calendário começará em breve.",
                "account_id": account.get("id")
            }
        else:
            error_message = account_details.get("error", "Falha ao conectar conta Outlook.")
            raise HTTPException(
                status_code=400,
                detail=error_message
            )

    except Exception as e:
        # Log do erro aqui seria uma boa prática
        raise HTTPException(status_code=500, detail=f"Um erro interno ocorreu: {str(e)}")

@router.get("/check-connection")
async def check_outlook_connection(current_user: User = Depends(get_current_user)):
    """Verifica se o usuário já tem uma conta Outlook conectada."""
    account = await get_user_social_account(user_id=current_user.id, provider="outlook")
    if account:
        return {"connected": True, "account": account}
    return {"connected": False} 