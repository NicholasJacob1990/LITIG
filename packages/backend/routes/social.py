from fastapi import APIRouter, Depends, HTTPException
from typing import Dict, Any, List

from backend.auth import get_current_user
from backend.models.user import User
# Simulação do wrapper e funções de banco de dados
from backend.services.unipile_app_service import get_unipile_app_service

router = APIRouter(prefix="/api/v1/social", tags=["social"])

# --- Funções Auxiliares (Simuladas/A Implementar) ---

async def get_user_all_social_accounts(user_id: str) -> List[Dict[str, Any]]:
    """Busca TODAS as contas sociais conectadas de um usuário no banco de dados."""
    print(f"[Simulação DB] Buscando todas as contas sociais para o usuário {user_id}")
    # Lógica de SELECT * FROM user_social_accounts WHERE user_id = :user_id
    # Retorno mockado para simular contas conectadas de Instagram e LinkedIn
    return [
        {"provider": "instagram", "account_id": "acc_mock_instagram_12345", "username": "adv_moderno"},
        {"provider": "linkedin", "account_id": "acc_mock_linkedin_67890", "username": "dr_joao_silva"},
    ]

# --- Endpoint da API ---

@router.get("/profiles/me", response_model=Dict[str, Any])
async def get_my_social_profiles(current_user: User = Depends(get_current_user)):
    """
    Retorna um consolidado de perfis e métricas sociais do usuário logado.
    Busca todas as contas conectadas e, para cada uma, obtém os dados do perfil via Unipile.
    """
    try:
        unipile_service = get_unipile_app_service()
        connected_accounts = await get_user_all_social_accounts(current_user.id)

        if not connected_accounts:
            return {"success": True, "profiles": {}, "message": "Nenhuma conta social conectada."}

        social_profiles_data = {}
        for account in connected_accounts:
            provider = account.get("provider")
            account_id = account.get("account_id")

            if not provider or not account_id:
                continue

            profile_data = None
            if provider == "instagram":
                # Utiliza a função existente para buscar o perfil do Instagram
                result = await unipile_service.get_instagram_profile(account_id)
                if result and result.get("success"):
                    profile_data = result.get("data")

            elif provider == "linkedin":
                # Utiliza a função existente para buscar o perfil do LinkedIn
                result = await unipile_service.get_linkedin_profile(account_id)
                if result and result.get("success"):
                    profile_data = result.get("data")
            
            # Adicionar lógica para outros provedores (Facebook, etc.) aqui

            if profile_data:
                # Simula um resumo de métricas chave para o frontend
                summary = {
                    "username": profile_data.get("username") or profile_data.get("public_identifier"),
                    "fullName": profile_data.get("full_name") or profile_data.get("name"),
                    "followers": profile_data.get("follower_count") or profile_data.get("connections", 0),
                    "profileUrl": profile_data.get("profile_pic_url") or profile_data.get("picture"),
                }
                social_profiles_data[provider] = summary

        return {
            "success": True,
            "profiles": social_profiles_data
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno do servidor ao buscar perfis sociais: {str(e)}") 