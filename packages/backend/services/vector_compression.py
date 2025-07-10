"""Serviço de compressão de embeddings usando PCA.
Reduz dimensionalidade de 1536 → 512 (por padrão) e persiste modelo em disco.
"""

from __future__ import annotations

import os
from typing import List

import joblib
import numpy as np
from sklearn.decomposition import PCA

DEFAULT_COMPONENTS = int(os.getenv("PCA_COMPONENTS", "512"))
MODEL_PATH = os.getenv("PCA_MODEL_PATH", "models/pca_compression.pkl")


class VectorCompressionService:
    """Service para compressão/expansão de vetores."""

    def __init__(self, n_components: int = DEFAULT_COMPONENTS):
        self.n_components = n_components
        self.pca: PCA | None = None
        self.is_fitted = False

        # Carregar modelo se existir
        if os.path.exists(MODEL_PATH):
            self.pca = joblib.load(MODEL_PATH)
            self.is_fitted = True

    def fit(self, embeddings: List[List[float]]):
        """Treina modelo PCA e persiste em disco."""
        embeddings_arr = np.array(embeddings)
        self.pca = PCA(n_components=self.n_components)
        self.pca.fit(embeddings_arr)
        self.is_fitted = True
        # Persistir modelo
        os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
        joblib.dump(self.pca, MODEL_PATH)

    def compress(self, embedding: List[float]) -> List[float]:
        """Comprime embedding para dimensões reduzidas."""
        if not self.is_fitted or self.pca is None:
            raise RuntimeError(
                "PCA ainda não foi treinado. Chame fit() primeiro ou carregue o modelo.")
        emb_arr = np.array(embedding).reshape(1, -1)
        compressed = self.pca.transform(emb_arr)
        return compressed[0].tolist()

    def decompress(self, compressed_embedding: List[float]) -> List[float]:
        """Reconstrói embedding aproximado (para debug)."""
        if not self.is_fitted or self.pca is None:
            raise RuntimeError(
                "PCA ainda não foi treinado. Chame fit() primeiro ou carregue o modelo.")
        decomp = self.pca.inverse_transform(
            np.array(compressed_embedding).reshape(1, -1))
        return decomp[0].tolist()


# Instância singleton
vector_compression_service = VectorCompressionService()
