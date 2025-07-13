"""
Serviço de Matchmaking, responsável por orquestrar o ranking e as notificações.
"""
import os
import time
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv

from ..algoritmo_match import KPI, Case, Lawyer, MatchmakingAlgorithm, haversine
from ..metrics import cache_hits_total, cache_misses_total
from ..models import MatchRequest
from .cache_service_simple import simple_cache_service as cache_service
from .notify_service import send_notifications_to_lawyers
from .offer_service import create_offers_from_ranking
from supabase import Client, create_client

# --- Configuração ---
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
algo = MatchmakingAlgorithm()


async def _persist_matches(case_id: str, ranked_lawyers: List[Lawyer]):
    """Salva os matches gerados na tabela case_matches."""
    records_to_insert = []
    for lw in ranked_lawyers:
        scores = lw.scores
        records_to_insert.append({
            "case_id": case_id,
            "lawyer_id": lw.id,
            "fair_score": scores.get("fair", 0),
            "equity_score": scores.get("equity", 0),
            "raw_score": scores.get("raw", 0),
            "features": scores.get("features", {}),
            "breakdown": scores.get("delta"),
            "weights_used": scores.get("weights_used"),
            "preset_used": scores.get("preset"),
        })

    if records_to_insert:
        try:
            # Usar `upsert` para o caso de o match já existir (ex: re-ranking)
            # A constraint `unique_case_lawyer_match` será usada para o `on_conflict`.
            supabase.table("case_matches").upsert(
                records_to_insert,
                on_conflict="case_id, lawyer_id"
            ).execute()
        except Exception as e:
            # Logar o erro mas não impedir o fluxo principal
            print(f"Erro ao persistir matches: {e}")


async def find_and_notify_matches(req: MatchRequest) -> Optional[Dict[str, Any]]:
    """
    Orquestra o processo de match e agora também persiste os resultados.
    """
    # --- Cache de Matching ---
    # Busca no cache Redis
    cached_result = await cache_service.get_case_matches(req.case_id, {"preset": req.preset, "k": req.k})
    if cached_result:
        cache_hits_total.inc()
        return cached_result
    cache_misses_total.inc()

    # 1. Carregar dados do caso
    case_row = supabase.table("cases").select(
        "*").eq("id", req.case_id).single().execute().data
    if not case_row:
        return None

    case = Case(
        id=case_row["id"],
        area=case_row["area"],
        subarea=case_row["subarea"],
        urgency_h=case_row["urgency_h"],
        coords=tuple(case_row["coords"]),
        complexity=case_row.get("complexity", "MEDIUM"),
        summary_embedding=np.array(case_row["summary_embedding"], dtype=np.float32),
    )

    # --- 1.a Ajustes finos fornecidos pelo usuário ------------------------
    if getattr(req, "area", None):
        case.area = req.area  # Sobrepõe área detectada
    if getattr(req, "subarea", None):
        case.subarea = req.subarea  # Sobrepõe subárea

    # Raio geográfico customizável (default 50 km)
    radius_km = getattr(req, "radius_km", None) or 50

    # Atualiza no objeto para cálculo de G
    case.radius_km = radius_km

    # 2. Carregar advogados candidatos — tentativa de filtro geo via RPC
    try:
        rpc_params = {
            "area": case.area,
            "lat": case.coords[0],
            "lon": case.coords[1],
            "km": radius_km,
        }
        lawyer_rows = supabase.rpc("find_nearby_lawyers", rpc_params).eq("is_available", True).execute().data
    except Exception:
        # Fallback para filtro somente por área
        lawyer_rows = supabase.table("lawyers").select(
            "*").contains("tags_expertise", [case.area]).eq("is_available", True).execute().data

    candidates = [
        Lawyer(
            id=r["id"],
            nome=r["nome"],
            tags_expertise=r["tags_expertise"],
            geo_latlon=tuple(r["geo_latlon"]),
            curriculo_json=r.get("curriculo_json", {}),
            casos_historicos_embeddings=[np.array(v)
                                         for v in r.get("casos_historicos_embeddings", [])],
            kpi=KPI(**r.get("kpi", {})),
            kpi_subarea=r.get("kpi_subarea", {}),
            kpi_softskill=r.get("kpi_softskill", 0.0),
            case_outcomes=r.get("case_outcomes", [])
        ) for r in lawyer_rows
    ]

    # Aplicar exclusões solicitadas (ex: "ver outras opções")
    if getattr(req, "exclude_ids", None):
        excl_set = set(req.exclude_ids or [])
        candidates = [lw for lw in candidates if lw.id not in excl_set]

    # 3. Executar o algoritmo de ranking com preset
    top_lawyers = await algo.rank(case, candidates, top_n=req.k, preset=req.preset)

    if not top_lawyers:
        return {"case_id": case.id, "matches": []}

    # 4. Persistir os matches gerados no banco de dados (assíncrono)
    await _persist_matches(case.id, top_lawyers)

    # 5. Criar ofertas para os advogados (Fase 4 - Sinal de Interesse)
    offer_ids = await create_offers_from_ranking(case, top_lawyers)

    # 6. Enviar notificações (assíncrono, não bloqueia a resposta)
    lawyer_ids = [lw.id for lw in top_lawyers]
    notification_payload = {
        "case_id": case.id,
        "headline": f"Novo caso na área de {case.area}",
        "summary": f"Um novo caso com urgência de {case.urgency_h}h está disponível para seu perfil.",
        "offer_ids": offer_ids  # Incluir IDs das ofertas para referência
    }
    await send_notifications_to_lawyers(lawyer_ids, notification_payload)

    # 7. Persistir `last_offered_at` e formatar resposta
    now = time.time()
    supabase.table("lawyers").update(
        {"last_offered_at": now}).in_("id", lawyer_ids).execute()

    lawyer_raw_data = {r['id']: r for r in lawyer_rows}
    response = format_match_response(case, top_lawyers, lawyer_raw_data)

    # Salvar no cache Redis
    await cache_service.set_case_matches(
        req.case_id,
        response,
        filters={"preset": req.preset, "k": req.k}
    )

    return response


