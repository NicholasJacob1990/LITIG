"""
backend/services/financial_reports_service.py

Serviço para gerar relatórios e métricas financeiras para advogados.
"""
import os
import logging
from typing import Dict, Any, List
from uuid import UUID
from datetime import datetime, timedelta
from supabase import create_client, Client

# Configuração
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

logger = logging.getLogger(__name__)

class FinancialReportsService:
    """
    Serviço para calcular e fornecer métricas financeiras para advogados.
    """

    async def get_lawyer_financials(self, lawyer_id: UUID) -> Dict[str, Any]:
        """
        Calcula e retorna um dashboard financeiro para um advogado.
        """
        try:
            # Período de análise (últimos 12 meses)
            end_date = datetime.utcnow()
            start_date = end_date - timedelta(days=365)

            # Usar RPC para buscar e agregar os dados no banco
            # (Assumindo que uma função `get_lawyer_financial_summary` será criada no Supabase)
            rpc_params = {
                "p_lawyer_id": str(lawyer_id),
                "p_start_date": start_date.isoformat(),
                "p_end_date": end_date.isoformat()
            }
            
            # Simulação de dados enquanto a RPC não existe
            # Em um cenário real, a chamada RPC seria:
            # response = supabase.rpc("get_lawyer_financial_summary", rpc_params).execute()
            # summary = response.data[0] if response.data else {}
            summary = {
                "total_billed": 150000.75,
                "total_received": 135000.50,
                "active_contracts": 12,
                "avg_ticket": 12500.06,
                "monthly_billing": [
                    {"month": "2024-08", "value": 12000},
                    {"month": "2024-09", "value": 15000},
                    {"month": "2024-10", "value": 13500},
                    # ... (outros meses)
                ]
            }
            
            return summary

        except Exception as e:
            logger.error(f"Erro ao calcular métricas financeiras para o advogado {lawyer_id}: {e}")
            raise

financial_reports_service = FinancialReportsService() 