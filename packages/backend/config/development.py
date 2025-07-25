"""
Configuração de desenvolvimento para o sistema de billing
Permite testar todo o fluxo sem chaves reais do Stripe
"""

import os
from typing import Dict, Any, Optional
from dataclasses import dataclass

@dataclass
class MockStripeConfig:
    """Configuração mock do Stripe para desenvolvimento"""
    
    # Chaves mockadas
    SECRET_KEY = "sk_test_mock_development_key"
    PUBLISHABLE_KEY = "pk_test_mock_development_key"
    WEBHOOK_SECRET = "whsec_mock_development_webhook"
    
    # Price IDs mockados
    MOCK_PRICE_IDS = {
        # Clientes
        'VIP': 'price_mock_vip_client',
        'ENTERPRISE': 'price_mock_enterprise_client',
        
        # Advogados
        'PRO': 'price_mock_pro_lawyer',
        
        # Escritórios
        'PARTNER': 'price_mock_partner_firm',
        'PREMIUM': 'price_mock_premium_firm',
    }
    
    # URLs de desenvolvimento
    FRONTEND_URL = "http://localhost:3000"
    API_BASE_URL = "http://localhost:8080"
    
    # Webhooks mockados
    WEBHOOK_ENDPOINTS = {
        'billing': f"{API_BASE_URL}/billing/webhooks/stripe"
    }
    
    # Deep links para desenvolvimento
    SUCCESS_URL = "litig://billing/success"
    CANCEL_URL = "litig://billing/cancel"
    
    # Configuração de planos completa
    ENTITY_PLANS = {
        'client': {
            'FREE': {'price_monthly': 0, 'stripe_price_id': None},
            'VIP': {'price_monthly': 99.90, 'stripe_price_id': MOCK_PRICE_IDS['VIP']},
            'ENTERPRISE': {'price_monthly': 299.90, 'stripe_price_id': MOCK_PRICE_IDS['ENTERPRISE']},
        },
        'lawyer': {
            'FREE': {'price_monthly': 0, 'stripe_price_id': None},
            'PRO': {'price_monthly': 149.90, 'stripe_price_id': MOCK_PRICE_IDS['PRO']},
        },
        'firm': {
            'FREE': {'price_monthly': 0, 'stripe_price_id': None},
            'PARTNER': {'price_monthly': 499.90, 'stripe_price_id': MOCK_PRICE_IDS['PARTNER']},
            'PREMIUM': {'price_monthly': 999.90, 'stripe_price_id': MOCK_PRICE_IDS['PREMIUM']},
        }
    }

    @classmethod
    def get_price_id(cls, plan: str) -> Optional[str]:
        """Retorna Price ID mockado para um plano"""
        return cls.MOCK_PRICE_IDS.get(plan)
    
    @classmethod
    def get_plan_amount(cls, plan: str, entity_type: str) -> int:
        """Retorna valor em centavos para um plano"""
        entity_plans = cls.ENTITY_PLANS.get(entity_type, {})
        plan_info = entity_plans.get(plan, {})
        price_monthly = plan_info.get('price_monthly', 0)
        return int(price_monthly * 100)  # Converter para centavos
    
    @classmethod
    def get_success_url(cls, session_id: str = "mock_session", plan_id: str = "mock_plan") -> str:
        """URL de sucesso com parâmetros"""
        return f"{cls.SUCCESS_URL}?session_id={session_id}&plan_id={plan_id}"
    
    @classmethod
    def get_cancel_url(cls, session_id: str = "mock_session") -> str:
        """URL de cancelamento com parâmetros"""
        return f"{cls.CANCEL_URL}?session_id={session_id}"


