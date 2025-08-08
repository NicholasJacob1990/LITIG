"""
Dashboard Routes
Exponha métricas resumidas para dashboards de advogados (associados) e contratantes (sócios/firmas).

URLs finais:
- /api/v1/dashboard/lawyer-stats
- /api/v1/dashboard/contractor-stats
"""

from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
import logging

from auth import get_current_user
from config import get_supabase_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/dashboard", tags=["Dashboard"])


class DashboardStats(BaseModel):
    activeCases: int
    newLeads: int
    alerts: int
    # contractor
    activeClients: int = 0
    activePartnerships: int = 0
    monthlyRevenue: float = 0.0
    conversionRate: int = 0
    # pipeline
    prospects: int = 0
    qualified: int = 0
    proposal: int = 0
    negotiation: int = 0
    closed: int = 0


async def _safe_count(query) -> int:
    try:
        resp = query.execute()
        if hasattr(resp, "count") and resp.count is not None:
            return int(resp.count)
        data = resp.data if getattr(resp, "data", None) else []
        return len(data)
    except Exception:
        return 0


@router.get("/lawyer-stats", response_model=DashboardStats)
async def get_lawyer_stats(
    current_user: Dict[str, Any] = Depends(get_current_user),
    supabase=Depends(get_supabase_client),
):
    """Dashboard para advogado associado (pessoa física).
    Retorna contagens simples baseadas em tabelas existentes; valores faltantes retornam 0.
    """
    try:
        user_id = current_user.get("id")

        # Casos ativos (não concluídos/cancelados)
        active_cases = await _safe_count(
            supabase.table("cases")
            .select("*")
            .eq("lawyer_id", user_id)
            .neq("status", "completed")
            .neq("status", "cancelled")
        )

        # Novas oportunidades (ofertas pendentes destinadas ao advogado)
        new_leads = await _safe_count(
            supabase.table("offers").select("*", count="exact").eq("lawyer_id", user_id).eq("status", "pending")
        )

        # Alertas (placeholder: 0)
        alerts = 0

        # Pipeline básico a partir de ofertas
        def offers_count(status: str) -> int:
            return supabase.table("offers").select("*", count="exact").eq("lawyer_id", user_id).eq("status", status)

        prospects = await _safe_count(offers_count("prospect"))
        qualified = await _safe_count(offers_count("qualified"))
        proposal = await _safe_count(offers_count("proposal"))
        negotiation = await _safe_count(offers_count("negotiation"))
        closed = await _safe_count(offers_count("closed"))

        # Conversão simples
        total_top = prospects + qualified
        conversion_rate = int(round((closed / total_top) * 100)) if total_top > 0 else 0

        return DashboardStats(
            activeCases=active_cases,
            newLeads=new_leads,
            alerts=alerts,
            prospects=prospects,
            qualified=qualified,
            proposal=proposal,
            negotiation=negotiation,
            closed=closed,
            conversionRate=conversion_rate,
        )
    except Exception as e:
        logger.error(f"Erro em /lawyer-stats: {e}")
        raise HTTPException(status_code=500, detail="Falha ao carregar métricas do advogado")


