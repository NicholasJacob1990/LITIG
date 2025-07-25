"""
Stripe Billing Service for Plan Upgrades
Handles subscription management, payment processing, and automatic plan updates.
Extended to support all entity types: clients, lawyers, and firms.
"""
import os
import logging
from typing import Dict, Any, Optional
from datetime import datetime
import stripe
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from models.premium_criteria import Client
from database import get_async_session
from config import get_supabase_client

# Configure Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

logger = logging.getLogger(__name__)


class StripeBillingService:
    """Service for handling Stripe billing and plan upgrades for all entity types."""
    
    def __init__(self):
        self.supabase = get_supabase_client()
        
        # Complete plan to Stripe Price ID mapping
        self.plan_price_mapping = {
            # Client plans
            "VIP": os.getenv("STRIPE_VIP_PRICE_ID", "price_vip_monthly"),
            "ENTERPRISE": os.getenv("STRIPE_ENTERPRISE_PRICE_ID", "price_enterprise_monthly"),
            
            # Lawyer plans
            "PRO": os.getenv("STRIPE_PRO_PRICE_ID", "price_pro_monthly"),
            
            # Firm plans
            "PARTNER": os.getenv("STRIPE_PARTNER_PRICE_ID", "price_partner_monthly"),
            "PREMIUM": os.getenv("STRIPE_PREMIUM_PRICE_ID", "price_premium_monthly"),
        }
        
        # Plan categories
        self.client_plans = ["VIP", "ENTERPRISE"]
        self.lawyer_plans = ["PRO"]
        self.firm_plans = ["PARTNER", "PREMIUM"]
    
    async def create_checkout_session(
        self, 
        user_id: str, 
        target_plan: str,
        entity_type: str,  # 'client', 'lawyer', 'firm'
        entity_id: str,
        success_url: str,
        cancel_url: str
    ) -> str:
        """Create Stripe checkout session for plan upgrade."""
        try:
            price_id = self.plan_price_mapping.get(target_plan)
            if not price_id:
                raise ValueError(f"Invalid plan: {target_plan}")
            
            # Validate plan for entity type
            if not self._validate_plan_for_entity(target_plan, entity_type):
                raise ValueError(f"Plan {target_plan} not valid for {entity_type}")
            
            # Get or create Stripe customer
            customer_id = await self._get_or_create_stripe_customer(user_id)
            
            # Create checkout session
            session = stripe.checkout.Session.create(
                customer=customer_id,
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                mode='subscription',
                success_url=success_url,
                cancel_url=cancel_url,
                metadata={
                    'user_id': user_id,
                    'target_plan': target_plan,
                    'entity_type': entity_type,
                    'entity_id': entity_id,
                    'upgrade_timestamp': datetime.now().isoformat()
                }
            )
            
            return session.url
            
        except Exception as e:
            logger.error(f"Error creating checkout session for {entity_type} {entity_id}: {e}")
            raise
    
    async def handle_subscription_created(self, event_data: Dict[str, Any]) -> None:
        """Handle successful subscription creation."""
        try:
            subscription = event_data['data']['object']
            customer_id = subscription['customer']
            metadata = subscription.get('metadata', {})
            
            user_id = metadata.get('user_id')
            target_plan = metadata.get('target_plan')
            entity_type = metadata.get('entity_type')
            entity_id = metadata.get('entity_id')
            
            if user_id and target_plan and entity_type and entity_id:
                # Get old plan for notifications
                old_plan = await self._get_current_plan(entity_type, entity_id)
                
                # Update plan
                await self._update_entity_plan(entity_type, entity_id, target_plan, user_id)
                await self._create_billing_record(user_id, entity_type, entity_id, subscription)
                
                # Send notification
                from services.notification_service import send_plan_change_notification
                await send_plan_change_notification(
                    user_id=user_id,
                    entity_type=entity_type,
                    entity_id=entity_id,
                    old_plan=old_plan,
                    new_plan=target_plan,
                    action='upgrade',
                    amount_cents=subscription["items"]["data"][0]["price"]["unit_amount"]
                )
                
                # Track analytics
                from services.analytics_service import analytics_service
                await analytics_service.track_plan_change(
                    user_id=user_id,
                    entity_type=entity_type,
                    old_plan=old_plan,
                    new_plan=target_plan,
                    amount_cents=subscription["items"]["data"][0]["price"]["unit_amount"]
                )
                
                logger.info(f"Successfully upgraded {entity_type} {entity_id} to {target_plan}")
            
        except Exception as e:
            logger.error(f"Error handling subscription created: {e}")
            raise
    
    async def handle_subscription_cancelled(self, event_data: Dict[str, Any]) -> None:
        """Handle subscription cancellation - downgrade to FREE."""
        try:
            subscription = event_data['data']['object']
            customer_id = subscription['customer']
            
            # Find user by Stripe customer ID
            user_id = await self._get_user_by_stripe_customer(customer_id)
            if user_id:
                # Get billing record to find entity details
                billing_record = await self._get_billing_record_by_subscription(subscription['id'])
                if billing_record:
                    await self._update_entity_plan(
                        billing_record['entity_type'], 
                        billing_record['entity_id'], 
                        "FREE", 
                        user_id
                    )
                    logger.info(f"Downgraded {billing_record['entity_type']} {billing_record['entity_id']} to FREE plan")
            
        except Exception as e:
            logger.error(f"Error handling subscription cancelled: {e}")
            raise
    
    async def handle_invoice_payment_failed(self, event_data: Dict[str, Any]) -> None:
        """Handle failed payment - flag for manual review."""
        try:
            invoice = event_data['data']['object']
            customer_id = invoice['customer']
            
            user_id = await self._get_user_by_stripe_customer(customer_id)
            if user_id:
                # Get billing record to find entity details
                subscription_id = invoice['subscription']
                billing_record = await self._get_billing_record_by_subscription(subscription_id)
                if billing_record:
                    await self._flag_payment_issue(
                        user_id, 
                        billing_record['entity_type'],
                        billing_record['entity_id'],
                        invoice['id']
                    )
                    logger.warning(f"Payment failed for {billing_record['entity_type']} {billing_record['entity_id']}, flagged for review")
            
        except Exception as e:
            logger.error(f"Error handling payment failure: {e}")
            raise
    
    def _validate_plan_for_entity(self, plan: str, entity_type: str) -> bool:
        """Validate that plan is appropriate for entity type."""
        if entity_type == 'client':
            return plan in self.client_plans
        elif entity_type == 'lawyer':
            return plan in self.lawyer_plans
        elif entity_type == 'firm':
            return plan in self.firm_plans
        return False
    
    async def _update_entity_plan(self, entity_type: str, entity_id: str, new_plan: str, user_id: str) -> None:
        """Update plan for any entity type."""
        try:
            if entity_type == 'client':
                # Update profiles table
                self.supabase.table("profiles").update({
                    "plan": new_plan
                }).eq("id", entity_id).execute()
            
            elif entity_type == 'lawyer':
                # Update lawyers table
                self.supabase.table("lawyers").update({
                    "plan": new_plan
                }).eq("id", entity_id).execute()
            
            elif entity_type == 'firm':
                # Update law_firms table
                self.supabase.table("law_firms").update({
                    "plan": new_plan
                }).eq("id", entity_id).execute()
            
            # Update Supabase user metadata for JWT claims
            self.supabase.auth.admin.update_user_by_id(
                user_id,
                {"user_metadata": {"plan": new_plan}}
            )
            
            logger.info(f"Updated {entity_type} {entity_id} plan to {new_plan}")
            
        except Exception as e:
            logger.error(f"Error updating {entity_type} plan: {e}")
            raise
    
    async def _create_billing_record(self, user_id: str, entity_type: str, entity_id: str, subscription: Dict[str, Any]) -> None:
        """Create billing record for audit trail."""
        try:
            billing_data = {
                "user_id": user_id,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "stripe_subscription_id": subscription["id"],
                "plan": subscription["metadata"].get("target_plan"),
                "amount_cents": subscription["items"]["data"][0]["price"]["unit_amount"],
                "status": "active",
                "billing_period_start": datetime.fromtimestamp(subscription["current_period_start"]),
                "billing_period_end": datetime.fromtimestamp(subscription["current_period_end"]),
                "created_at": datetime.now()
            }
            
            self.supabase.table("billing_records").insert(billing_data).execute()
            
        except Exception as e:
            logger.error(f"Error creating billing record: {e}")
            # Don't raise - this is non-critical
    
    async def _get_billing_record_by_subscription(self, subscription_id: str) -> Optional[Dict[str, Any]]:
        """Get billing record by Stripe subscription ID."""
        try:
            result = self.supabase.table("billing_records").select("*").eq("stripe_subscription_id", subscription_id).single().execute()
            return result.data if result.data else None
        except:
            return None
    
    async def _flag_payment_issue(self, user_id: str, entity_type: str, entity_id: str, invoice_id: str) -> None:
        """Flag payment issue for manual review."""
        try:
            issue_data = {
                "user_id": user_id,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "issue_type": "payment_failed",
                "stripe_invoice_id": invoice_id,
                "status": "pending_review",
                "created_at": datetime.now()
            }
            
            self.supabase.table("billing_issues").insert(issue_data).execute()
            
        except Exception as e:
            logger.error(f"Error flagging payment issue: {e}")
    
    async def _get_or_create_stripe_customer(self, user_id: str) -> str:
        """Get existing Stripe customer or create new one."""
        try:
            # Check if user already has Stripe customer ID
            profile = self.supabase.table("profiles").select("stripe_customer_id, full_name").eq("user_id", user_id).single().execute()
            
            if profile.data and profile.data.get("stripe_customer_id"):
                return profile.data["stripe_customer_id"]
            
            # Create new Stripe customer
            customer = stripe.Customer.create(
                email=self._get_user_email(user_id),
                name=profile.data.get("full_name") if profile.data else None,
                metadata={"user_id": user_id}
            )
            
            # Save customer ID to database
            self.supabase.table("profiles").update({
                "stripe_customer_id": customer.id
            }).eq("user_id", user_id).execute()
            
            return customer.id
            
        except Exception as e:
            logger.error(f"Error creating Stripe customer for user {user_id}: {e}")
            raise
    
    async def _get_user_by_stripe_customer(self, customer_id: str) -> Optional[str]:
        """Get user ID by Stripe customer ID."""
        try:
            profile = self.supabase.table("profiles").select("user_id").eq("stripe_customer_id", customer_id).single().execute()
            return profile.data.get("user_id") if profile.data else None
        except:
            return None
    
    def _get_user_email(self, user_id: str) -> Optional[str]:
        """Get user email from Supabase Auth."""
        try:
            user = self.supabase.auth.admin.get_user_by_id(user_id)
            return user.user.email if user.user else None
        except:
            return None
    
    async def _get_current_plan(self, entity_type: str, entity_id: str) -> str:
        """Get current plan for an entity."""
        try:
            if entity_type == 'client':
                result = self.supabase.table("profiles").select("plan").eq("id", entity_id).single().execute()
            elif entity_type == 'lawyer':
                result = self.supabase.table("lawyers").select("plan").eq("id", entity_id).single().execute()
            elif entity_type == 'firm':
                result = self.supabase.table("law_firms").select("plan").eq("id", entity_id).single().execute()
            else:
                return "FREE"
            
            return result.data.get("plan", "FREE") if result.data else "FREE"
        except Exception:
            return "FREE"
    
    def get_plan_features(self, plan: str, entity_type: str) -> list:
        """Get features for each plan by entity type."""
        if entity_type == 'client':
            return self._get_client_plan_features(plan)
        elif entity_type == 'lawyer':
            return self._get_lawyer_plan_features(plan)
        elif entity_type == 'firm':
            return self._get_firm_plan_features(plan)
        return []
    
    def _get_client_plan_features(self, plan: str) -> list:
        """Get features for client plans."""
        features = {
            "FREE": [
                "Até 2 casos por mês",
                "Suporte por email",
                "Advogados verificados"
            ],
            "VIP": [
                "Casos ilimitados",
                "Prioridade no matching",
                "Advogados PRO exclusivos",
                "Suporte prioritário",
                "Manager dedicado"
            ],
            "ENTERPRISE": [
                "Tudo do VIP",
                "SLA de 1 hora",
                "Integração via API",
                "Relatórios customizados",
                "Suporte 24/7",
                "Account manager executivo"
            ]
        }
        return features.get(plan, [])
    
    def _get_lawyer_plan_features(self, plan: str) -> list:
        """Get features for lawyer plans."""
        features = {
            "FREE": [
                "Perfil básico",
                "Até 5 casos por mês",
                "Comissão padrão: 15%"
            ],
            "PRO": [
                "Perfil destacado",
                "Casos premium exclusivos",
                "Comissão reduzida: 10%",
                "Prioridade no matching",
                "Analytics avançado",
                "Suporte prioritário"
            ]
        }
        return features.get(plan, [])
    
    def _get_firm_plan_features(self, plan: str) -> list:
        """Get features for firm plans."""
        features = {
            "FREE": [
                "Perfil básico do escritório",
                "Até 3 advogados",
                "Comissão padrão: 15%"
            ],
            "PARTNER": [
                "Perfil destacado",
                "Até 20 advogados",
                "Comissão reduzida: 12%",
                "Dashboard administrativo",
                "Relatórios de performance",
                "API de integração"
            ],
            "PREMIUM": [
                "Tudo do Partner",
                "Advogados ilimitados",
                "Comissão reduzida: 8%",
                "White-label disponível",
                "SLA corporativo",
                "Account manager dedicado",
                "Integração ERP customizada"
            ]
        }
        return features.get(plan, []) 