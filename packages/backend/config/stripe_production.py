"""
Stripe Production Configuration
Configurações de produção para integração Stripe com todos os planos
"""
import os
from typing import Dict, List

class StripeProductionConfig:
    """Configuração de produção para Stripe."""
    
    # Chaves Stripe (devem ser definidas como variáveis de ambiente)
    SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "sk_live_...")
    PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_live_...")
    WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_...")
    
    # Price IDs de Produção
    PRICE_IDS = {
        # Planos de Clientes
        "VIP": os.getenv("STRIPE_VIP_PRICE_ID", "price_1OVIPxxxxxxxxxxxxxxxx"),
        "ENTERPRISE": os.getenv("STRIPE_ENTERPRISE_PRICE_ID", "price_1OENTxxxxxxxxxxxxxxxx"),
        
        # Planos de Advogados
        "PRO": os.getenv("STRIPE_PRO_PRICE_ID", "price_1OPROxxxxxxxxxxxxxxxx"),
        
        # Planos de Escritórios
        "PARTNER": os.getenv("STRIPE_PARTNER_PRICE_ID", "price_1OPARxxxxxxxxxxxxxxxx"),
        "PREMIUM": os.getenv("STRIPE_PREMIUM_PRICE_ID", "price_1OPRExxxxxxxxxxxxxxxx"),
    }
    
    # URLs de Webhook
    WEBHOOK_ENDPOINTS = {
        "billing": f"{os.getenv('API_BASE_URL', 'https://api.litig.com.br')}/billing/webhooks/stripe"
    }
    
    # URLs de Redirecionamento
    FRONTEND_URLS = {
        "success": f"{os.getenv('FRONTEND_URL', 'https://app.litig.com.br')}/billing/success",
        "cancel": f"{os.getenv('FRONTEND_URL', 'https://app.litig.com.br')}/billing/cancel",
    }
    
    # Configuração de Planos por Entidade
    ENTITY_PLANS = {
        "client": {
            "FREE": {"price_id": None, "amount_cents": 0},
            "VIP": {"price_id": PRICE_IDS["VIP"], "amount_cents": 9990},
            "ENTERPRISE": {"price_id": PRICE_IDS["ENTERPRISE"], "amount_cents": 29990},
        },
        "lawyer": {
            "FREE": {"price_id": None, "amount_cents": 0},
            "PRO": {"price_id": PRICE_IDS["PRO"], "amount_cents": 14990},
        },
        "firm": {
            "FREE": {"price_id": None, "amount_cents": 0},
            "PARTNER": {"price_id": PRICE_IDS["PARTNER"], "amount_cents": 49990},
            "PREMIUM": {"price_id": PRICE_IDS["PREMIUM"], "amount_cents": 99990},
        }
    }
    
    # Eventos de Webhook para Escutar
    WEBHOOK_EVENTS = [
        "customer.subscription.created",
        "customer.subscription.updated", 
        "customer.subscription.deleted",
        "invoice.payment_succeeded",
        "invoice.payment_failed",
        "checkout.session.completed",
        "customer.created",
        "customer.updated",
    ]
    
    # Configurações de Retry
    WEBHOOK_RETRY_CONFIG = {
        "max_retries": 3,
        "retry_delay": 5,  # segundos
        "exponential_backoff": True,
    }
    
    @classmethod
    def get_price_id(cls, plan: str) -> str:
        """Retorna o Price ID do Stripe para um plano."""
        return cls.PRICE_IDS.get(plan, "")
    
    @classmethod
    def get_plan_amount(cls, entity_type: str, plan: str) -> int:
        """Retorna o valor em centavos para um plano."""
        entity_plans = cls.ENTITY_PLANS.get(entity_type, {})
        plan_config = entity_plans.get(plan, {})
        return plan_config.get("amount_cents", 0)
    
    @classmethod
    def validate_plan_for_entity(cls, entity_type: str, plan: str) -> bool:
        """Valida se um plano é válido para um tipo de entidade."""
        entity_plans = cls.ENTITY_PLANS.get(entity_type, {})
        return plan in entity_plans
    
    @classmethod
    def get_webhook_url(cls, endpoint_type: str = "billing") -> str:
        """Retorna a URL do webhook para um tipo específico."""
        return cls.WEBHOOK_ENDPOINTS.get(endpoint_type, "")
    
    @classmethod
    def get_success_url(cls, entity_type: str, entity_id: str) -> str:
        """Retorna URL de sucesso personalizada."""
        base_url = cls.FRONTEND_URLS["success"]
        return f"{base_url}?entity_type={entity_type}&entity_id={entity_id}"
    
    @classmethod
    def get_cancel_url(cls, entity_type: str, entity_id: str) -> str:
        """Retorna URL de cancelamento personalizada."""
        base_url = cls.FRONTEND_URLS["cancel"]
        return f"{base_url}?entity_type={entity_type}&entity_id={entity_id}"


# Configurações específicas de produção
PRODUCTION_CONFIG = {
    "stripe": StripeProductionConfig,
    "environment": "production",
    "debug": False,
    "log_level": "INFO",
    "monitoring": {
        "enabled": True,
        "metrics_endpoint": "/metrics",
        "health_check_endpoint": "/health",
    }
}

# Script de configuração de webhooks
WEBHOOK_SETUP_SCRIPT = """
# Script para configurar webhooks no Stripe Dashboard

1. Acesse: https://dashboard.stripe.com/webhooks
2. Clique em "Add endpoint"
3. URL do endpoint: {webhook_url}
4. Eventos para escutar:
   - customer.subscription.created
   - customer.subscription.updated
   - customer.subscription.deleted
   - invoice.payment_succeeded
   - invoice.payment_failed
   - checkout.session.completed
   - customer.created
   - customer.updated

5. Copie o Webhook Secret (whsec_...) para STRIPE_WEBHOOK_SECRET
6. Configure Rate Limiting para 100 requests/min
7. Configure Retry Logic com 3 tentativas
""".format(webhook_url=StripeProductionConfig.get_webhook_url()) 