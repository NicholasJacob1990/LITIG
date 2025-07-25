"""
Serviço de Matchmaking, responsável por orquestrar o ranking e as notificações.
"""
import os
import time
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv

from algoritmo_match import KPI, Case, Lawyer, MatchmakingAlgorithm, haversine
from metrics import cache_hits_total, cache_misses_total
from models import MatchRequest
from services.cache_service_simple import simple_cache_service as cache_service
from services.notify_service import send_notifications_to_lawyers
from services.offer_service import create_offer_from_match
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
    Orquestra o processo de match e retorna a lista de advogados para o cliente escolher.
    NOVO FLUXO: Não cria ofertas automaticamente, apenas retorna matches para escolha do cliente.
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

    # 5. NOVO FLUXO: Atualizar status do caso para "awaiting_client_choice"
    supabase.table("cases").update({
        "status": "awaiting_client_choice",
        "matches_generated_at": time.time()
    }).eq("id", case.id).execute()

    # 6. Formatar resposta para o cliente escolher
    lawyer_raw_data = {r['id']: r for r in lawyer_rows}
    response = format_match_response(case, top_lawyers, lawyer_raw_data)

    # Salvar no cache Redis
    await cache_service.set_case_matches(
        req.case_id,
        response,
        filters={"preset": req.preset, "k": req.k}
    )

    return response


async def process_client_choice(case_id: str, chosen_lawyer_id: str, choice_order: int) -> Dict[str, Any]:
    """
    Processa a escolha do cliente e cria a oferta para o advogado escolhido.
    NOVO FLUXO: Cria oferta apenas para o advogado escolhido pelo cliente.
    
    Args:
        case_id: ID do caso
        chosen_lawyer_id: ID do advogado escolhido pelo cliente
        choice_order: Ordem de escolha (1 = primeira escolha, 2 = segunda, etc.)
        
    Returns:
        Resultado da criação da oferta
    """
    try:
        # 1. Buscar dados do caso
        case_row = supabase.table("cases").select("*").eq("id", case_id).single().execute().data
        if not case_row:
            raise ValueError("Caso não encontrado")
        
        if case_row["status"] != "awaiting_client_choice":
            raise ValueError("Caso não está aguardando escolha do cliente")
        
        # 2. Buscar dados do advogado escolhido
        lawyer_row = supabase.table("lawyers").select("*").eq("id", chosen_lawyer_id).single().execute().data
        if not lawyer_row:
            raise ValueError("Advogado não encontrado")
        
        if not lawyer_row.get("is_available", False):
            raise ValueError("Advogado não está disponível")
        
        # 3. Preparar detalhes da oferta
        offer_details = {
            "case_summary": case_row.get("summary", ""),
            "legal_area": case_row.get("area", ""),
            "subarea": case_row.get("subarea", ""),
            "urgency_level": case_row.get("urgency_h", 0),
            "estimated_fee": case_row.get("estimated_fee", None),
            "client_location": case_row.get("coords", []),
            "complexity": case_row.get("complexity", "MEDIUM")
        }
        
        # 4. Criar oferta usando o serviço
        offer_id = await create_offer_from_match(
            case_id=case_id,
            lawyer_id=chosen_lawyer_id,
            choice_order=choice_order,
            offer_details=offer_details
        )
        
        # 5. Atualizar status do caso
        supabase.table("cases").update({
            "status": "offer_pending",
            "offer_sent_at": time.time(),
            "chosen_lawyer_id": chosen_lawyer_id
        }).eq("id", case_id).execute()
        
        # 6. Enviar notificação para o advogado
        notification_payload = {
            "case_id": case_id,
            "offer_id": offer_id,
            "headline": f"Nova oferta de caso na área de {case_row.get('area', '')}",
            "summary": f"Você foi escolhido por um cliente para um caso de {case_row.get('area', '')}. Prazo para resposta: 48h.",
            "urgency_level": case_row.get("urgency_h", 0)
        }
        
        await send_notifications_to_lawyers([chosen_lawyer_id], notification_payload)
        
        return {
            "success": True,
            "message": "Oferta criada e enviada com sucesso",
            "offer_id": offer_id,
            "case_id": case_id,
            "lawyer_id": chosen_lawyer_id
        }
        
    except Exception as e:
        print(f"Erro ao processar escolha do cliente: {e}")
        raise


async def reactivate_matching_for_case(case_id: str, exclude_lawyer_ids: List[str]) -> Dict[str, Any]:
    """
    Reativa o matching para um caso quando uma oferta é rejeitada.
    
    Args:
        case_id: ID do caso
        exclude_lawyer_ids: IDs dos advogados a serem excluídos do novo matching
        
    Returns:
        Resultado do novo matching
    """
    try:
        # 1. Buscar dados do caso
        case_row = supabase.table("cases").select("*").eq("id", case_id).single().execute().data
        if not case_row:
            raise ValueError("Caso não encontrado")
        
        # 2. Criar request de match excluindo advogados que já rejeitaram
        match_request = MatchRequest(
            case_id=case_id,
            exclude_ids=exclude_lawyer_ids,
            k=5,  # Buscar próximos 5 advogados
            preset="balanced"
        )
        
        # 3. Executar novo matching
        result = await find_and_notify_matches(match_request)
        
        # 4. Atualizar status do caso
        supabase.table("cases").update({
            "status": "awaiting_client_choice",
            "rematched_at": time.time()
        }).eq("id", case_id).execute()
        
        return result
        
    except Exception as e:
        print(f"Erro ao reativar matching: {e}")
        raise


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
            "primary_area": raw_data.get("tags_expertise", [None])[0] if raw_data.get("tags_expertise") else None,
        })

    return {"case_id": case.id, "matches": matches_response}


class MatchService:
    """Classe de serviço para operações de matching."""

    def __init__(self):
        self.algo = MatchmakingAlgorithm()

    async def find_matches(self, req: MatchRequest) -> Optional[Dict[str, Any]]:
        """Encontra matches para um caso específico."""
        return await find_and_notify_matches(req)

    async def process_client_choice(self, case_id: str, chosen_lawyer_id: str, choice_order: int) -> Dict[str, Any]:
        """Processa a escolha do cliente."""
        return await process_client_choice(case_id, chosen_lawyer_id, choice_order)

    async def reactivate_matching(self, case_id: str, exclude_lawyer_ids: List[str]) -> Dict[str, Any]:
        """Reativa matching para caso rejeitado."""
        return await reactivate_matching_for_case(case_id, exclude_lawyer_ids)

    async def persist_matches(self, case_id: str, ranked_lawyers: List[Lawyer]):
        """Persiste matches no banco de dados."""
        return await _persist_matches(case_id, ranked_lawyers)
