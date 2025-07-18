# -*- coding: utf-8 -*-
"""
Unipile Routes CORRIGIDO - Endpoints para integração Unipile com redes sociais
============================================================================

Endpoints para configuração, teste e monitoramento da integração
com a API do Unipile incluindo Instagram e Facebook.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import JSONResponse
from typing import Dict, Any, Optional
from datetime import datetime
import logging

# Import corrigido para evitar erros
try:
    from backend.services.unipile_sdk_wrapper_clean import UnipileSDKWrapper
except ImportError:
    # Fallback para o original se houver problemas
    from backend.services.unipile_sdk_wrapper import UnipileSDKWrapper

from backend.auth import get_current_user

router = APIRouter(prefix="/api/v1/unipile", tags=["unipile"])
logger = logging.getLogger(__name__)


@router.get("/health")
async def health_check():
    """
    Verifica saúde da conexão com Unipile usando o SDK oficial.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        health_data = await unipile_wrapper.health_check()
        
        return JSONResponse(
            status_code=200 if health_data.get("success") else 503,
            content=health_data
        )
    except Exception as e:
        logger.error(f"Erro no health check Unipile via SDK: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(e),
                "using_sdk": True,
                "timestamp": datetime.now().isoformat()
            }
        )


@router.get("/accounts")
async def list_accounts(current_user = Depends(get_current_user)):
    """
    Lista todas as contas conectadas no Unipile.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        accounts = await unipile_wrapper.list_accounts()
        
        return {
            "accounts": [
                {
                    "id": account.id,
                    "provider": account.provider,
                    "email": account.email,
                    "status": account.status,
                    "last_sync": account.last_sync.isoformat() if account.last_sync else None
                }
                for account in accounts
            ],
            "total": len(accounts),
            "using_sdk": True,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro ao listar contas: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ===== NOVOS ENDPOINTS PARA REDES SOCIAIS =====

@router.post("/connect-instagram")
async def connect_instagram(
    credentials: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Conecta uma conta do Instagram via Unipile SDK.
    
    Body:
    {
        "username": "usuario_instagram",
        "password": "senha_segura"
    }
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        result = await unipile_wrapper.connect_instagram_simple(
            credentials.get("username", ""),
            credentials.get("password", "")
        )
        
        if result and result.get("success"):
            return {
                "success": True,
                "message": "Instagram conectado com sucesso",
                "account_data": result.get("data", {}),
                "provider": "instagram",
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(
                status_code=400, 
                detail=f"Erro ao conectar Instagram: {result.get('error', 'Erro desconhecido') if result else 'Falha na conexão'}"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao conectar Instagram: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/connect-facebook")
async def connect_facebook(
    credentials: Dict[str, str],
    current_user = Depends(get_current_user)
):
    """
    Conecta uma conta do Facebook via Unipile SDK.
    
    Body:
    {
        "username": "usuario_facebook",
        "password": "senha_segura"
    }
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        result = await unipile_wrapper.connect_facebook_simple(
            credentials.get("username", ""),
            credentials.get("password", "")
        )
        
        if result and result.get("success"):
            return {
                "success": True,
                "message": "Facebook conectado com sucesso",
                "account_data": result.get("data", {}),
                "provider": "facebook",
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(
                status_code=400, 
                detail=f"Erro ao conectar Facebook: {result.get('error', 'Erro desconhecido') if result else 'Falha na conexão'}"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao conectar Facebook: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/instagram-profile/{account_id}")
async def get_instagram_profile(
    account_id: str,
    current_user = Depends(get_current_user)
):
    """
    Obtém perfil completo do Instagram com métricas.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        result = await unipile_wrapper.get_instagram_data(account_id)
        
        if result:
            return {
                "success": True,
                "instagram_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=404, detail="Perfil Instagram não encontrado")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao obter perfil Instagram {account_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/facebook-profile/{account_id}")
async def get_facebook_profile(
    account_id: str,
    current_user = Depends(get_current_user)
):
    """
    Obtém perfil completo do Facebook com métricas.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        result = await unipile_wrapper.get_facebook_data(account_id)
        
        if result:
            return {
                "success": True,
                "facebook_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=404, detail="Perfil Facebook não encontrado")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao obter perfil Facebook {account_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/social-profiles/{lawyer_id}")
async def get_social_profiles(
    lawyer_id: str,
    current_user = Depends(get_current_user)
):
    """
    Obtém dados consolidados de todas as redes sociais para um advogado.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        
        # TODO: Em produção, buscar accounts_ids do banco baseado no lawyer_id
        # Para teste, usar mock data
        sample_accounts = {
            "linkedin": "li_sample_123",
            "instagram": "ig_sample_456", 
            "facebook": "fb_sample_789"
        }
        
        result = await unipile_wrapper.get_social_score(sample_accounts)
        
        if result:
            return {
                "success": True,
                "lawyer_id": lawyer_id,
                "social_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            return {
                "success": False,
                "lawyer_id": lawyer_id,
                "message": "Nenhum dado social encontrado",
                "timestamp": datetime.now().isoformat()
            }
            
    except Exception as e:
        logger.error(f"Erro ao obter perfis sociais para {lawyer_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sync-social/{lawyer_id}")
async def sync_social_data(
    lawyer_id: str,
    platforms: Dict[str, Any],
    current_user = Depends(get_current_user)
):
    """
    Sincroniza dados sociais para um advogado específico.
    
    Body:
    {
        "platforms": {
            "linkedin": "account_id_linkedin",
            "instagram": "account_id_instagram",
            "facebook": "account_id_facebook"
        }
    }
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        
        platforms_data = platforms.get("platforms", {})
        result = await unipile_wrapper.get_social_score(platforms_data)
        
        # TODO: Salvar no banco de dados
        # TODO: Atualizar hybrid_legal_data_service com novos dados
        
        if result:
            return {
                "success": True,
                "lawyer_id": lawyer_id,
                "message": "Dados sociais sincronizados com sucesso",
                "social_score": result.get("social_score", {}),
                "platforms_synced": list(platforms_data.keys()),
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=400, detail="Falha na sincronização dos dados sociais")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao sincronizar dados sociais para {lawyer_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/test-sdk")
async def test_sdk_connection():
    """
    Endpoint de teste para verificar se o SDK está funcionando.
    """
    try:
        unipile_wrapper = UnipileSDKWrapper()
        
        # 1. Health check
        health = await unipile_wrapper.health_check()
        
        # 2. List accounts
        accounts = await unipile_wrapper.list_accounts()
        
        return {
            "success": True,
            "message": "SDK funcionando corretamente",
            "health_check": health,
            "accounts_found": len(accounts),
            "accounts": [
                {
                    "id": account.id,
                    "provider": account.provider,
                    "status": account.status
                }
                for account in accounts
            ],
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro no teste do SDK: {e}")
        return {
            "success": False,
            "error": str(e),
            "message": "SDK com problemas",
            "timestamp": datetime.now().isoformat()
        } 