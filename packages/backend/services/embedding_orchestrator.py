"""
Orquestrador de Embeddings: Ponto Único de Acesso
=====================================

Serviço centralizado para geração de embeddings que abstrai a complexidade
dos provedores subjacentes. Implementa a estratégia original V2 (1024D)
com cascata otimizada: OpenAI → Voyage → Arctic.

Características:
- Interface simples e limpa
- Suporte para contextos específicos (case, lawyer_cv, enriched)
- Métricas de performance
- Preparado para futuras extensões (cache, rate limiting, A/B testing)
"""

import logging
import time
from typing import Any, Dict, List, Optional, Tuple
import asyncio
from dataclasses import dataclass
from enum import Enum

# Mover a definição do logger para o topo
logger = logging.getLogger(__name__)

# Importar serviço V2 (estratégia original)
try:
    from .embedding_service_v2 import legal_embedding_service_v2
    EMBEDDING_V2_AVAILABLE = True
except ImportError:
    logger.warning("EmbeddingService V2 não disponível")
    EMBEDDING_V2_AVAILABLE = False

# Importar serviço de embeddings enriquecidos V3
try:
    from .enriched_embedding_service import enriched_embedding_service
    ENRICHED_EMBEDDING_AVAILABLE = True
except ImportError:
    logger.warning("EnrichedEmbeddingService não disponível")
    ENRICHED_EMBEDDING_AVAILABLE = False


class EmbeddingType(Enum):
    """Tipos de embedding disponíveis."""
    STANDARD = "standard"      # V2 - Texto puro (1024D)
    ENRICHED = "enriched"      # V3 - Texto + KPIs + APIs (1024D)


@dataclass
class EmbeddingResult:
    """Resultado padronizado de geração de embedding."""
    embedding: List[float]
    dimensions: int
    provider: str
    embedding_type: str
    generation_time: float
    context_type: str
    confidence_score: float = 1.0
    metadata: Optional[Dict[str, Any]] = None


