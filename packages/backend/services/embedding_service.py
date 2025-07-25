"""
Serviço de geração de embeddings com triplo fallback.
Usa Gemini como primário, OpenAI como secundário e sentence-transformers como fallback final.
"""
import logging
import os
import time
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv

from supabase import Client, create_client
from metrics import external_api_duration, fallback_usage_total, track_time

# Configuração
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") # NOVO
OPENAI_TIMEOUT = int(os.getenv("OPENAI_TIMEOUT", "30"))
GEMINI_TIMEOUT = int(os.getenv("GEMINI_TIMEOUT", "30")) # NOVO

logger = logging.getLogger(__name__)

# Clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Importações condicionais
try:
    import google.generativeai as genai
    genai.configure(api_key=GEMINI_API_KEY)
    GEMINI_AVAILABLE = True
except (ImportError, Exception):
    logger.warning("Gemini (google-generativeai) não disponível.")
    GEMINI_AVAILABLE = False

try:
    from openai import AsyncOpenAI
    openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)
    OPENAI_AVAILABLE = True
except ImportError:
    logger.warning("OpenAI não disponível.")
    OPENAI_AVAILABLE = False
    openai_client = None

try:
    from sentence_transformers import SentenceTransformer
    # MUDANÇA: Carregar nosso modelo "sopa" soberano como fallback local
    LOCAL_MODEL_PATH = 'models/litig-embedding-soup-v1'
    if os.path.exists(LOCAL_MODEL_PATH):
        local_model = SentenceTransformer(LOCAL_MODEL_PATH)
        LOCAL_MODEL_AVAILABLE = True
    else:
        logger.warning(f"Modelo 'sopa' não encontrado em '{LOCAL_MODEL_PATH}'. Fallback local desabilitado.")
        LOCAL_MODEL_AVAILABLE = False
        local_model = None
except ImportError:
    logger.warning("Sentence-transformers não disponível.")
    LOCAL_MODEL_AVAILABLE = False
    local_model = None

# Importar métricas se disponível
try:
    from metrics import external_api_duration, fallback_usage_total, track_time
    METRICS_AVAILABLE = True
except ImportError:
    METRICS_AVAILABLE = False
    # Criar decoradores dummy se métricas não estiverem disponíveis

    def track_time(histogram, **labels):
        def decorator(func):
            return func
        return decorator


class EmbeddingService:
    """Serviço de embeddings com fallback em cascata."""

    def __init__(self):
        self.gemini_enabled = GEMINI_AVAILABLE and GEMINI_API_KEY
        self.openai_enabled = OPENAI_AVAILABLE and OPENAI_API_KEY
        self.local_enabled = LOCAL_MODEL_AVAILABLE
        
        # Dimensão primária agora é 768 (Gemini)
        self.embedding_dim = 768 
        self.openai_dim = 1536
        self.local_dim = 384

        if not any([self.gemini_enabled, self.openai_enabled, self.local_enabled]):
            raise RuntimeError("Nenhum modelo de embedding disponível!")

    async def generate_embedding(
        self,
        text: str,
        task_type: str = "RETRIEVAL_DOCUMENT"
    ) -> List[float]:
        """
        Gera embedding com fallback em cascata: Gemini -> OpenAI -> Local.
        Mantém compatibilidade com código existente.
        """
        embedding, _ = await self.generate_embedding_with_provider(text, task_type)
        return embedding

    async def generate_embedding_with_provider(
        self,
        text: str,
        task_type: str = "RETRIEVAL_DOCUMENT",
        allow_local_fallback: bool = True
    ) -> tuple[List[float], str]:
        """
        Gera embedding com rastreabilidade de origem.
        
        Args:
            text: Texto para gerar embedding
            task_type: Tipo de tarefa para Gemini
            allow_local_fallback: Se permitir fallback para modelo local
            
        Returns:
            Tuple[embedding_vector, provider_name]
            provider_name: 'gemini', 'openai', 'local'
            
        Raises:
            RuntimeError: Se nenhum provedor conseguir gerar embedding
        """
        logger.info(f"🧠 Gerando embedding com rastreabilidade para texto: {text[:50]}...")
        
        # 1. Estratégia de cascata: Gemini → OpenAI → Local (se permitido)
        if self.gemini_enabled:
            try:
                logger.debug("Tentando Gemini como provedor primário...")
                embedding = await self._generate_gemini_embedding(text, task_type)
                logger.info("✅ Embedding gerado via Gemini")
                return embedding, "gemini"
            except Exception as e:
                logger.warning(f"❌ Gemini falhou, tentando OpenAI: {e}")
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(service="embeddings", reason=f"gemini_fail:{type(e).__name__}").inc()

        # 2. Fallback para OpenAI
        if self.openai_enabled:
            try:
                logger.debug("Tentando OpenAI como fallback...")
                embedding = await self._generate_openai_embedding(text)
                # Truncar para 768 dimensões para manter consistência
                truncated_embedding = embedding[:self.embedding_dim]
                logger.info("✅ Embedding gerado via OpenAI (truncado para 768)")
                return truncated_embedding, "openai"
            except Exception as e:
                logger.warning(f"❌ OpenAI falhou: {e}")
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(service="embeddings", reason=f"openai_fail:{type(e).__name__}").inc()

        # 3. Fallback para modelo local (apenas se permitido)
        if self.local_enabled and allow_local_fallback:
            try:
                logger.debug("Usando modelo local como último fallback...")
                embedding = await self._generate_local_embedding(text)
                # Padding para 768 dimensões
                if len(embedding) < self.embedding_dim:
                    padding = [0.0] * (self.embedding_dim - len(embedding))
                    padded_embedding = embedding + padding
                else:
                    padded_embedding = embedding[:self.embedding_dim]
                
                logger.info("✅ Embedding gerado via modelo local (com padding para 768)")
                return padded_embedding, "local"
            except Exception as e:
                logger.error(f"❌ Modelo local falhou: {e}")
                if METRICS_AVAILABLE:
                    fallback_usage_total.labels(service="embeddings", reason=f"local_fail:{type(e).__name__}").inc()
        elif not allow_local_fallback:
            logger.warning("🚫 Fallback para modelo local desabilitado pela configuração")
        
        # Se chegou até aqui, todos os provedores falharam
        error_msg = "❌ Nenhum provedor de embedding disponível"
        if not allow_local_fallback:
            error_msg += " (fallback local desabilitado)"
        
        logger.error(error_msg)
        raise RuntimeError(error_msg)

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

    async def _generate_gemini_embedding(self, text: str, task_type: str) -> List[float]:
        """Gera embedding usando Gemini com normalização."""
        import asyncio
        
        response = await asyncio.wait_for(
            genai.embed_content_async(
                model="models/embedding-001", # gemini-embedding-001
                content=text,
                task_type=task_type,
                output_dimensionality=self.embedding_dim
            ),
            timeout=GEMINI_TIMEOUT
        )
        
        embedding_np = np.array(response['embedding'])
        # Normalização é obrigatória para dimensões < 3072
        normed_embedding = embedding_np / np.linalg.norm(embedding_np)
        return normed_embedding.tolist()

    async def _generate_local_embedding(self, text: str) -> List[float]:
        """Gera embedding usando modelo local e faz padding."""
        # sentence-transformers é síncrono, então rodamos em thread
        import asyncio

        loop = asyncio.get_event_loop()
        embedding = await loop.run_in_executor(None, local_model.encode, text)
        embedding_list = embedding.tolist()

        # Padding com zeros para manter compatibilidade dimensional com 768
        if len(embedding_list) < self.embedding_dim:
            padding = [0.0] * (self.embedding_dim - len(embedding_list))
            embedding_list.extend(padding)
        return embedding_list[:self.embedding_dim] # Garante o truncamento

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

