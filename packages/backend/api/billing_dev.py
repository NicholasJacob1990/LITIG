"""
Endpoints de desenvolvimento para testar sistema de billing
Permite simular fluxos do Stripe sem chaves reais
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import uuid
from datetime import datetime, timedelta
import asyncio

from config.development import (
    MockStripeService, 
    MockStripeConfig, 
    DevelopmentUtils,
    is_development
)
from services.stripe_billing_service import StripeBillingService
from core.dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix="/billing/dev", tags=["billing-development"])

# Schemas para desenvolvimento
class MockCheckoutRequest(BaseModel):
    target_plan: str
    entity_type: str
    entity_id: str

class MockWebhookRequest(BaseModel):
    event_type: str
    session_id: str
    entity_type: str
    entity_id: str
    target_plan: str

class MockPaymentSimulation(BaseModel):
    session_id: str
    success: bool = True
    delay_seconds: int = 2

# Instância do serviço mock
mock_service = MockStripeService()


@router.get("/config")
async def get_development_config():
    """Retorna configuração de desenvolvimento"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    return {
        "environment": "development",
        "stripe_config": {
            "mock_price_ids": MockStripeConfig.MOCK_PRICE_IDS,
            "frontend_url": MockStripeConfig.FRONTEND_URL,
            "api_base_url": MockStripeConfig.API_BASE_URL,
            "success_url": MockStripeConfig.SUCCESS_URL,
            "cancel_url": MockStripeConfig.CANCEL_URL,
        },
        "entity_plans": MockStripeConfig.ENTITY_PLANS,
    }