class MockStripeService:
    """Serviço mock do Stripe para desenvolvimento"""
    
    def __init__(self):
        self.config = MockStripeConfig()
    
    async def create_checkout_session(
        self,
        target_plan: str,
        entity_type: str,
        entity_id: str,
        success_url: str,
        cancel_url: str
    ) -> Dict[str, Any]:
        """Simula criação de sessão do Stripe"""
        
        # Simular dados da sessão
        mock_session_id = f"cs_mock_{entity_type}_{entity_id}_{target_plan}"
        
        # URL mock do checkout
        checkout_url = f"{self.config.FRONTEND_URL}/mock-checkout/{mock_session_id}"
        
        return {
            'session_id': mock_session_id,
            'checkout_url': checkout_url,
            'client_secret': f"cs_mock_secret_{mock_session_id}",
            'customer_id': f"cus_mock_{entity_id}",
            'amount': self.config.get_plan_amount(target_plan, entity_type),
            'currency': 'brl',
            'metadata': {
                'entity_type': entity_type,
                'entity_id': entity_id,
                'target_plan': target_plan,
                'success_url': success_url,
                'cancel_url': cancel_url,
            }
        }
    
    async def simulate_webhook_event(
        self,
        event_type: str,
        session_id: str,
        entity_type: str,
        entity_id: str,
        target_plan: str
    ) -> Dict[str, Any]:
        """Simula eventos de webhook do Stripe"""
        
        mock_subscription_id = f"sub_mock_{entity_id}_{target_plan}"
        
        if event_type == 'checkout.session.completed':
            return {
                'id': f"evt_mock_{session_id}",
                'type': event_type,
                'data': {
                    'object': {
                        'id': session_id,
                        'mode': 'subscription',
                        'status': 'complete',
                        'customer': f"cus_mock_{entity_id}",
                        'subscription': mock_subscription_id,
                        'metadata': {
                            'entity_type': entity_type,
                            'entity_id': entity_id,
                            'target_plan': target_plan,
                        }
                    }
                }
            }
        
        elif event_type == 'customer.subscription.created':
            return {
                'id': f"evt_mock_sub_{session_id}",
                'type': event_type,
                'data': {
                    'object': {
                        'id': mock_subscription_id,
                        'customer': f"cus_mock_{entity_id}",
                        'status': 'active',
                        'items': {
                            'data': [{
                                'price': {
                                    'unit_amount': self.config.get_plan_amount(target_plan, entity_type),
                                    'currency': 'brl'
                                }
                            }]
                        },
                        'metadata': {
                            'entity_type': entity_type,
                            'entity_id': entity_id,
                            'target_plan': target_plan,
                        }
                    }
                }
            }
        
        return {}
    
    def get_plan_features(self, plan: str, entity_type: str) -> list:
        """Retorna features mockadas para um plano"""
        features_map = {
            'client': {
                'FREE': ['Até 2 casos por mês', 'Suporte por email'],
                'VIP': ['Casos ilimitados', 'Prioridade no matching', 'Suporte prioritário'],
                'ENTERPRISE': ['Tudo do VIP', 'SLA de 1 hora', 'Account manager'],
            },
            'lawyer': {
                'FREE': ['Perfil básico', 'Até 5 casos por mês', 'Comissão 15%'],
                'PRO': ['Perfil destacado', 'Casos premium', 'Comissão 10%'],
            },
            'firm': {
                'FREE': ['Perfil básico', 'Até 3 advogados', 'Comissão 15%'],
                'PARTNER': ['Até 20 advogados', 'Dashboard admin', 'Comissão 12%'],
                'PREMIUM': ['Advogados ilimitados', 'White-label', 'Comissão 8%'],
            }
        }
        
        return features_map.get(entity_type, {}).get(plan, [])


# Função para verificar se está em desenvolvimento
def is_development() -> bool:
    """Verifica se estamos em ambiente de desenvolvimento"""
    return os.getenv('ENVIRONMENT', 'development').lower() in ['development', 'dev', 'local']


# Função para obter configuração baseada no ambiente
def get_stripe_config():
    """Retorna configuração do Stripe baseada no ambiente"""
    if is_development():
        return MockStripeConfig()
    else:
        # Importar configuração de produção quando disponível
        try:
            from .stripe_production import StripeProductionConfig
            return StripeProductionConfig()
        except ImportError:
            # Fallback para mock se produção não estiver configurada
            return MockStripeConfig()


# Instância global para desenvolvimento
mock_stripe_service = MockStripeService()


# Utilidades para desenvolvimento
class DevelopmentUtils:
    """Utilitários para desenvolvimento e testes"""
    
    @staticmethod
    def create_test_checkout_url(entity_type: str, plan: str) -> str:
        """Cria URL de teste para checkout"""
        return f"http://localhost:3000/mock-checkout?entity_type={entity_type}&plan={plan}"
    
    @staticmethod
    def simulate_successful_payment(session_id: str) -> str:
        """Simula pagamento bem-sucedido"""
        return f"litig://billing/success?session_id={session_id}&status=success"
    
    @staticmethod
    def simulate_cancelled_payment(session_id: str) -> str:
        """Simula pagamento cancelado"""
        return f"litig://billing/cancel?session_id={session_id}&status=cancelled"
    
    @staticmethod
    def get_mock_billing_history(entity_type: str, entity_id: str) -> list:
        """Retorna histórico de billing mockado"""
        return [
            {
                'id': f"bill_mock_{entity_id}_1",
                'entity_type': entity_type,
                'entity_id': entity_id,
                'plan': 'FREE',
                'amount_cents': 0,
                'status': 'active',
                'created_at': '2024-01-01T00:00:00Z',
                'billing_period_start': '2024-01-01T00:00:00Z',
                'billing_period_end': '2024-02-01T00:00:00Z',
            }
        ]


# Configuração de logging para desenvolvimento
import logging

def setup_development_logging():
    """Configura logging para desenvolvimento"""
    if is_development():
        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # Logger específico para billing
        billing_logger = logging.getLogger('billing')
        billing_logger.setLevel(logging.DEBUG)
        
        print("🧪 Ambiente de desenvolvimento configurado")
        print("📋 Usando configuração mock do Stripe")
        print(f"🔗 Deep links: {MockStripeConfig.SUCCESS_URL}")
        print(f"🌐 Frontend: {MockStripeConfig.FRONTEND_URL}")
        print(f"🔌 API: {MockStripeConfig.API_BASE_URL}")


# Auto-setup quando importado
if is_development():
    setup_development_logging() 