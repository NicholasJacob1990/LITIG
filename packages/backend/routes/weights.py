"""
Rota para debugging e transparência do algoritmo de match v2.2.
Permite visualizar os pesos atualmente carregados.
"""
from typing import Dict

from fastapi import APIRouter, HTTPException

# Importar a variável _current_weights diretamente do módulo do algoritmo
from algoritmo_match import PRESET_WEIGHTS, _current_weights, load_weights

router = APIRouter()


@router.get("/debug/weights", response_model=Dict[str, float])
async def get_current_weights():
    """
    Retorna os pesos que o algoritmo de match está utilizando no momento.
    """
    if not _current_weights:
        # Se estiver vazio, tenta carregar
        load_weights()

    if not _current_weights:
        raise HTTPException(status_code=500, detail="Pesos não puderam ser carregados.")

    # Retorna uma cópia para evitar modificação externa
    return _current_weights.copy()


@router.get("/debug/presets", response_model=Dict[str, Dict[str, float]])
async def get_available_presets():
    """
    Retorna todos os presets de pesos disponíveis.
    """
    return PRESET_WEIGHTS


@router.post("/debug/reload_weights", response_model=Dict[str, float])
async def reload_weights_endpoint():
    """
    Força o recarregamento dos pesos do arquivo ltr_weights.json.
    Útil após um novo treinamento do modelo LTR.
    """
    try:
        reloaded_weights = load_weights()
        return reloaded_weights
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao recarregar pesos: {e}")
