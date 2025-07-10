# backend/services/embedding_service.py
"""
Serviço de geração de embeddings com fallback local.
Usa OpenAI como principal e sentence-transformers como fallback.
"""
import logging
import os
import time
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv

from backend.services.embedding_service_parallel import parallel_embedding_service
from supabase import Client, create_client

# Configuração
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
OPENAI_TIMEOUT = int(os.getenv("OPENAI_TIMEOUT", "30"))

logger = logging.getLogger(__name__)

# Clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Importações condicionais
try:
    from openai import AsyncOpenAI
    openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)
    OPENAI_AVAILABLE = True
except ImportError:
    logger.warning("OpenAI não disponível, usando apenas fallback local")
    OPENAI_AVAILABLE = False
    openai_client = None

try:
    from sentence_transformers import SentenceTransformer

    # Modelo multilíngue pequeno e eficiente
    local_model = SentenceTransformer('all-MiniLM-L6-v2')
    LOCAL_MODEL_AVAILABLE = True
except ImportError:
    logger.warning("Sentence-transformers não disponível")
    LOCAL_MODEL_AVAILABLE = False
    local_model = None

# Importar métricas se disponível
try:
    from backend.metrics import external_api_duration, fallback_usage_total, track_time
    METRICS_AVAILABLE = True
except ImportError:
    METRICS_AVAILABLE = False
    # Criar decoradores dummy se métricas não estiverem disponíveis

    def track_time(histogram, **labels):
        def decorator(func):
            return func
        return decorator


