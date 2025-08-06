"""
Endpoints para obter movimentações detalhadas de processos via Escavador.
"""

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from dependencies.auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-movements", tags=["Process Movements"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

class MovementClassifier:
    """Classifica movimentações processuais por tipo."""
    
    MOVEMENT_TYPES = {
        "PETICAO": {
            "keywords": ["petição", "peticao", "inicial", "contestação", "contestacao", "recurso", "apelação", "apelacao"],
            "icon": "📄",
            "color": "#3B82F6",
            "description": "Petições e documentos protocolados"
        },
        "DECISAO": {
            "keywords": ["decisão", "decisao", "sentença", "sentenca", "acórdão", "acordao", "despacho"],
            "icon": "⚖️",
            "color": "#8B5CF6",
            "description": "Decisões judiciais"
        },
        "JUNTADA": {
            "keywords": ["juntada", "juntou", "anexou", "anexar", "documento"],
            "icon": "📎",
            "color": "#10B981",
            "description": "Juntada de documentos"
        },
        "CITACAO": {
            "keywords": ["citação", "citacao", "intimação", "intimacao", "notificação", "notificacao"],
            "icon": "📨",
            "color": "#F59E0B",
            "description": "Citações e intimações"
        },
        "AUDIENCIA": {
            "keywords": ["audiência", "audiencia", "sessão", "sessao", "conciliação", "conciliacao"],
            "icon": "🏛️",
            "color": "#EF4444",
            "description": "Audiências e sessões"
        },
        "CONCLUSAO": {
            "keywords": ["conclusão", "conclusao", "conclusos", "juiz", "relator"],
            "icon": "📋",
            "color": "#6B7280",
            "description": "Conclusão para decisão"
        },
        "OUTROS": {
            "keywords": [],
            "icon": "📌",
            "color": "#9CA3AF",
            "description": "Outras movimentações"
        }
    }
    
    def classify_movement(self, content: str) -> Dict[str, Any]:
        """Classifica uma movimentação pelo seu conteúdo."""
        content_lower = content.lower()
        
        for movement_type, config in self.MOVEMENT_TYPES.items():
            if movement_type == "OUTROS":
                continue
                
            for keyword in config["keywords"]:
                if keyword in content_lower:
                    return {
                        "type": movement_type,
                        "icon": config["icon"],
                        "color": config["color"],
                        "description": config["description"]
                    }
        
        # Default para "OUTROS"
        outros_config = self.MOVEMENT_TYPES["OUTROS"]
        return {
            "type": "OUTROS",
            "icon": outros_config["icon"],
            "color": outros_config["color"],
            "description": outros_config["description"]
        }

