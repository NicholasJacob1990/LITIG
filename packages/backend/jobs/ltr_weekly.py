#!/usr/bin/env python3
"""
Job semanal de re-treino do Ranker LTR.
Executa exportação de dados, treinamento offline e atualização online dos pesos.
É executado via Celery Beat aos sábados às 02:00 (configurado em backend/celery_app.py).
"""
import logging
import os
import subprocess
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


def _run(cmd: str) -> None:
    """Executa comando shell e lança erro se exit≠0."""
    result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
    logger.info(result.stdout.strip())


def run_weekly_pipeline() -> None:
    """Executa as três etapas do pipeline LTR semanal (export > train > update)."""
    logger.info("=== INICIANDO PIPELINE LTR SEMANAL ===")
    start = datetime.utcnow()

    cmds = [
        "python backend/jobs/ltr_export.py",
        "python backend/jobs/ltr_train.py",
        "python backend/jobs/ltr_online_update.py",
    ]
    for c in cmds:
        logger.info("Executando: %s", c)
        _run(c)

    duration = (datetime.utcnow() - start).total_seconds()
    logger.info("✅ Pipeline LTR concluído em %.2f s", duration)


# Tarefa Celery
try:
    from backend.celery_app import celery_app  # noqa: E402

    @celery_app.task(name="backend.jobs.ltr_weekly.run_weekly_ltr")
    def run_weekly_ltr_task():  # type: ignore
        run_weekly_pipeline()

except ImportError:  # pragma: no cover
    pass


if __name__ == "__main__":
    run_weekly_pipeline()