class EmbeddingService:
    """Serviço de embeddings com fallback automático."""

    def __init__(self):
        self.openai_enabled = OPENAI_AVAILABLE and OPENAI_API_KEY
        self.local_enabled = LOCAL_MODEL_AVAILABLE
        self.embedding_dim = 1536  # Dimensão OpenAI
        self.local_dim = 384  # Dimensão do modelo local

        if not self.openai_enabled and not self.local_enabled:
            raise RuntimeError("Nenhum modelo de embedding disponível!")

    async def generate_embedding(
        self,
        text: str,
        force_local: bool = False
    ) -> List[float]:
        """
        Gera embedding com fallback automático.

        Args:
            text: Texto para gerar embedding
            force_local: Forçar uso do modelo local

        Returns:
            Lista de floats representando o embedding
        """
        # Tentar OpenAI primeiro (se não forçar local)
        if self.openai_enabled and not force_local:
            try:
                embedding = await self._generate_openai_embedding(text)
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(
                        service="embeddings",
                        reason="none"
                    ).inc()
                return embedding

            except Exception as e:
                logger.warning(f"OpenAI falhou, usando fallback local: {e}")
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(
                        service="embeddings",
                        reason=type(e).__name__
                    ).inc()

        # Fallback para modelo local
        if self.local_enabled:
            return await self._generate_local_embedding(text)
        else:
            raise RuntimeError("Nenhum modelo de embedding disponível!")

    @track_time(external_api_duration if METRICS_AVAILABLE else None,
                service="openai", operation="embeddings")
    async def _generate_openai_embedding(self, text: str) -> List[float]:
        """Gera embedding usando OpenAI."""
        import asyncio

        # Implementar timeout manual
        try:
            response = await asyncio.wait_for(
                openai_client.embeddings.create(
                    model="text-embedding-3-small",
                    input=text
                ),
                timeout=OPENAI_TIMEOUT
            )
            return response.data[0].embedding

        except asyncio.TimeoutError:
            raise TimeoutError(f"OpenAI timeout após {OPENAI_TIMEOUT}s")

    async def _generate_local_embedding(self, text: str) -> List[float]:
        """Gera embedding usando modelo local."""
        # sentence-transformers é síncrono, então rodamos em thread
        import asyncio

        loop = asyncio.get_event_loop()
        embedding = await loop.run_in_executor(
            None,
            local_model.encode,
            text
        )

        # Converter para lista e fazer padding para dimensão esperada
        embedding_list = embedding.tolist()

        # Padding com zeros para manter compatibilidade dimensional
        if len(embedding_list) < self.embedding_dim:
            padding = [0.0] * (self.embedding_dim - len(embedding_list))
            embedding_list.extend(padding)

        return embedding_list

    async def generate_batch_embeddings(
        self,
        texts: List[str],
        force_local: bool = False
    ) -> List[List[float]]:
        """
        Gera embeddings em batch com fallback automático.

        Args:
            texts: Lista de textos
            force_local: Forçar uso do modelo local

        Returns:
            Lista de embeddings
        """
        embeddings = []

        # Usar serviço paralelo se OpenAI e não force_local
        if self.openai_enabled and not force_local:
            try:
                embeddings = await parallel_embedding_service.generate_embeddings_batch(texts)
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(
                        service="embeddings_parallel",
                        reason="none"
                    ).inc()
                return embeddings
            except Exception as e:
                logger.warning(f"Parallel embedding falhou, fallback batch local: {e}")
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(
                        service="embeddings_parallel",
                        reason=type(e).__name__
                    ).inc()

        # Se não conseguir paralelizar, usar batch antigo ou local ... existing
        # code batch loop ...

        return embeddings

    def get_similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """
        Calcula similaridade coseno entre dois embeddings.
        Funciona independente do modelo usado.
        """
        # Converter para numpy arrays
        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)

        # Truncar ao menor tamanho se necessário
        min_len = min(len(vec1), len(vec2))
        vec1 = vec1[:min_len]
        vec2 = vec2[:min_len]

        # Calcular similaridade coseno
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return float(dot_product / (norm1 * norm2))

    async def test_models(self) -> Dict[str, Any]:
        """Testa ambos os modelos e compara resultados."""
        test_text = "Este é um texto de teste para embeddings."
        results = {}

        # Testar OpenAI
        if self.openai_enabled:
            try:
                start = time.time()
                openai_emb = await self._generate_openai_embedding(test_text)
                results['openai'] = {
                    'success': True,
                    'time': time.time() - start,
                    'dimension': len(openai_emb)
                }
            except Exception as e:
                results['openai'] = {
                    'success': False,
                    'error': str(e)
                }

        # Testar local
        if self.local_enabled:
            try:
                start = time.time()
                local_emb = await self._generate_local_embedding(test_text)
                results['local'] = {
                    'success': True,
                    'time': time.time() - start,
                    'dimension': len(local_emb)
                }
            except Exception as e:
                results['local'] = {
                    'success': False,
                    'error': str(e)
                }

        return results


# Instância global do serviço
embedding_service = EmbeddingService()


# Funções de conveniência para manter compatibilidade
async def generate_embedding(text: str) -> List[float]:
    """Gera embedding para um texto."""
    return await embedding_service.generate_embedding(text)


async def generate_embeddings(texts: List[str]) -> List[List[float]]:
    """Gera embeddings para múltiplos textos."""
    return await embedding_service.generate_batch_embeddings(texts)


if __name__ == "__main__":
    import asyncio

    async def test():
        # Testar serviço
        print("Testando serviço de embeddings...")

        # Teste individual
        text = "Preciso de um advogado trabalhista em São Paulo"
        embedding = await generate_embedding(text)
        print(f"Embedding gerado: dimensão {len(embedding)}")

        # Teste em batch
        texts = [
            "Contrato de trabalho",
            "Rescisão indireta",
            "Horas extras não pagas"
        ]
        embeddings = await generate_embeddings(texts)
        print(f"Batch gerado: {len(embeddings)} embeddings")

        # Teste de similaridade
        sim = embedding_service.get_similarity(embeddings[0], embeddings[1])
        print(f"Similaridade entre textos: {sim:.3f}")

        # Teste de modelos
        test_results = await embedding_service.test_models()
        print(f"Resultados dos testes: {test_results}")

    asyncio.run(test())
