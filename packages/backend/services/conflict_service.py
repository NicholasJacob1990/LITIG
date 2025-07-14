"""Serviço de checagem de conflitos de interesse.

Por ora, a heurística é simplificada (MVP):
1. Se o advogado já representa alguma parte listada em `case.opposing_party_ids` ⇒ conflito.
2. Se o escritório do advogado coincide com `case.opposing_firm_ids` ⇒ conflito.
3. Se o advogado marcou self-declared conflict (campo `lawyer.has_conflict`), retorna True.

A estrutura de dados do `Case` original não possui esses campos; eles são opcionais
neste MVP. A função deve ser robusta a atributos ausentes.
"""
from __future__ import annotations
from typing import Any


def conflict_scan(case: Any, lawyer: Any) -> bool:
    """Retorna True se houver conflito de interesse detectado."""
    # 1) Self-declared conflict flag (pode ser setada em processos disciplinares)
    if getattr(lawyer, "has_conflict", False):
        return True

    # 2) Conflito com partes adversas
    opposing_parties = set(getattr(case, "opposing_party_ids", []) or [])
    if opposing_parties:
        past_clients = set(getattr(lawyer, "past_client_ids", []) or [])
        if opposing_parties & past_clients:
            return True

    # 3) Conflito entre escritórios/bancas
    opposing_firms = set(getattr(case, "opposing_firm_ids", []) or [])
    if opposing_firms and lawyer.firm_id and lawyer.firm_id in opposing_firms:
        return True

    return False 