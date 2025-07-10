"""
Módulo de serviços - pasta para organização dos serviços específicos.
"""

# Este arquivo é mantido vazio para evitar imports circulares.
# As importações devem ser feitas diretamente dos módulos específicos.

from __future__ import annotations

import os
from typing import Dict, List

from dotenv import load_dotenv

from supabase import Client, create_client

"""Pacote de serviços – exporta utilitários de alto nível.
Inclui generate_explanations_for_matches para evitar conflito entre
arquivo services.py antigo e o pacote.
"""


# Carregar variáveis de ambiente a partir do .env raiz
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Criar cliente apenas se as variáveis estiverem configuradas
supabase: Client = None
if SUPABASE_URL and SUPABASE_SERVICE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
else:
    # Em desenvolvimento, usar cliente mock ou None
    print("AVISO: Variáveis SUPABASE_URL e SUPABASE_SERVICE_KEY não configuradas. Rodando em modo de desenvolvimento.")

# Importar serviço de explicação IA
from .explanation_service import (  # noqa: E402
    generate_explanations_for_matches as explanation_service,
)


async def generate_explanations_for_matches(
        case_id: str, lawyer_ids: List[str]) -> Dict[str, str]:
    """Gera explicações IA para uma lista de advogados de um caso."""
    # 1. Buscar resumo do caso
    case_row = (
        supabase.table("cases")
        .select("texto_cliente")
        .eq("id", case_id)
        .single()
        .execute()
        .data
    )
    if not case_row:
        raise ValueError(f"Caso com ID {case_id} não encontrado.")
    case_summary: str = case_row["texto_cliente"]

    # 2. Buscar dados dos advogados
    lawyer_rows = (
        supabase.table("lawyers")
        .select("*")
        .in_("id", lawyer_ids)
        .execute()
        .data
    )
    lawyers_data = {lw["id"]: lw for lw in lawyer_rows}

    # 3. Gerar explicações usando o serviço de IA
    explanations: Dict[str, str] = {}
    for lw_id in lawyer_ids:
        if lw_id in lawyers_data:
            mock_match_data = {
                **lawyers_data[lw_id],
                "fair": 0.9,
                "features": {},
                "distance_km": 10,
            }
            explanations[lw_id] = await explanation_service.generate_explanation(
                case_summary, mock_match_data
            )
        else:
            explanations[lw_id] = "Dados do advogado não encontrados."
    return explanations

__all__ = [
    "generate_explanations_for_matches",
]
