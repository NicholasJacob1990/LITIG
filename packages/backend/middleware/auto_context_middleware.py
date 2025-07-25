"""
Middleware para detecção automática de contexto
Solução 3: Intercepta requisições e detecta contexto automaticamente

Funcionalidades:
- Detecta contexto baseado na rota
- Aplica automaticamente para super associados
- Não interfere em outros usuários
- Logs automáticos de mudanças
"""

import logging
from typing import Callable, Dict, Any
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from services.auto_context_service import AutoContextService
from config import get_supabase_client
from auth import get_current_user_from_request

logger = logging.getLogger(__name__)

class AutoContextMiddleware(BaseHTTPMiddleware):
    """
    Middleware para detecção automática de contexto
    
    Aplica a Solução 3: detecção transparente sem intervenção manual
    """
    
    def __init__(self, app, supabase_client=None):
        super().__init__(app)
        self.supabase = supabase_client or get_supabase_client()
        self.auto_context_service = AutoContextService(self.supabase)
        
        # Rotas que devem ser ignoradas pelo middleware
        self.ignored_routes = {
            '/api/health',
            '/api/auto-context/health',
            '/api/auth/login',
            '/api/auth/logout',
            '/docs',
            '/redoc',
            '/openapi.json',
            '/metrics',
        }
        
        # Patterns de rota para detecção automática
        self.route_patterns = {
            'personal_client': ['/personal/', '/my-cases/', '/client/'],
            'administrative_task': ['/admin/', '/settings/', '/management/'],
            'platform_work': ['/offers/', '/partnerships/', '/cases/', '/dashboard/']
        }

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Processa a requisição e detecta contexto automaticamente
        """
        # Verificar se deve processar esta requisição
        if not self._should_process_request(request):
            return await call_next(request)
        
        try:
            # Tentar obter usuário atual
            current_user = await self._get_current_user_safe(request)
            
            if not current_user or not self._is_super_associate(current_user):
                # Não é super associado, prosseguir normalmente
                return await call_next(request)
            
            # Detectar contexto automaticamente
            context_info = await self._detect_context_from_request(request, current_user)
            
            # Adicionar informações de contexto no header da resposta
            response = await call_next(request)
            
            if isinstance(response, (Response, JSONResponse)):
                response.headers["X-Auto-Context"] = context_info.get("context", "platform_work")
                response.headers["X-Context-Method"] = context_info.get("method", "route_based")
                response.headers["X-Context-Confidence"] = str(context_info.get("confidence", 1.0))
            
            return response
            
        except Exception as e:
            logger.error(f"Error in auto context middleware: {e}")
            # Em caso de erro, prosseguir normalmente
            return await call_next(request)

    def _should_process_request(self, request: Request) -> bool:
        """
        Verifica se a requisição deve ser processada pelo middleware
        """
        path = request.url.path
        
        # Ignorar rotas específicas
        if path in self.ignored_routes:
            return False
        
        # Ignorar arquivos estáticos
        if path.startswith('/static/') or path.startswith('/assets/'):
            return False
        
        # Processar apenas requisições para API
        if not path.startswith('/api/'):
            return False
        
        return True

    async def _get_current_user_safe(self, request: Request) -> Dict[str, Any] | None:
        """
        Obtém usuário atual de forma segura (sem lançar exceções)
        """
        try:
            return await get_current_user_from_request(request)
        except Exception:
            return None

    def _is_super_associate(self, user: Dict[str, Any]) -> bool:
        """
        Verifica se o usuário é super associado
        """
        return user.get("role") == "lawyer_platform_associate"

    async def _detect_context_from_request(self, request: Request, user: Dict[str, Any]) -> Dict[str, Any]:
        """
        Detecta contexto baseado na requisição HTTP
        """
        path = request.url.path
        method = request.method
        query_params = dict(request.query_params)
        
        # Detecção baseada em padrões de rota
        detected_context = self._detect_context_by_route_pattern(path)
        
        # Se não detectou por padrão, usar contexto padrão
        if not detected_context:
            detected_context = "platform_work"
        
        # Calcular confiança baseada no método de detecção
        confidence = self._calculate_confidence(path, method, detected_context)
        
        # Log da detecção
        log_result = await self.auto_context_service.log_automatic_detection(
            user_id=user["id"],
            detected_context=detected_context,
            route_path=path,
            method=method,
            confidence=confidence,
            query_params=query_params
        )
        
        return {
            "context": detected_context,
            "method": "route_pattern",
            "confidence": confidence,
            "log_id": log_result.get("log_id"),
            "indicators": [f"route:{path}", f"method:{method}"]
        }

    def _detect_context_by_route_pattern(self, path: str) -> str | None:
        """
        Detecta contexto baseado em padrões de rota
        """
        for context, patterns in self.route_patterns.items():
            for pattern in patterns:
                if pattern in path:
                    return context
        return None

    def _calculate_confidence(self, path: str, method: str, context: str) -> float:
        """
        Calcula confiança da detecção baseada em vários fatores
        """
        confidence = 0.5  # Base
        
        # Rotas muito específicas = alta confiança
        specific_routes = {
            '/personal/': 0.95,
            '/admin/': 0.90,
            '/my-cases/': 0.85,
            '/client/': 0.85,
            '/offers/': 0.80,
            '/partnerships/': 0.80
        }
        
        for route, conf in specific_routes.items():
            if route in path:
                confidence = max(confidence, conf)
        
        # Métodos GET são mais confiáveis para detecção
        if method == 'GET':
            confidence += 0.1
        
        # Contexto padrão tem confiança menor
        if context == 'platform_work':
            confidence = min(confidence, 0.7)
        
        return min(confidence, 1.0)

class AutoContextRequestState:
    """
    Classe para armazenar estado do contexto durante a requisição
    """
    
    def __init__(self):
        self.current_context = None
        self.detection_method = None
        self.confidence = None
        self.user_id = None
        self.log_id = None

# Instância global para armazenar estado da requisição
auto_context_state = AutoContextRequestState()

def get_request_context() -> AutoContextRequestState:
    """
    Obtém o contexto da requisição atual
    """
    return auto_context_state

async def set_request_context(
    context: str, 
    method: str, 
    confidence: float, 
    user_id: str, 
    log_id: str = None
):
    """
    Define o contexto da requisição atual
    """
    auto_context_state.current_context = context
    auto_context_state.detection_method = method
    auto_context_state.confidence = confidence
    auto_context_state.user_id = user_id
    auto_context_state.log_id = log_id 