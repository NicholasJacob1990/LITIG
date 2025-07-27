"""
Rotas para AutoContextService - Sistema de Detecção Automática de Contexto
Solução 3: Contexto automático sem toggle manual

Endpoints para:
- Detecção automática de contexto baseada em rotas
- Logs de mudanças de contexto
- Consulta de contexto atual
- Histórico de contextos
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, Request, Query
from pydantic import BaseModel, Field
import logging

from auth import get_current_user
from config import get_supabase_client
from services.auto_context_service import AutoContextService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auto-context", tags=["Auto Context"])

# Pydantic Models
class ContextDetectionRequest(BaseModel):
    route_path: str = Field(..., description="Caminho da rota atual")
    action_data: Optional[Dict[str, Any]] = Field(None, description="Dados da ação executada")
    entity_metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados da entidade")

class ContextDetectionResponse(BaseModel):
    detected_context: str = Field(..., description="Contexto detectado")
    confidence: float = Field(..., description="Confiança da detecção (0-1)")
    detection_method: str = Field(..., description="Método usado para detecção")
    indicators_found: List[str] = Field(..., description="Indicadores encontrados")
    log_id: str = Field(..., description="ID do log criado")

class ContextHistoryResponse(BaseModel):
    user_id: str
    context_changes: List[Dict[str, Any]]
    current_context: str
    session_summary: Dict[str, Any]

class ContextStatsResponse(BaseModel):
    total_detections: int
    context_distribution: Dict[str, int]
    detection_accuracy: float
    avg_confidence: float
    most_active_hours: List[int]

@router.post("/detect", response_model=ContextDetectionResponse)
async def detect_context(
    request: ContextDetectionRequest,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Detecta automaticamente o contexto do usuário baseado na rota e dados
    
    Solução 3: Detecção automática sem intervenção manual
    """
    try:
        # Verificar se é Super Associado (suportar nome novo e legado)
        user_role = current_user.get("role", "")
        if user_role not in ["super_associate", "lawyer_platform_associate"]:
            raise HTTPException(
                status_code=403,
                detail="Acesso restrito a Super Associados"
            )
        
        auto_context_service = AutoContextService(supabase)
        
        # Detectar contexto automaticamente
        detection_result = await auto_context_service.detect_context_automatically(
            user_id=current_user["id"],
            route_path=request.route_path,
            action_data=request.action_data or {},
            entity_metadata=request.entity_metadata or {}
        )
        
        return ContextDetectionResponse(
            detected_context=detection_result["context"],
            confidence=detection_result["confidence"],
            detection_method=detection_result["method"],
            indicators_found=detection_result["indicators"],
            log_id=detection_result["log_id"]
        )
        
    except Exception as e:
        logger.error(f"Error detecting context: {e}")
        raise HTTPException(status_code=500, detail="Failed to detect context")

