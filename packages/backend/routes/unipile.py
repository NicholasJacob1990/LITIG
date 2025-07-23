# -*- coding: utf-8 -*-
"""
Unipile Routes - Endpoints específicos para integração Unipile
============================================================

Endpoints para configuração, teste e monitoramento da integração
com a API do Unipile para dados de comunicação profissional.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import JSONResponse
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging

from backend.services.unipile_app_service import get_unipile_app_service
from backend.auth import get_current_user

router = APIRouter(prefix="/api/v1/unipile", tags=["unipile"])
logger = logging.getLogger(__name__)


@router.get("/health")
async def health_check():
    """
    Verifica saúde da conexão com Unipile usando o SDK oficial.
    
    Returns:
        Status da conexão e informações de configuração
    """
    try:
        unipile_service = get_unipile_app_service()
        health_data = await unipile_service.health_check()
        
        return JSONResponse(
            status_code=200 if health_data["status"] == "healthy" else 503,
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
    Lista todas as contas conectadas no Unipile usando o SDK oficial.
    
    Baseado em: https://developer.unipile.com/reference/accountscontroller_listaccounts
    """
    try:
        unipile_service = get_unipile_app_service()
        accounts = await unipile_service.list_accounts()
        
        return {
            "accounts": [
                {
                    "id": acc.id,
                    "provider": acc.provider,
                    "email": acc.email,
                    "status": acc.status,
                    "last_sync": acc.last_sync.isoformat() if acc.last_sync else None
                }
                for acc in accounts
            ],
            "total": len(accounts),
            "using_sdk": True,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro ao listar contas Unipile via SDK: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/profile/{email}")
async def get_profile(
    email: str,
    current_user = Depends(get_current_user)
):
    """
    Busca perfil de usuário por email.
    """
    try:
        unipile_service = get_unipile_app_service()
        profile = await unipile_service.get_profile_by_email(email)
        
        if not profile:
            raise HTTPException(status_code=404, detail="Perfil não encontrado")
        
        return {
            "profile": {
                "provider_id": profile.provider_id,
                "provider": profile.provider,
                "name": profile.name,
                "email": profile.email,
                "profile_data": profile.profile_data,
                "last_activity": profile.last_activity.isoformat() if profile.last_activity else None
            },
            "timestamp": datetime.now().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil {email}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/lawyer/{oab_number}/communication")
async def get_lawyer_communication_data(
    oab_number: str,
    email: Optional[str] = Query(None, description="Email do advogado (opcional)"),
    current_user = Depends(get_current_user)
):
    """
    Busca dados de comunicação para um advogado específico.
    """
    try:
        unipile_service = get_unipile_app_service()
        data, transparency = await unipile_service.get_communication_data(
            oab_number=oab_number,
            email=email
        )
        
        if not data:
            return {
                "message": "Nenhum dado de comunicação encontrado",
                "transparency": transparency.to_dict(),
                "timestamp": datetime.now().isoformat()
            }
        
        return {
            "data": data,
            "transparency": transparency.to_dict(),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro ao buscar dados de comunicação para OAB {oab_number}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/test-integration")
async def test_integration(
    test_email: str = Query(..., description="Email para teste"),
    current_user = Depends(get_current_user)
):
    """
    Testa integração completa com Unipile.
    """
    try:
        unipile_service = get_unipile_app_service()
        
        # 1. Health check
        health = await unipile_service.health_check()
        
        # 2. Listar contas
        accounts = await unipile_service.list_accounts()
        
        # 3. Buscar perfil de teste
        profile = await unipile_service.get_profile_by_email(test_email)
        
        # 4. Buscar dados de comunicação
        comm_data, transparency = await unipile_service.get_communication_data(
            oab_number="TEST123",
            email=test_email
        )
        
        return {
            "test_results": {
                "health_check": health,
                "accounts_found": len(accounts),
                "profile_found": profile is not None,
                "communication_data_found": comm_data is not None,
                "transparency": transparency.to_dict() if transparency else None
            },
            "details": {
                "accounts": [acc.provider for acc in accounts],
                "profile": {
                    "name": profile.name,
                    "provider": profile.provider
                } if profile else None,
                "communication_score": comm_data.get("communication_score", 0) if comm_data else 0
            },
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro no teste de integração: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/config")
async def get_configuration(current_user = Depends(get_current_user)):
    """
    Retorna configuração atual do Unipile.
    """
    try:
        unipile_service = get_unipile_app_service()
        config_data = await unipile_service.get_configuration()
        
        return {
            "configuration": config_data,
            "using_app_service": True,
            "service_layer": "UnipileAppService with CompatibilityLayer",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erro ao obter configuração: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sync-lawyer/{oab_number}")
async def sync_lawyer_data(
    oab_number: str,
    force_refresh: bool = Query(False, description="Forçar atualização dos dados"),
    current_user = Depends(get_current_user)
):
    """
    Sincroniza dados de um advogado específico com Unipile.
    """
    try:
        from backend.services.hybrid_legal_data_service import HybridLegalDataService
        
        hybrid_service = HybridLegalDataService()
        
        # Buscar dados híbridos incluindo Unipile
        hybrid_data = await hybrid_service.get_lawyer_data(
            lawyer_id=f"oab_{oab_number}",
            oab_number=oab_number
        )
        
        if not hybrid_data:
            raise HTTPException(status_code=404, detail="Dados não encontrados")
        
        # Filtrar transparência do Unipile
        unipile_transparency = [
            t for t in hybrid_data.data_transparency 
            if t.source.value == "unipile"
        ]
        
        return {
            "sync_result": {
                "oab_number": oab_number,
                "name": hybrid_data.name,
                "unipile_data_found": len(unipile_transparency) > 0,
                "transparency": [t.to_dict() for t in unipile_transparency],
                "total_sources": len(hybrid_data.data_transparency)
            },
            "timestamp": datetime.now().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao sincronizar dados do advogado {oab_number}: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 


# 🆕 NOVOS ENDPOINTS PARA REDES SOCIAIS

@router.post("/connect-instagram")
async def connect_instagram(
    credentials: dict,
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
        unipile_service = get_unipile_app_service()
        result = await unipile_service.connect_instagram_simple(
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
            
    except Exception as e:
        logger.error(f"Erro ao conectar Instagram: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/connect-facebook")
async def connect_facebook(
    credentials: dict,
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
        unipile_service = get_unipile_app_service()
        result = await unipile_service.connect_facebook_simple(
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
        unipile_service = get_unipile_app_service()
        result = await unipile_service.get_instagram_data(account_id)
        
        if result:
            return {
                "success": True,
                "instagram_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=404, detail="Perfil Instagram não encontrado")
            
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
        unipile_service = get_unipile_app_service()
        result = await unipile_service.get_facebook_data(account_id)
        
        if result:
            return {
                "success": True,
                "facebook_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=404, detail="Perfil Facebook não encontrado")
            
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
        unipile_service = get_unipile_app_service()
        
        # TODO: Buscar accounts_ids do banco baseado no lawyer_id
        # Por agora, retornar mock data para teste
        sample_accounts = {
            "linkedin": "li_sample_123",
            "instagram": "ig_sample_456", 
            "facebook": "fb_sample_789"
        }
        
        result = await unipile_service.get_social_score(sample_accounts)
        
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
    platforms: dict,
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
        unipile_service = get_unipile_app_service()
        
        platforms_data = platforms.get("platforms", {})
        result = await unipile_service.get_social_score(platforms_data)
        
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
            
    except Exception as e:
        logger.error(f"Erro ao sincronizar dados sociais para {lawyer_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 


@router.post("/connect-linkedin")
async def connect_linkedin(
    credentials: dict,
    current_user = Depends(get_current_user)
):
    """
    Conecta uma conta do LinkedIn usando o SDK oficial.
    
    Body:
        {
            "username": "seu_email_linkedin",
            "password": "sua_senha_linkedin"
        }
    """
    try:
        unipile_service = get_unipile_app_service()
        
        username = credentials.get("username")
        password = credentials.get("password")
        
        if not username or not password:
            raise HTTPException(status_code=400, detail="Username e password são obrigatórios")
        
        result = await unipile_service.connect_linkedin(username, password)
        
        if result:
            return {
                "success": True,
                "message": "Conta LinkedIn conectada com sucesso",
                "account_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=400, detail="Falha ao conectar conta LinkedIn")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao conectar LinkedIn: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/connect-email")
async def connect_email(
    email_data: dict,
    current_user = Depends(get_current_user)
):
    """
    Conecta uma conta de email (Gmail/Outlook) usando o SDK oficial.
    
    Body:
        {
            "provider": "gmail" | "outlook",
            "email": "seu_email@gmail.com",
            "credentials": {
                "password": "sua_senha",
                // outros campos específicos do provedor
            }
        }
    """
    try:
        unipile_service = get_unipile_app_service()
        
        provider = email_data.get("provider")
        email = email_data.get("email")
        credentials = email_data.get("credentials", {})
        
        if not provider or not email:
            raise HTTPException(status_code=400, detail="Provider e email são obrigatórios")
        
        result = await unipile_service.connect_email(provider, email, credentials)
        
        if result:
            return {
                "success": True,
                "message": f"Conta {provider} conectada com sucesso",
                "account_data": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=400, detail=f"Falha ao conectar conta {provider}")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao conectar email: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/emails/{account_id}")
async def list_emails(
    account_id: str,
    limit: int = Query(50, description="Número máximo de emails a retornar"),
    current_user = Depends(get_current_user)
):
    """
    Lista emails de uma conta específica usando o SDK oficial.
    """
    try:
        unipile_service = get_unipile_app_service()
        
        options = {"limit": limit}
        emails = await unipile_service.list_emails(account_id, options)
        
        return {
            "emails": emails,
            "total": len(emails),
            "account_id": account_id,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro ao listar emails: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send-email")
async def send_email(
    email_data: dict,
    current_user = Depends(get_current_user)
):
    """
    Envia um email usando o SDK oficial.
    
    Body:
        {
            "account_id": "id_da_conta",
            "to": "destinatario@email.com",
            "subject": "Assunto do email",
            "body": "Corpo do email"
        }
    """
    try:
        unipile_service = get_unipile_app_service()
        
        account_id = email_data.get("account_id")
        if not account_id:
            raise HTTPException(status_code=400, detail="account_id é obrigatório")
        
        result = await unipile_service.send_email(account_id, email_data)
        
        if result:
            return {
                "success": True,
                "message": "Email enviado com sucesso",
                "result": result,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=400, detail="Falha ao enviar email")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao enviar email: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/company-profile/{account_id}/{identifier}")
async def get_company_profile(
    account_id: str,
    identifier: str,
    current_user = Depends(get_current_user)
):
    """
    Recupera o perfil de uma empresa no LinkedIn usando o SDK oficial.
    
    Args:
        account_id: ID da conta LinkedIn conectada
        identifier: Identificador da empresa (ex: "Unipile")
    """
    try:
        unipile_service = get_unipile_app_service()
        
        profile = await unipile_service.get_company_profile(account_id, identifier)
        
        if profile:
            return {
                "success": True,
                "company_profile": profile,
                "account_id": account_id,
                "identifier": identifier,
                "timestamp": datetime.now().isoformat()
            }
        else:
            raise HTTPException(status_code=404, detail="Perfil da empresa não encontrado")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil da empresa: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 