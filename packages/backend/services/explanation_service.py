# backend/explanation_service.py
import os
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv

from backend.algoritmo_match import KPI, Case, Lawyer, MatchmakingAlgorithm
from backend.models import ExplainRequest, ExplainResponse, Explanation
from supabase import Client, create_client

# Configuração
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

algo = MatchmakingAlgorithm()


async def generate_explanations_for_matches(
    req: ExplainRequest,
) -> Optional[ExplainResponse]:
    """
    Gera explicações detalhadas para o match entre um caso e advogados.
    v2.2: Usa o novo `algo.rank` para obter o breakdown detalhado.
    """
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
        summary_embedding=np.array(
            case_row.get(
                "summary_embedding",
                []),
            dtype=np.float32),
    )

    # 2. Carregar dados dos advogados especificados
    lawyer_rows = supabase.table("lawyers").select(
        "*").in_("id", req.lawyer_ids).execute().data

    candidates = [
        Lawyer(
            id=r["id"],
            nome=r["nome"],
            tags_expertise=r["tags_expertise"],
            geo_latlon=tuple(r["geo_latlon"]),
            curriculo_json=r.get("curriculo_json", {}),
            kpi=KPI(**r.get("kpi", {})),
            kpi_subarea=r.get("kpi_subarea", {}),
            kpi_softskill=r.get("kpi_softskill", 0.0),
            case_outcomes=r.get("case_outcomes", [])
        ) for r in lawyer_rows
    ]

    if not candidates:
        return None

    # 3. Executar o ranking para obter scores detalhados
    ranked_lawyers = await algo.rank(case, candidates, top_n=len(candidates), preset=req.preset)

    explanations = []
    for lw in ranked_lawyers:
        scores = lw.scores
        explanations.append(
            Explanation(
                lawyer_id=lw.id,
                raw_score=scores.get("raw", 0),
                features=scores.get("features", {}),
                breakdown=scores.get("delta")
            )
        )

    return ExplainResponse(case_id=case.id, explanations=explanations)


# Instância do serviço para importação
explanation_service = generate_explanations_for_matches
