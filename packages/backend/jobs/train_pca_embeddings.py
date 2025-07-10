import logging
import os
from datetime import datetime
from typing import List

import numpy as np
from celery import shared_task
from dotenv import load_dotenv

from backend.metrics import job_executions_total
from backend.services.vector_compression import vector_compression_service
from supabase import Client, create_client

load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

logger = logging.getLogger(__name__)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# -------------------------------------------
# Celery Task
# -------------------------------------------


@shared_task(name="backend.jobs.train_pca_embeddings.train_pca_task", bind=True)
def train_pca_task(self):
    """Treina PCA sobre embeddings existentes e atualiza colunas comprimidas."""
    job_name = "train_pca"
    try:
        logger.info("🏁 Iniciando treinamento PCA para compressão de embeddings")

        # 1. Coletar embeddings das tabelas
        case_rows = supabase.table("cases").select(
            "id, summary_embedding").limit(2000).execute().data or []
        lawyer_rows = supabase.table("lawyers").select(
            "id, casos_historicos_embeddings").limit(2000).execute().data or []

        embeddings: List[List[float]] = []
        for row in case_rows:
            emb = row.get("summary_embedding")
            if emb:
                embeddings.append(emb[:1536])  # garantir tamanho
        for row in lawyer_rows:
            hist = row.get("casos_historicos_embeddings", [])
            if hist:
                embeddings.extend([e[:1536] for e in hist[:3]])  # amostra

        if len(embeddings) < 100:
            logger.warning(
                "Embeddings insuficientes para treinar PCA (>=100 necessários)")
            job_executions_total.labels(job_name=job_name, status="skipped").inc()
            return "skipped"

        # 2. Treinar PCA
        vector_compression_service.fit(embeddings)
        logger.info("✅ PCA treinado com %d embeddings", len(embeddings))

        # 3. Atualizar colunas comprimidas (casos)
        for row in case_rows:
            emb = row.get("summary_embedding")
            if not emb:
                continue
            comp = vector_compression_service.compress(emb[:1536])
            supabase.table("cases").update(
                {"embedding_compressed": comp}).eq("id", row["id"]).execute()

        # 4. Atualizar advogados
        for row in lawyer_rows:
            hist = row.get("casos_historicos_embeddings", [])
            if not hist:
                continue
            compressed_list = [vector_compression_service.compress(
                e[:1536]) for e in hist[:1]]  # pegar último
            supabase.table("lawyers").update(
                {"embedding_compressed": compressed_list[0]}).eq("id", row["id"]).execute()

        job_executions_total.labels(job_name=job_name, status="success").inc()
        logger.info("🎉 Compressão de embeddings concluída com sucesso")
        return "success"

    except Exception as exc:
        logger.exception("Erro crítico no treinamento PCA: %s", exc)
        job_executions_total.labels(job_name=job_name, status="failed").inc()
        # Registrar retries automáticos
        raise self.retry(exc=exc, countdown=300, max_retries=3)
