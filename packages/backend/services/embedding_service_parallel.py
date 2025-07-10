"""
Serviço de geração de embeddings em paralelo usando httpx + asyncio.
Permite até BATCH_SIZE requisições simultâneas à API OpenAI, com controle
por semáforo para evitar estouro de limite.
"""
from __future__ import annotations

import asyncio
import os
from asyncio import Semaphore
from typing import List

import httpx
from dotenv import load_dotenv

from backend.metrics import external_api_duration, fallback_usage_total

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small")

# Concurrency
MAX_CONCURRENT_REQUESTS = int(os.getenv("EMBEDDING_BATCH_SIZE", "10"))
POOL_SIZE = max(1, MAX_CONCURRENT_REQUESTS // 2)  # metade do batch para pool
TIMEOUT = int(os.getenv("OPENAI_TIMEOUT", "30"))

# ---------------------------------------------------------------------------
# Parallel Embedding Service
# ---------------------------------------------------------------------------


class ParallelEmbeddingService:
    """Gera embeddings em paralelo com limite de simultaneidade."""

    def __init__(self, max_concurrency: int = MAX_CONCURRENT_REQUESTS):
        self.semaphore = Semaphore(max_concurrency)
        self.session_pool = [
            httpx.AsyncClient(
                timeout=TIMEOUT) for _ in range(POOL_SIZE)]

    async def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Gera embeddings para uma lista de textos em paralelo."""
        tasks = []
        for i, txt in enumerate(texts):
            session = self.session_pool[i % len(self.session_pool)]
            tasks.append(self._generate_single_embedding(session, txt))

        embeddings = await asyncio.gather(*tasks, return_exceptions=True)

        # Tratar erros e métricas
        valid_embeddings: List[List[float]] = []
        for emb in embeddings:
            if isinstance(emb, Exception):
                fallback_usage_total.labels(service="openai", reason="error").inc()
            else:
                valid_embeddings.append(emb)

        return valid_embeddings

    async def _generate_single_embedding(
            self, session: httpx.AsyncClient, text: str) -> List[float]:
        """Faz uma única chamada à API OpenAI para gerar embedding."""
        async with self.semaphore:
            labels = {"service": "openai", "operation": "embedding"}
            with external_api_duration.labels(**labels).time():
                headers = {
                    "Authorization": f"Bearer {OPENAI_API_KEY}",
                    "Content-Type": "application/json",
                }
                payload = {"model": EMBEDDING_MODEL, "input": text}
                try:
                    resp = await session.post("https://api.openai.com/v1/embeddings", json=payload, headers=headers)
                    resp.raise_for_status()
                    data = resp.json()
                    return data["data"][0]["embedding"]
                except Exception as exc:
                    raise exc

    async def aclose(self):
        """Fecha todas as conexões httpx."""
        await asyncio.gather(*[client.aclose() for client in self.session_pool])


# Instância singleton para uso pela aplicação
parallel_embedding_service = ParallelEmbeddingService()