@router.get(
    "/{cnj}/detailed",
    summary="Obter Movimentações Detalhadas de um Processo",
    description="Busca todas as movimentações de um processo pelo CNJ, classificadas por tipo para exibição em linha do tempo.",
    response_model=Dict[str, Any],
)
async def get_detailed_process_movements(
    cnj: str,
    limit: Optional[int] = Query(default=50, description="Limite de movimentações retornadas"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar movimentações detalhadas de um processo específico.
    
    Retorna dados formatados para exibição em linha do tempo no frontend,
    incluindo classificação por tipo de movimentação.
    """
    try:
        movements_data = await escavador_client.get_detailed_process_movements(cnj, limit)
        return movements_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar movimentações do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.")

@router.get(
    "/{cnj}/summary",
    summary="Obter Resumo do Status do Processo",
    description="Retorna um resumo formatado do status atual do processo para exibição no frontend.",
    response_model=Dict[str, Any],
)
async def get_process_status_summary(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para obter resumo do status atual do processo.
    
    Retorna dados no formato esperado pelo ProcessStatusSection do frontend.
    """
    try:
        status_data = await escavador_client.get_process_status_summary(cnj)
        return status_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 
Endpoints para obter movimentações detalhadas de processos via Escavador.
"""

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from dependencies.auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-movements", tags=["Process Movements"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

class MovementClassifier:
    """Classifica movimentações processuais por tipo."""
    
    MOVEMENT_TYPES = {
        "PETICAO": {
            "keywords": ["petição", "peticao", "inicial", "contestação", "contestacao", "recurso", "apelação", "apelacao"],
            "icon": "📄",
            "color": "#3B82F6",
            "description": "Petições e documentos protocolados"
        },
        "DECISAO": {
            "keywords": ["decisão", "decisao", "sentença", "sentenca", "acórdão", "acordao", "despacho"],
            "icon": "⚖️",
            "color": "#8B5CF6",
            "description": "Decisões judiciais"
        },
        "JUNTADA": {
            "keywords": ["juntada", "juntou", "anexou", "anexar", "documento"],
            "icon": "📎",
            "color": "#10B981",
            "description": "Juntada de documentos"
        },
        "CITACAO": {
            "keywords": ["citação", "citacao", "intimação", "intimacao", "notificação", "notificacao"],
            "icon": "📨",
            "color": "#F59E0B",
            "description": "Citações e intimações"
        },
        "AUDIENCIA": {
            "keywords": ["audiência", "audiencia", "sessão", "sessao", "conciliação", "conciliacao"],
            "icon": "🏛️",
            "color": "#EF4444",
            "description": "Audiências e sessões"
        },
        "CONCLUSAO": {
            "keywords": ["conclusão", "conclusao", "conclusos", "juiz", "relator"],
            "icon": "📋",
            "color": "#6B7280",
            "description": "Conclusão para decisão"
        },
        "OUTROS": {
            "keywords": [],
            "icon": "📌",
            "color": "#9CA3AF",
            "description": "Outras movimentações"
        }
    }
    
    def classify_movement(self, content: str) -> Dict[str, Any]:
        """Classifica uma movimentação pelo seu conteúdo."""
        content_lower = content.lower()
        
        for movement_type, config in self.MOVEMENT_TYPES.items():
            if movement_type == "OUTROS":
                continue
                
            for keyword in config["keywords"]:
                if keyword in content_lower:
                    return {
                        "type": movement_type,
                        "icon": config["icon"],
                        "color": config["color"],
                        "description": config["description"]
                    }
        
        # Default para "OUTROS"
        outros_config = self.MOVEMENT_TYPES["OUTROS"]
        return {
            "type": "OUTROS",
            "icon": outros_config["icon"],
            "color": outros_config["color"],
            "description": outros_config["description"]
        }

@router.get(
    "/{cnj}/detailed",
    summary="Obter Movimentações Detalhadas de um Processo",
    description="Busca todas as movimentações de um processo pelo CNJ, classificadas por tipo para exibição em linha do tempo.",
    response_model=Dict[str, Any],
)
async def get_detailed_process_movements(
    cnj: str,
    limit: Optional[int] = Query(default=50, description="Limite de movimentações retornadas"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar movimentações detalhadas de um processo específico.
    
    Retorna dados formatados para exibição em linha do tempo no frontend,
    incluindo classificação por tipo de movimentação.
    """
    try:
        movements_data = await escavador_client.get_detailed_process_movements(cnj, limit)
        return movements_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar movimentações do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.")

@router.get(
    "/{cnj}/summary",
    summary="Obter Resumo do Status do Processo",
    description="Retorna um resumo formatado do status atual do processo para exibição no frontend.",
    response_model=Dict[str, Any],
)
async def get_process_status_summary(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para obter resumo do status atual do processo.
    
    Retorna dados no formato esperado pelo ProcessStatusSection do frontend.
    """
    try:
        status_data = await escavador_client.get_process_status_summary(cnj)
        return status_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 
Endpoints para obter movimentações detalhadas de processos via Escavador.
"""

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from dependencies.auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-movements", tags=["Process Movements"])

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Retorna uma instância do cliente Escavador com a chave de API."""
    from config.base import ESCAVADOR_API_KEY
    if not ESCAVADOR_API_KEY:
        raise HTTPException(
            status_code=500, detail="ESCAVADOR_API_KEY não está configurada no ambiente."
        )
    return EscavadorClient(api_key=ESCAVADOR_API_KEY)

class MovementClassifier:
    """Classifica movimentações processuais por tipo."""
    
    MOVEMENT_TYPES = {
        "PETICAO": {
            "keywords": ["petição", "peticao", "inicial", "contestação", "contestacao", "recurso", "apelação", "apelacao"],
            "icon": "📄",
            "color": "#3B82F6",
            "description": "Petições e documentos protocolados"
        },
        "DECISAO": {
            "keywords": ["decisão", "decisao", "sentença", "sentenca", "acórdão", "acordao", "despacho"],
            "icon": "⚖️",
            "color": "#8B5CF6",
            "description": "Decisões judiciais"
        },
        "JUNTADA": {
            "keywords": ["juntada", "juntou", "anexou", "anexar", "documento"],
            "icon": "📎",
            "color": "#10B981",
            "description": "Juntada de documentos"
        },
        "CITACAO": {
            "keywords": ["citação", "citacao", "intimação", "intimacao", "notificação", "notificacao"],
            "icon": "📨",
            "color": "#F59E0B",
            "description": "Citações e intimações"
        },
        "AUDIENCIA": {
            "keywords": ["audiência", "audiencia", "sessão", "sessao", "conciliação", "conciliacao"],
            "icon": "🏛️",
            "color": "#EF4444",
            "description": "Audiências e sessões"
        },
        "CONCLUSAO": {
            "keywords": ["conclusão", "conclusao", "conclusos", "juiz", "relator"],
            "icon": "📋",
            "color": "#6B7280",
            "description": "Conclusão para decisão"
        },
        "OUTROS": {
            "keywords": [],
            "icon": "📌",
            "color": "#9CA3AF",
            "description": "Outras movimentações"
        }
    }
    
    def classify_movement(self, content: str) -> Dict[str, Any]:
        """Classifica uma movimentação pelo seu conteúdo."""
        content_lower = content.lower()
        
        for movement_type, config in self.MOVEMENT_TYPES.items():
            if movement_type == "OUTROS":
                continue
                
            for keyword in config["keywords"]:
                if keyword in content_lower:
                    return {
                        "type": movement_type,
                        "icon": config["icon"],
                        "color": config["color"],
                        "description": config["description"]
                    }
        
        # Default para "OUTROS"
        outros_config = self.MOVEMENT_TYPES["OUTROS"]
        return {
            "type": "OUTROS",
            "icon": outros_config["icon"],
            "color": outros_config["color"],
            "description": outros_config["description"]
        }

@router.get(
    "/{cnj}/detailed",
    summary="Obter Movimentações Detalhadas de um Processo",
    description="Busca todas as movimentações de um processo pelo CNJ, classificadas por tipo para exibição em linha do tempo.",
    response_model=Dict[str, Any],
)
async def get_detailed_process_movements(
    cnj: str,
    limit: Optional[int] = Query(default=50, description="Limite de movimentações retornadas"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para buscar movimentações detalhadas de um processo específico.
    
    Retorna dados formatados para exibição em linha do tempo no frontend,
    incluindo classificação por tipo de movimentação.
    """
    try:
        movements_data = await escavador_client.get_detailed_process_movements(cnj, limit)
        return movements_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar movimentações do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.")

@router.get(
    "/{cnj}/summary",
    summary="Obter Resumo do Status do Processo",
    description="Retorna um resumo formatado do status atual do processo para exibição no frontend.",
    response_model=Dict[str, Any],
)
async def get_process_status_summary(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client),
):
    """
    Endpoint para obter resumo do status atual do processo.
    
    Retorna dados no formato esperado pelo ProcessStatusSection do frontend.
    """
    try:
        status_data = await escavador_client.get_process_status_summary(cnj)
        return status_data
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erro inesperado ao buscar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno no servidor.") 