def format_match_response(
        case: Case, ranked_lawyers: List[Lawyer], raw_data_map: Dict) -> Dict[str, Any]:
    """Formata a resposta do endpoint de match."""
    matches_response = []
    for lw in ranked_lawyers:
        raw_data = raw_data_map.get(lw.id)
        if not raw_data:
            continue

        matches_response.append({
            "lawyer_id": lw.id,
            "nome": lw.nome,
            "fair": lw.scores.get("fair", 0),
            "equity": lw.scores.get("equity", 0),
            "features": lw.scores.get("features", {}),
            "breakdown": lw.scores.get("delta"),
            "weights_used": lw.scores.get("weights_used"),
            "preset_used": lw.scores.get("preset"),
            "avatar_url": raw_data.get("avatar_url"),
            "is_available": raw_data.get("is_available", False),
            "rating": lw.kpi.avaliacao_media,
            "distance_km": haversine(case.coords, lw.geo_latlon),
        })

    return {"case_id": case.id, "matches": matches_response}


class MatchService:
    """Classe de serviço para operações de matching."""

    def __init__(self):
        self.algo = MatchmakingAlgorithm()

    async def find_matches(self, req: MatchRequest) -> Optional[Dict[str, Any]]:
        """Encontra matches para um caso específico."""
        return await find_and_notify_matches(req)

    async def persist_matches(self, case_id: str, ranked_lawyers: List[Lawyer]):
        """Persiste matches no banco de dados."""
        return await _persist_matches(case_id, ranked_lawyers)

    async def find_partners(
        self,
        description: str,
        area=None,
        coordinates=None,
        radius_km: float = 50,
        urgency_hours: Optional[int] = None,
        limit: int = 10,
        exclude_user_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Busca parceiros jurídicos usando o algoritmo de matching.
        Adaptado para busca de parcerias (não casos específicos).
        """
        try:
            # Criar um "caso fictício" para usar o algoritmo de matching
            mock_case = Case(
                id=f"partnership_search_{int(time.time())}",
                area=area or "EMPRESARIAL",  # Default
                subarea="Parceria",
                urgency_h=urgency_hours or 48,
                coords=coordinates or (-23.5505, -46.6333),  # São Paulo default
                complexity="MEDIUM",
                summary_embedding=np.zeros(384, dtype=np.float32),  # Embedding vazio
            )
            
            # Buscar advogados candidatos
            try:
                rpc_params = {
                    "area": mock_case.area,
                    "lat": mock_case.coords[0],
                    "lon": mock_case.coords[1],
                    "km": radius_km,
                }
                lawyer_rows = supabase.rpc("find_nearby_lawyers", rpc_params).eq("is_available", True).execute().data
            except Exception:
                # Fallback para busca geral
                lawyer_rows = supabase.table("lawyers").select("*").eq("is_available", True).limit(50).execute().data
            
            # Filtrar usuário atual se especificado
            if exclude_user_id:
                lawyer_rows = [r for r in lawyer_rows if r["id"] != exclude_user_id]
            
            # Converter para objetos Lawyer
            candidates = [
                Lawyer(
                    id=r["id"],
                    nome=r["nome"],
                    tags_expertise=r["tags_expertise"],
                    geo_latlon=tuple(r["geo_latlon"]),
                    curriculo_json=r.get("curriculo_json", {}),
                    casos_historicos_embeddings=[np.array(v) for v in r.get("casos_historicos_embeddings", [])],
                    kpi=KPI(**r.get("kpi", {})),
                    kpi_subarea=r.get("kpi_subarea", {}),
                    kpi_softskill=r.get("kpi_softskill", 0.0),
                    case_outcomes=r.get("case_outcomes", [])
                ) for r in lawyer_rows[:limit]  # Limitar aqui para performance
            ]
            
            # Executar ranking (sem persistir, pois é busca)
            top_lawyers = await self.algo.rank(mock_case, candidates, top_n=limit, preset="balanced")
            
            # Formatar resposta para frontend
            partners = []
            for lw in top_lawyers:
                raw_data = next((r for r in lawyer_rows if r["id"] == lw.id), {})
                
                partner = {
                    "id": lw.id,
                    "nome": lw.nome,
                    "primary_area": raw_data.get("tags_expertise", ["Geral"])[0] if raw_data.get("tags_expertise") else "Geral",
                    "rating": lw.kpi.avaliacao_media,
                    "is_available": raw_data.get("is_available", True),
                    "avatar_url": raw_data.get("avatar_url"),
                    "distance_km": haversine(mock_case.coords, lw.geo_latlon) if coordinates else None,
                    "fair": lw.scores.get("fair", 0),
                    "experience_years": raw_data.get("curriculo_json", {}).get("experience_years", 0),
                    "awards": raw_data.get("curriculo_json", {}).get("awards", []),
                    "professional_summary": raw_data.get("curriculo_json", {}).get("summary", "")
                }
                partners.append(partner)
            
            return partners
            
        except Exception as e:
            print(f"Erro na busca de parceiros: {e}")
            return []


# Instância do serviço para importação
match_service = MatchService()
