"""
Endpoints para obter detalhes de Pessoas (advogados, etc.) via Escavador.
"""

import logging
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy" 
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/persons", tags=["Persons"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

@router.get(
    "/{person_id}/details",
    summary="Obter Detalhes Completos de uma Pessoa",
    description="Busca os detalhes completos de uma pessoa, incluindo o currículo Lattes, pelo seu ID do Escavador.",
    response_model=Dict[str, Any],
)
async def get_person_details_route(
    person_id: int,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar detalhes de uma pessoa (advogado, etc.) pelo ID do Escavador.
    """
    try:
        details = await escavador_client.get_person_details(person_id)
        return details
    except HTTPException as e:
        # Re-lançar exceções HTTP já formatadas pelo client
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar detalhes da pessoa {person_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 
Endpoints para obter detalhes de Pessoas (advogados, etc.) via Escavador.
"""

import logging
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy" 
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/persons", tags=["Persons"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

@router.get(
    "/{person_id}/details",
    summary="Obter Detalhes Completos de uma Pessoa",
    description="Busca os detalhes completos de uma pessoa, incluindo o currículo Lattes, pelo seu ID do Escavador.",
    response_model=Dict[str, Any],
)
async def get_person_details_route(
    person_id: int,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar detalhes de uma pessoa (advogado, etc.) pelo ID do Escavador.
    """
    try:
        details = await escavador_client.get_person_details(person_id)
        return details
    except HTTPException as e:
        # Re-lançar exceções HTTP já formatadas pelo client
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar detalhes da pessoa {person_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 
Endpoints para obter detalhes de Pessoas (advogados, etc.) via Escavador.
"""

import logging
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy" 
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/persons", tags=["Persons"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

@router.get(
    "/{person_id}/details",
    summary="Obter Detalhes Completos de uma Pessoa",
    description="Busca os detalhes completos de uma pessoa, incluindo o currículo Lattes, pelo seu ID do Escavador.",
    response_model=Dict[str, Any],
)
async def get_person_details_route(
    person_id: int,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar detalhes de uma pessoa (advogado, etc.) pelo ID do Escavador.
    """
    try:
        details = await escavador_client.get_person_details(person_id)
        return details
    except HTTPException as e:
        # Re-lançar exceções HTTP já formatadas pelo client
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar detalhes da pessoa {person_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 