class EmbeddingOrchestrator:
    """
    Orquestrador centralizado para geração de embeddings.
    
    Funcionalidades:
    - Interface unificada para embeddings standard e enriched
    - Seleção automática da melhor estratégia baseada no contexto
    - Métricas de performance
    - Fallback robusto entre provedores
    - Preparado para futuras extensões
    """
    
    def __init__(self, enable_metrics: bool = True):
        self.enable_metrics = enable_metrics
        
        # Validação de serviços
        if not EMBEDDING_V2_AVAILABLE:
            raise RuntimeError("EmbeddingService V2 não disponível - sistema não pode funcionar")
        
        # Métricas internas
        self.metrics = {
            "standard_requests": 0,
            "enriched_requests": 0,
            "total_time": 0.0,
            "errors": 0,
            "provider_usage": {}
        }
        
        logger.info("🎯 EmbeddingOrchestrator inicializado")
        logger.info(f"✅ V2 Standard disponível: {EMBEDDING_V2_AVAILABLE}")
        logger.info(f"✅ V3 Enriched disponível: {ENRICHED_EMBEDDING_AVAILABLE}")

    async def generate_embedding(
        self,
        text: str,
        context_type: str = "case",
        embedding_type: EmbeddingType = EmbeddingType.STANDARD,
        force_provider: Optional[str] = None,
        **kwargs
    ) -> EmbeddingResult:
        """
        Gera embedding usando a melhor estratégia disponível.
        
        Args:
            text: Texto para gerar embedding
            context_type: Tipo de contexto ("case", "lawyer_cv", etc.)
            embedding_type: Tipo de embedding (STANDARD ou ENRICHED)
            force_provider: Forçar provedor específico
            **kwargs: Argumentos adicionais para embeddings enriquecidos
            
        Returns:
            EmbeddingResult com embedding e metadados
        """
        start_time = time.time()
        
        try:
            # Decidir qual tipo de embedding usar
            if embedding_type == EmbeddingType.ENRICHED and ENRICHED_EMBEDDING_AVAILABLE:
                result = await self._generate_enriched_embedding(
                    text, context_type, force_provider, **kwargs
                )
            else:
                # Usar standard (V2) como fallback padrão
                result = await self._generate_standard_embedding(
                    text, context_type, force_provider
                )
            
            # Adicionar tempo de geração
            result.generation_time = time.time() - start_time
            
            # Atualizar métricas
            if self.enable_metrics:
                await self._update_metrics(result)
            
            return result
            
        except Exception as e:
            self.metrics["errors"] += 1
            logger.error(f"Erro na geração de embedding: {e}")
            raise

    async def _generate_standard_embedding(
        self,
        text: str,
        context_type: str,
        force_provider: Optional[str] = None
    ) -> EmbeddingResult:
        """Gera embedding standard usando V2 (1024D)."""
        try:
            embedding, provider = await legal_embedding_service_v2.generate_legal_embedding(
                text, context_type, force_provider=force_provider
            )
            
            return EmbeddingResult(
                embedding=embedding,
                dimensions=len(embedding),
                provider=provider,
                embedding_type="standard",
                generation_time=0.0,  # Será preenchido depois
                context_type=context_type,
                confidence_score=1.0
            )
            
        except Exception as e:
            logger.error(f"Erro no embedding standard: {e}")
            raise

    async def _generate_enriched_embedding(
        self,
        text: str,
        context_type: str,
        force_provider: Optional[str] = None,
        **kwargs
    ) -> EmbeddingResult:
        """Gera embedding enriquecido usando V3 (1024D com KPIs)."""
        if not ENRICHED_EMBEDDING_AVAILABLE:
            logger.warning("Enriched embedding não disponível, usando standard")
            return await self._generate_standard_embedding(text, context_type, force_provider)
        
        try:
            # Para embeddings enriquecidos, precisamos do LawyerProfile
            lawyer_profile = kwargs.get('lawyer_profile')
            if not lawyer_profile:
                logger.warning("LawyerProfile não fornecido para embedding enriquecido, usando standard")
                return await self._generate_standard_embedding(text, context_type, force_provider)
            
            embedding, provider, metadata = await enriched_embedding_service.generate_enriched_embedding(
                lawyer_profile, 
                template_type=kwargs.get('template_type', 'balanced'),
                force_provider=force_provider
            )
            
            return EmbeddingResult(
                embedding=embedding,
                dimensions=len(embedding),
                provider=provider,
                embedding_type="enriched",
                generation_time=0.0,  # Será preenchido depois
                context_type=context_type,
                confidence_score=1.0,
                metadata=metadata
            )
            
        except Exception as e:
            logger.error(f"Erro no embedding enriquecido: {e}")
            # Fallback para standard
            logger.info("Fazendo fallback para embedding standard")
            return await self._generate_standard_embedding(text, context_type, force_provider)

    async def _update_metrics(self, result: EmbeddingResult):
        """Atualiza métricas internas."""
        if result.embedding_type == "standard":
            self.metrics["standard_requests"] += 1
        else:
            self.metrics["enriched_requests"] += 1
        
        self.metrics["total_time"] += result.generation_time
        
        # Contar uso de provedores
        provider = result.provider
        if provider not in self.metrics["provider_usage"]:
            self.metrics["provider_usage"][provider] = 0
        self.metrics["provider_usage"][provider] += 1

    def get_metrics(self) -> Dict[str, Any]:
        """Retorna métricas de performance do orquestrador."""
        total_requests = self.metrics["standard_requests"] + self.metrics["enriched_requests"]
        
        if total_requests == 0:
            return {"message": "Nenhuma requisição processada ainda"}
        
        avg_time = self.metrics["total_time"] / total_requests if total_requests > 0 else 0
        
        return {
            "total_requests": total_requests,
            "standard_requests": self.metrics["standard_requests"],
            "enriched_requests": self.metrics["enriched_requests"],
            "standard_percentage": (self.metrics["standard_requests"] / total_requests) * 100,
            "enriched_percentage": (self.metrics["enriched_requests"] / total_requests) * 100,
            "avg_generation_time": round(avg_time, 3),
            "errors": self.metrics["errors"],
            "provider_usage": self.metrics["provider_usage"],
            "services_available": {
                "v2_standard": EMBEDDING_V2_AVAILABLE,
                "v3_enriched": ENRICHED_EMBEDDING_AVAILABLE
            }
        }

    def get_service_status(self) -> Dict[str, Any]:
        """Retorna status completo do orquestrador."""
        status = {
            "orchestrator": {
                "version": "1.0",
                "strategy": "V2/V3 Original"
            },
            "v2_standard": {
                "available": EMBEDDING_V2_AVAILABLE,
                "dimensions": 1024,
                "providers": ["openai-3-large", "voyage-law-2", "snowflake-arctic-embed-l"]
            },
            "v3_enriched": {
                "available": ENRICHED_EMBEDDING_AVAILABLE,
                "dimensions": 1024,
                "features": ["cv_text", "kpis", "escavador_data", "performance_metrics"]
            }
        }
        
        # Adicionar stats do V2 se disponível
        if EMBEDDING_V2_AVAILABLE and hasattr(legal_embedding_service_v2, 'get_provider_stats'):
            status["v2_standard"]["provider_stats"] = legal_embedding_service_v2.get_provider_stats()
        
        return status


# Instância global padrão
embedding_orchestrator = EmbeddingOrchestrator()


# Funções de conveniência para compatibilidade com código existente
async def generate_embedding(
    text: str,
    context_type: str = "case",
    **kwargs
) -> List[float]:
    """
    Função de conveniência para gerar embedding standard.
    Mantém compatibilidade com código existente.
    """
    result = await embedding_orchestrator.generate_embedding(
        text, context_type, EmbeddingType.STANDARD, **kwargs
    )
    return result.embedding


async def generate_embedding_with_provider(
    text: str,
    context_type: str = "case",
    force_provider: Optional[str] = None
) -> Tuple[List[float], str]:
    """
    Função de conveniência que retorna embedding + provider.
    Mantém compatibilidade com código existente.
    """
    result = await embedding_orchestrator.generate_embedding(
        text, context_type, EmbeddingType.STANDARD, force_provider=force_provider
    )
    return result.embedding, result.provider


async def generate_enriched_embedding(
    lawyer_profile,
    template_type: str = "balanced",
    force_provider: Optional[str] = None
) -> Tuple[List[float], str, Dict[str, Any]]:
    """
    Função de conveniência para gerar embedding enriquecido.
    """
    result = await embedding_orchestrator.generate_embedding(
        "", "lawyer_cv", EmbeddingType.ENRICHED,
        force_provider=force_provider,
        lawyer_profile=lawyer_profile,
        template_type=template_type
    )
    return result.embedding, result.provider, result.metadata or {}


# Função para obter métricas do orquestrador
def get_orchestrator_metrics() -> Dict[str, Any]:
    """Função de conveniência para obter métricas."""
    return embedding_orchestrator.get_metrics()


def get_orchestrator_status() -> Dict[str, Any]:
    """Função de conveniência para obter status."""
    return embedding_orchestrator.get_service_status()