"""
Billing API endpoints for Stripe integration
Handles checkout sessions, webhooks, and plan management for all entity types
"""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
import stripe
import hmac
import hashlib
import json
from typing import Optional

from services.stripe_billing_service import StripeBillingService
from dependencies.auth import get_current_user

router = APIRouter(prefix="/billing", tags=["billing"])

billing_service = StripeBillingService()


class CreateCheckoutRequest(BaseModel):
    target_plan: str
    entity_type: str  # 'client', 'lawyer', 'firm'
    entity_id: str
    success_url: str
    cancel_url: str


class CheckoutResponse(BaseModel):
    checkout_url: str
    session_id: str


@router.post("/create-checkout", response_model=CheckoutResponse)
async def create_checkout_session(
    request: CreateCheckoutRequest,
    current_user: dict = Depends(get_current_user)
):
    """Create Stripe checkout session for plan upgrade."""
    try:
        # Validate plan for entity type
        valid_plans = {
            "client": ["VIP", "ENTERPRISE"],
            "lawyer": ["PRO"],
            "firm": ["PARTNER", "PREMIUM"]
        }
        
        if request.entity_type not in valid_plans:
            raise HTTPException(status_code=400, detail="Invalid entity type")
        
        if request.target_plan not in valid_plans[request.entity_type]:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid plan {request.target_plan} for {request.entity_type}"
            )
        
        checkout_url = await billing_service.create_checkout_session(
            user_id=current_user["id"],
            target_plan=request.target_plan,
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            success_url=request.success_url,
            cancel_url=request.cancel_url
        )
        
        return CheckoutResponse(
            checkout_url=checkout_url,
            session_id=checkout_url.split("/")[-1]  # Extract session ID
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/current-plan/{entity_type}/{entity_id}")
async def get_current_plan(
    entity_type: str,
    entity_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get entity's current billing plan."""
    try:
        if entity_type not in ["client", "lawyer", "firm"]:
            raise HTTPException(status_code=400, detail="Invalid entity type")
        
        # Get current plan from database based on entity type
        current_plan = await _get_entity_plan(entity_type, entity_id)
        
        return {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "current_plan": current_plan,
            "plan_features": billing_service.get_plan_features(current_plan, entity_type)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/webhooks/stripe", status_code=status.HTTP_200_OK)
async def stripe_webhook(request: Request):
    """Handle Stripe webhooks for subscription events."""
    try:
        payload = await request.body()
        sig_header = request.headers.get('stripe-signature')
        
        if not sig_header:
            raise HTTPException(status_code=400, detail="Missing Stripe signature")
        
        # Verify webhook signature
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, billing_service.STRIPE_WEBHOOK_SECRET
            )
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid payload")
        except stripe.error.SignatureVerificationError:
            raise HTTPException(status_code=400, detail="Invalid signature")
        
        # Handle different event types
        if event['type'] == 'customer.subscription.created':
            await billing_service.handle_subscription_created(event)
        elif event['type'] == 'customer.subscription.deleted':
            await billing_service.handle_subscription_cancelled(event)
        elif event['type'] == 'invoice.payment_failed':
            await billing_service.handle_invoice_payment_failed(event)
        elif event['type'] == 'checkout.session.completed':
            await _handle_checkout_completed(event)
        
        return {"status": "success"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Webhook error: {str(e)}")


@router.get("/plans/{entity_type}")
async def get_available_plans(entity_type: str):
    """Get all available billing plans for specific entity type."""
    try:
        if entity_type not in ["client", "lawyer", "firm"]:
            raise HTTPException(status_code=400, detail="Invalid entity type")
        
        plans_data = {
            "client": [
                {
                    "id": "FREE",
                    "name": "Gratuito",
                    "price_monthly": 0,
                    "features": billing_service.get_plan_features("FREE", "client"),
                    "description": "Plano básico para explorar a plataforma"
                },
                {
                    "id": "VIP",
                    "name": "VIP",
                    "price_monthly": 99.90,
                    "features": billing_service.get_plan_features("VIP", "client"),
                    "description": "Serviço concierge e priorização"
                },
                {
                    "id": "ENTERPRISE",
                    "name": "Enterprise",
                    "price_monthly": 299.90,
                    "features": billing_service.get_plan_features("ENTERPRISE", "client"),
                    "description": "SLA corporativo e suporte dedicado"
                }
            ],
            "lawyer": [
                {
                    "id": "FREE",
                    "name": "Gratuito",
                    "price_monthly": 0,
                    "features": billing_service.get_plan_features("FREE", "lawyer"),
                    "description": "Plano básico para começar"
                },
                {
                    "id": "PRO",
                    "name": "PRO",
                    "price_monthly": 149.90,
                    "features": billing_service.get_plan_features("PRO", "lawyer"),
                    "description": "Para advogados que querem destaque e casos premium"
                }
            ],
            "firm": [
                {
                    "id": "FREE",
                    "name": "Gratuito",
                    "price_monthly": 0,
                    "features": billing_service.get_plan_features("FREE", "firm"),
                    "description": "Plano básico para escritórios pequenos"
                },
                {
                    "id": "PARTNER",
                    "name": "Partner",
                    "price_monthly": 499.90,
                    "features": billing_service.get_plan_features("PARTNER", "firm"),
                    "description": "Para escritórios que buscam crescimento"
                },
                {
                    "id": "PREMIUM",
                    "name": "Premium",
                    "price_monthly": 999.90,
                    "features": billing_service.get_plan_features("PREMIUM", "firm"),
                    "description": "Máxima visibilidade e recursos empresariais"
                }
            ]
        }
        
        return {
            "entity_type": entity_type,
            "plans": plans_data[entity_type]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/billing-history/{entity_type}/{entity_id}")
async def get_billing_history(
    entity_type: str,
    entity_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get billing history for an entity."""
    try:
        if entity_type not in ["client", "lawyer", "firm"]:
            raise HTTPException(status_code=400, detail="Invalid entity type")
        
        # Get billing records from database
        billing_records = await _get_billing_records(entity_type, entity_id, current_user["id"])
        plan_history = await _get_plan_history(entity_type, entity_id, current_user["id"])
        
        return {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "billing_records": billing_records,
            "plan_history": plan_history
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def _handle_checkout_completed(event):
    """Handle successful checkout completion."""
    session = event['data']['object']
    
    # Extract metadata
    user_id = session['metadata'].get('user_id')
    target_plan = session['metadata'].get('target_plan')
    entity_type = session['metadata'].get('entity_type')
    entity_id = session['metadata'].get('entity_id')
    
    if user_id and target_plan and entity_type and entity_id:
        # The actual subscription creation will trigger another webhook
        # This is just for immediate UI feedback
        pass


async def _get_entity_plan(entity_type: str, entity_id: str) -> str:
    """Get current plan for any entity type."""
    try:
        supabase = billing_service.supabase
        
        if entity_type == "client":
            result = supabase.table("profiles").select("plan").eq("id", entity_id).single().execute()
        elif entity_type == "lawyer":
            result = supabase.table("lawyers").select("plan").eq("id", entity_id).single().execute()
        elif entity_type == "firm":
            result = supabase.table("law_firms").select("plan").eq("id", entity_id).single().execute()
        else:
            return "FREE"
        
        return result.data.get("plan", "FREE") if result.data else "FREE"
        
    except Exception:
        return "FREE"


async def _get_billing_records(entity_type: str, entity_id: str, user_id: str) -> list:
    """Get billing records for entity."""
    try:
        supabase = billing_service.supabase
        result = supabase.table("billing_records")\
            .select("*")\
            .eq("entity_type", entity_type)\
            .eq("entity_id", entity_id)\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .execute()
        
        return result.data if result.data else []
        
    except Exception:
        return []


async def _get_plan_history(entity_type: str, entity_id: str, user_id: str) -> list:
    """Get plan change history for entity."""
    try:
        supabase = billing_service.supabase
        result = supabase.table("plan_history")\
            .select("*")\
            .eq("entity_type", entity_type)\
            .eq("entity_id", entity_id)\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .execute()
        
        return result.data if result.data else []
        
    except Exception:
        return [] 