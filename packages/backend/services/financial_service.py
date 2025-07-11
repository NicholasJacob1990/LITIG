from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List, Optional

from ..config import get_supabase_client
from supabase.client import Client
from fastapi import Depends

class FinancialDashboard(BaseModel):
    current_month_earnings: float
    quarterly_earnings: float
    total_earnings: float
    pending_receivables: float

class PaymentRecord(BaseModel):
    id: UUID
    case_id: Optional[UUID]
    case_title: Optional[str]
    net_amount: float
    fee_type: str
    paid_at: Optional[datetime]
    status: str

class FinancialService:
    def __init__(self, supabase: Client = Depends(get_supabase_client)):
        self.supabase = supabase

    async def get_dashboard_data(self, lawyer_id: UUID) -> FinancialDashboard:
        result = await self.supabase.rpc('get_lawyer_financial_metrics', {'lawyer_uuid': str(lawyer_id)}).execute()
        return FinancialDashboard(**result.data[0]) if result.data else FinancialDashboard(
            current_month_earnings=0, quarterly_earnings=0, total_earnings=0, pending_receivables=0
        )

    async def get_payment_history(self, lawyer_id: UUID, page: int, limit: int) -> List[PaymentRecord]:
        offset = (page - 1) * limit
        result = await self.supabase.table('lawyer_payments').select('*').eq('lawyer_id', str(lawyer_id)).order('paid_at', desc=True).range(offset, offset + limit - 1).execute()
        return [PaymentRecord(**record) for record in result.data] if result.data else [] 