@router.get("/contractor-stats", response_model=DashboardStats)
async def get_contractor_stats(
    current_user: Dict[str, Any] = Depends(get_current_user),
    supabase=Depends(get_supabase_client),
):
    """Dashboard para advogado contratante/sócio (pessoa jurídica/firm vinculado).
    Usa proxies simples das tabelas para métricas de captação.
    """
    try:
        user_id = current_user.get("id")

        # Casos ativos (onde o advogado é owner ou firm admin coordena)
        active_cases = await _safe_count(
            supabase.table("cases")
            .select("*")
            .eq("owner_id", user_id)
            .neq("status", "completed")
            .neq("status", "cancelled")
        )

        # Oportunidades novas: ofertas criadas pelo usuário (ou sua firma) ainda pendentes
        new_leads = await _safe_count(
            supabase.table("offers").select("*", count="exact").eq("created_by", user_id).eq("status", "pending")
        )

        # Clientes ativos distintos (dos casos ativos)
        try:
            active_clients_resp = (
                supabase.table("cases")
                .select("client_id")
                .eq("owner_id", user_id)
                .neq("status", "completed")
                .neq("status", "cancelled")
                .execute()
            )
            active_clients = len({row["client_id"] for row in (active_clients_resp.data or []) if row.get("client_id")})
        except Exception:
            active_clients = 0

        # Parcerias ativas
        active_partnerships = await _safe_count(
            supabase.table("partnerships")
            .select("*", count="exact")
            .or_(f"creator_id.eq.{user_id},partner_id.eq.{user_id}")
            .eq("status", "active")
        )

        # Receita mensal (placeholder 0.0; integrar a financeiro quando disponível)
        monthly_revenue = 0.0

        # Pipeline consolidado do criador
        def offers_count(status: str) -> int:
            return supabase.table("offers").select("*", count="exact").eq("created_by", user_id).eq("status", status)

        prospects = await _safe_count(offers_count("prospect"))
        qualified = await _safe_count(offers_count("qualified"))
        proposal = await _safe_count(offers_count("proposal"))
        negotiation = await _safe_count(offers_count("negotiation"))
        closed = await _safe_count(offers_count("closed"))

        total_top = prospects + qualified
        conversion_rate = int(round((closed / total_top) * 100)) if total_top > 0 else 0

        return DashboardStats(
            activeCases=active_cases,
            newLeads=new_leads,
            alerts=0,
            activeClients=active_clients,
            activePartnerships=active_partnerships,
            monthlyRevenue=monthly_revenue,
            prospects=prospects,
            qualified=qualified,
            proposal=proposal,
            negotiation=negotiation,
            closed=closed,
            conversionRate=conversion_rate,
        )
    except Exception as e:
        logger.error(f"Erro em /contractor-stats: {e}")
        raise HTTPException(status_code=500, detail="Falha ao carregar métricas do contratante")


@router.get("/client-stats", response_model=DashboardStats)
async def get_client_stats(
    current_user: Dict[str, Any] = Depends(get_current_user),
    supabase=Depends(get_supabase_client),
):
    """Dashboard para cliente (PF/PJ).
    Métricas básicas derivadas das tabelas: casos do cliente e ofertas vinculadas aos seus casos.
    """
    try:
        user_id = current_user.get("id")

        # Casos ativos do cliente
        active_cases = await _safe_count(
            supabase.table("cases")
            .select("*")
            .eq("client_id", user_id)
            .neq("status", "completed")
            .neq("status", "cancelled")
        )

        # Ofertas pendentes relacionadas aos casos do cliente
        try:
            client_cases = supabase.table("cases").select("id").eq("client_id", user_id).execute().data or []
            case_ids = [row["id"] for row in client_cases if row.get("id")]
        except Exception:
            case_ids = []

        new_leads = 0
        if case_ids:
            # Conta ofertas pendentes por case_id
            total = 0
            for cid in case_ids:
                total += await _safe_count(
                    supabase.table("offers").select("*").eq("case_id", cid).eq("status", "pending")
                )
            new_leads = total

        # Pipeline simples: propostas enviadas ao cliente (por status)
        def offers_count_for_cases(status: str) -> int:
            # Soma por case ids (supabase não tem in_ no cliente python de forma trivial)
            async def _count_for_case(cid: str) -> int:
                return await _safe_count(
                    supabase.table("offers").select("*").eq("case_id", cid).eq("status", status)
                )
            return sum([
                # Not async loop; simple approximation due to SDK sync execute
                (supabase.table("offers").select("*").eq("case_id", cid).eq("status", status).execute().data or []).__len__()
                for cid in case_ids
            ])

        prospects = offers_count_for_cases("prospect") if case_ids else 0
        qualified = offers_count_for_cases("qualified") if case_ids else 0
        proposal = offers_count_for_cases("proposal") if case_ids else 0
        negotiation = offers_count_for_cases("negotiation") if case_ids else 0
        closed = offers_count_for_cases("closed") if case_ids else 0

        total_top = prospects + qualified
        conversion_rate = int(round((closed / total_top) * 100)) if total_top > 0 else 0

        return DashboardStats(
            activeCases=active_cases,
            newLeads=new_leads,
            alerts=0,
            prospects=prospects,
            qualified=qualified,
            proposal=proposal,
            negotiation=negotiation,
            closed=closed,
            conversionRate=conversion_rate,
        )
    except Exception as e:
        logger.error(f"Erro em /client-stats: {e}")
        raise HTTPException(status_code=500, detail="Falha ao carregar métricas do cliente")