@router.post("/mock-checkout")
async def create_mock_checkout(
    request: MockCheckoutRequest,
    current_user = Depends(get_current_user)
):
    """Cria uma sessão de checkout mockada"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    try:
        # Gerar URLs com deep links
        success_url = MockStripeConfig.get_success_url(
            session_id="mock_session", 
            plan_id=request.target_plan
        )
        cancel_url = MockStripeConfig.get_cancel_url(session_id="mock_session")
        
        # Criar sessão mockada
        session_data = await mock_service.create_checkout_session(
            target_plan=request.target_plan,
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            success_url=success_url,
            cancel_url=cancel_url
        )
        
        return {
            "status": "success",
            "message": "Sessão de checkout mockada criada",
            "data": session_data,
            "instructions": {
                "frontend": f"Abra {session_data['checkout_url']} para simular checkout",
                "mobile": f"Use deep link {success_url} para simular sucesso",
                "webhook": f"Use /billing/dev/simulate-webhook para simular eventos"
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao criar checkout mock: {str(e)}")


@router.post("/simulate-webhook")
async def simulate_webhook_event(
    request: MockWebhookRequest,
    supabase = Depends(get_supabase_client)
):
    """Simula eventos de webhook do Stripe"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    try:
        # Gerar evento mockado
        event_data = await mock_service.simulate_webhook_event(
            event_type=request.event_type,
            session_id=request.session_id,
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            target_plan=request.target_plan
        )
        
        # Processar evento através do serviço real de billing
        billing_service = StripeBillingService(supabase=supabase)
        
        if request.event_type == 'customer.subscription.created':
            await billing_service.handle_subscription_created(event_data)
        elif request.event_type == 'checkout.session.completed':
            # Processar checkout completo (se houver handler específico)
            pass
        
        return {
            "status": "success",
            "message": f"Evento {request.event_type} simulado com sucesso",
            "event_data": event_data,
            "processed": True
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao simular webhook: {str(e)}")


@router.post("/simulate-payment")
async def simulate_payment_flow(
    request: MockPaymentSimulation,
    supabase = Depends(get_supabase_client)
):
    """Simula fluxo completo de pagamento com delay"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    try:
        # Extrair informações do session_id
        session_parts = request.session_id.split('_')
        if len(session_parts) >= 4:
            entity_type = session_parts[2]
            entity_id = session_parts[3] 
            target_plan = session_parts[4] if len(session_parts) > 4 else "VIP"
        else:
            # Fallback para dados mock
            entity_type = "client"
            entity_id = str(uuid.uuid4())
            target_plan = "VIP"
        
        # Simular delay de processamento
        if request.delay_seconds > 0:
            await asyncio.sleep(request.delay_seconds)
        
        if request.success:
            # Simular sucesso
            # 1. Checkout completed
            checkout_event = await mock_service.simulate_webhook_event(
                event_type='checkout.session.completed',
                session_id=request.session_id,
                entity_type=entity_type,
                entity_id=entity_id,
                target_plan=target_plan
            )
            
            # 2. Subscription created
            subscription_event = await mock_service.simulate_webhook_event(
                event_type='customer.subscription.created',
                session_id=request.session_id,
                entity_type=entity_type,
                entity_id=entity_id,
                target_plan=target_plan
            )
            
            # Processar através do billing service
            billing_service = StripeBillingService(supabase=supabase)
            await billing_service.handle_subscription_created(subscription_event)
            
            # Gerar deep link de sucesso
            success_url = MockStripeConfig.get_success_url(
                session_id=request.session_id,
                plan_id=target_plan
            )
            
            return {
                "status": "success",
                "message": "Pagamento simulado com sucesso",
                "deep_link": success_url,
                "events_processed": ["checkout.session.completed", "customer.subscription.created"],
                "plan_updated": target_plan,
                "entity": {"type": entity_type, "id": entity_id}
            }
        else:
            # Simular cancelamento
            cancel_url = MockStripeConfig.get_cancel_url(session_id=request.session_id)
            
            return {
                "status": "cancelled",
                "message": "Pagamento cancelado pelo usuário",
                "deep_link": cancel_url,
                "session_id": request.session_id
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao simular pagamento: {str(e)}")


@router.get("/plans/{entity_type}")
async def get_mock_plans(entity_type: str):
    """Retorna planos mockados para um tipo de entidade"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    if entity_type not in MockStripeConfig.ENTITY_PLANS:
        raise HTTPException(status_code=400, detail=f"Tipo de entidade inválido: {entity_type}")
    
    plans = []
    for plan_id, plan_info in MockStripeConfig.ENTITY_PLANS[entity_type].items():
        plans.append({
            "id": plan_id,
            "name": plan_id.title(),
            "price_monthly": plan_info["price_monthly"],
            "stripe_price_id": plan_info["stripe_price_id"],
            "features": mock_service.get_plan_features(plan_id, entity_type),
            "currency": "BRL"
        })
    
    return {
        "entity_type": entity_type,
        "plans": plans,
        "total": len(plans)
    }


@router.get("/billing-history/{entity_type}/{entity_id}")
async def get_mock_billing_history(entity_type: str, entity_id: str):
    """Retorna histórico de billing mockado"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    history = DevelopmentUtils.get_mock_billing_history(entity_type, entity_id)
    
    return {
        "entity_type": entity_type,
        "entity_id": entity_id,
        "billing_records": history,
        "plan_history": [
            {
                "id": str(uuid.uuid4()),
                "entity_type": entity_type,
                "entity_id": entity_id,
                "old_plan": "FREE",
                "new_plan": "FREE",
                "changed_at": "2024-01-01T00:00:00Z",
                "changed_by": entity_id
            }
        ],
        "total_records": len(history)
    }


@router.post("/test-deep-link")
async def test_deep_link_generation():
    """Testa geração de deep links"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    test_session_id = "cs_test_12345"
    test_plan_id = "VIP"
    
    return {
        "deep_links": {
            "billing_success": MockStripeConfig.get_success_url(test_session_id, test_plan_id),
            "billing_cancel": MockStripeConfig.get_cancel_url(test_session_id),
            "case_link": f"litig://case/case_12345",
            "chat_link": f"litig://chat/chat_12345"
        },
        "test_urls": {
            "frontend_checkout": f"{MockStripeConfig.FRONTEND_URL}/mock-checkout/{test_session_id}",
            "webhook_endpoint": MockStripeConfig.WEBHOOK_ENDPOINTS["billing"]
        },
        "instructions": {
            "mobile_test": "Use estes deep links no simulador/dispositivo para testar navegação",
            "web_test": "Abra as test_urls no navegador para simular checkout"
        }
    }


@router.get("/status")
async def development_status():
    """Status do ambiente de desenvolvimento"""
    if not is_development():
        raise HTTPException(status_code=404, detail="Endpoint disponível apenas em desenvolvimento")
    
    return {
        "environment": "development",
        "mock_stripe_active": True,
        "available_endpoints": [
            "/billing/dev/config",
            "/billing/dev/mock-checkout",
            "/billing/dev/simulate-webhook", 
            "/billing/dev/simulate-payment",
            "/billing/dev/plans/{entity_type}",
            "/billing/dev/billing-history/{entity_type}/{entity_id}",
            "/billing/dev/test-deep-link",
            "/billing/dev/status"
        ],
        "entity_types": list(MockStripeConfig.ENTITY_PLANS.keys()),
        "available_plans": {
            entity_type: list(plans.keys()) 
            for entity_type, plans in MockStripeConfig.ENTITY_PLANS.items()
        }
    } 