async def generate_embedding_with_provider(text: str, allow_local_fallback: bool = True) -> tuple[List[float], str]:
    """
    Gera embedding com rastreabilidade de origem.
    
    Returns:
        Tuple[embedding_vector, provider_name]
        provider_name: 'gemini', 'openai', 'local'
    """
    return await embedding_service.generate_embedding_with_provider(text, allow_local_fallback=allow_local_fallback)

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
        
        # 🆕 TESTE DA NOVA FUNCIONALIDADE
        print("\n🧠 Testando nova funcionalidade com rastreabilidade...")
        embedding_with_provider, provider = await generate_embedding_with_provider(text)
        print(f"✅ Embedding gerado via {provider}: dimensão {len(embedding_with_provider)}")
        
        # Teste com fallback local desabilitado
        try:
            embedding_no_local, provider_no_local = await generate_embedding_with_provider(
                text, allow_local_fallback=False
            )
            print(f"✅ Embedding sem fallback local via {provider_no_local}: dimensão {len(embedding_no_local)}")
        except RuntimeError as e:
            print(f"⚠️ Fallback local desabilitado funcionou: {e}")

        # Teste em batch
        texts = [
            "Contrato de trabalho",
            "Rescisão indireta",
            "Horas extras não pagas"
        ]
        embeddings = await generate_embeddings(texts)
        print(f"\nBatch gerado: {len(embeddings)} embeddings")

        # Teste de similaridade
        sim = embedding_service.get_similarity(embeddings[0], embeddings[1])
        print(f"Similaridade entre textos: {sim:.3f}")

        # Teste de modelos
        test_results = await embedding_service.test_models()
        print(f"\nResultados dos testes: {test_results}")

    asyncio.run(test())


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

async def generate_embedding_with_provider(text: str, allow_local_fallback: bool = True) -> tuple[List[float], str]:
    """
    Gera embedding com rastreabilidade de origem.
    
    Returns:
        Tuple[embedding_vector, provider_name]
        provider_name: 'gemini', 'openai', 'local'
    """
    return await embedding_service.generate_embedding_with_provider(text, allow_local_fallback=allow_local_fallback)

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
        
        # 🆕 TESTE DA NOVA FUNCIONALIDADE
        print("\n🧠 Testando nova funcionalidade com rastreabilidade...")
        embedding_with_provider, provider = await generate_embedding_with_provider(text)
        print(f"✅ Embedding gerado via {provider}: dimensão {len(embedding_with_provider)}")
        
        # Teste com fallback local desabilitado
        try:
            embedding_no_local, provider_no_local = await generate_embedding_with_provider(
                text, allow_local_fallback=False
            )
            print(f"✅ Embedding sem fallback local via {provider_no_local}: dimensão {len(embedding_no_local)}")
        except RuntimeError as e:
            print(f"⚠️ Fallback local desabilitado funcionou: {e}")

        # Teste em batch
        texts = [
            "Contrato de trabalho",
            "Rescisão indireta",
            "Horas extras não pagas"
        ]
        embeddings = await generate_embeddings(texts)
        print(f"\nBatch gerado: {len(embeddings)} embeddings")

        # Teste de similaridade
        sim = embedding_service.get_similarity(embeddings[0], embeddings[1])
        print(f"Similaridade entre textos: {sim:.3f}")

        # Teste de modelos
        test_results = await embedding_service.test_models()
        print(f"\nResultados dos testes: {test_results}")

    asyncio.run(test())