@router.get("/current")
async def get_current_context(
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Retorna o contexto atual do usuário
    """
    try:
        if current_user.get("role") != "lawyer_platform_associate":
            return {"context": "not_applicable", "message": "User is not a platform associate"}
        
        auto_context_service = AutoContextService(supabase)
        
        current_context = await auto_context_service.get_current_context(
            user_id=current_user["id"]
        )
        
        return current_context
        
    except Exception as e:
        logger.error(f"Error getting current context: {e}")
        raise HTTPException(status_code=500, detail="Failed to get current context")

@router.get("/history", response_model=ContextHistoryResponse)
async def get_context_history(
    hours: int = Query(24, description="Histórico das últimas N horas"),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Retorna histórico de mudanças de contexto do usuário
    """
    try:
        if current_user.get("role") != "lawyer_platform_associate":
            raise HTTPException(
                status_code=403,
                detail="Context history is only available for platform associates"
            )
        
        auto_context_service = AutoContextService(supabase)
        
        # Buscar histórico
        since = datetime.utcnow() - timedelta(hours=hours)
        history = await auto_context_service.get_context_history(
            user_id=current_user["id"],
            since=since
        )
        
        # Buscar contexto atual
        current_context = await auto_context_service.get_current_context(
            user_id=current_user["id"]
        )
        
        # Calcular resumo da sessão
        session_summary = await auto_context_service.get_session_summary(
            user_id=current_user["id"],
            since=since
        )
        
        return ContextHistoryResponse(
            user_id=current_user["id"],
            context_changes=history,
            current_context=current_context.get("context", "platform_work"),
            session_summary=session_summary
        )
        
    except Exception as e:
        logger.error(f"Error getting context history: {e}")
        raise HTTPException(status_code=500, detail="Failed to get context history")

@router.post("/manual-log")
async def log_manual_context_change(
    context: str,
    reason: str,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Log manual de mudança de contexto (para casos excepcionais)
    """
    try:
        if current_user.get("role") != "lawyer_platform_associate":
            raise HTTPException(
                status_code=403,
                detail="Manual context logging is only available for platform associates"
            )
        
        auto_context_service = AutoContextService(supabase)
        
        log_result = await auto_context_service.log_manual_context_change(
            user_id=current_user["id"],
            context=context,
            reason=reason
        )
        
        return {
            "success": True,
            "log_id": log_result["log_id"],
            "message": f"Manual context change to {context} logged successfully"
        }
        
    except Exception as e:
        logger.error(f"Error logging manual context change: {e}")
        raise HTTPException(status_code=500, detail="Failed to log manual context change")

@router.get("/stats", response_model=ContextStatsResponse)
async def get_context_stats(
    days: int = Query(7, description="Estatísticas dos últimos N dias"),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Retorna estatísticas de uso do sistema de contexto automático
    
    Apenas para administradores ou para o próprio usuário
    """
    try:
        auto_context_service = AutoContextService(supabase)
        
        # Verificar se é Super Associado (suportar nome novo e legado)
        user_role = current_user.get("role", "")
        if user_role not in ["super_associate", "lawyer_platform_associate"]:
            raise HTTPException(
                status_code=403,
                detail="Acesso restrito a Super Associados"
            )
        
        # Calcular período
        since = datetime.utcnow() - timedelta(days=days)
        
        stats = await auto_context_service.get_context_statistics(
            user_id=current_user["id"],
            since=since
        )
        
        return ContextStatsResponse(
            total_detections=stats["total_detections"],
            context_distribution=stats["context_distribution"],
            detection_accuracy=stats["detection_accuracy"],
            avg_confidence=stats["avg_confidence"],
            most_active_hours=stats["most_active_hours"]
        )
        
    except Exception as e:
        logger.error(f"Error getting context stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to get context statistics")

@router.post("/middleware-detection")
async def middleware_context_detection(
    request: Request,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """
    Endpoint para detecção automática via middleware
    
    Chamado automaticamente pelo middleware em todas as requisições
    de super associados
    """
    try:
        # Apenas processar para super associados
        if current_user.get("role") != "lawyer_platform_associate":
            return {"context": "not_applicable"}
        
        auto_context_service = AutoContextService(supabase)
        
        # Extrair informações da requisição
        route_path = str(request.url.path)
        method = request.method
        query_params = dict(request.query_params)
        
        # Detectar contexto baseado na requisição
        detection_result = await auto_context_service.detect_context_from_request(
            user_id=current_user["id"],
            route_path=route_path,
            method=method,
            query_params=query_params
        )
        
        return {
            "context": detection_result["context"],
            "auto_detected": True,
            "method": detection_result["method"],
            "log_id": detection_result.get("log_id")
        }
        
    except Exception as e:
        logger.error(f"Error in middleware context detection: {e}")
        # Não falhar a requisição por causa do contexto
        return {"context": "platform_work", "auto_detected": False, "error": str(e)}

@router.get("/health")
async def context_service_health():
    """
    Health check do serviço de contexto automático
    """
    try:
        return {
            "status": "healthy",
            "service": "AutoContextService",
            "version": "1.0.0",
            "features": [
                "automatic_detection",
                "route_based_context",
                "action_based_context", 
                "entity_metadata_context",
                "context_history",
                "statistics",
                "manual_logging"
            ],
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Context service health check failed: {e}")
        raise HTTPException(status_code=503, detail="Context service unavailable") 