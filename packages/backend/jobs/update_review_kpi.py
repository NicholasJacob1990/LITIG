#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Job: Atualização de KPI de Reviews - Fase 9
===========================================
Job noturno para atualizar kpi.avaliacao_media dos advogados baseado nas reviews.
Executa às 02:00 UTC para não conflitar com o job do Jusbrasil (03:00 UTC).

Comando para agendar no cron:
0 2 * * * /usr/bin/python3 /path/to/backend/jobs/update_review_kpi.py
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

from backend.config import settings
from supabase import create_client, Client

# Adicionar o diretório backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.append(str(backend_dir))


# Configurar logging estruturado
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[logging.StreamHandler()]
)

logger = logging.getLogger(__name__)


class ReviewKPIUpdater:
    """Atualizador de KPIs de reviews dos advogados."""

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )
        self.start_time = datetime.utcnow()

    def log_structured(self, level: str, message: str, **kwargs):
        """Log estruturado em JSON."""
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": level,
            "service": "review_kpi_updater",
            "message": message,
            "job_id": f"review_kpi_{self.start_time.strftime('%Y%m%d_%H%M%S')}",
            **kwargs
        }
        logger.info(json.dumps(log_data))

    async def update_all_lawyers_kpi(self) -> dict:
        """
        Atualiza o KPI avaliacao_media para todos os advogados.

        Returns:
            dict: Estatísticas da execução
        """
        try:
            self.log_structured("INFO", "Iniciando atualização de KPIs de reviews")

            # Chamar a função SQL criada na migração
            result = self.supabase.rpc('update_lawyers_review_kpi').execute()

            if result.data is None:
                updated_count = 0
            else:
                updated_count = result.data

            stats = {
                "updated_lawyers": updated_count,
                "start_time": self.start_time.isoformat(),
                "end_time": datetime.utcnow().isoformat(),
                "duration_seconds": (datetime.utcnow() - self.start_time).total_seconds(),
                "success": True
            }

            self.log_structured(
                "INFO",
                "KPI de reviews atualizado com sucesso",
                **stats
            )

            return stats

        except Exception as e:
            error_stats = {
                "error": str(e),
                "error_type": type(e).__name__,
                "start_time": self.start_time.isoformat(),
                "end_time": datetime.utcnow().isoformat(),
                "duration_seconds": (datetime.utcnow() - self.start_time).total_seconds(),
                "success": False
            }

            self.log_structured(
                "ERROR",
                "Erro ao atualizar KPI de reviews",
                **error_stats
            )

            raise


async def main():
    """Função principal do job."""
    updater = ReviewKPIUpdater()

    try:
        # Atualizar KPIs
        update_stats = await updater.update_all_lawyers_kpi()

        # Log final
        updater.log_structured(
            "INFO",
            "Job de atualização de KPI de reviews concluído",
            update_stats=update_stats
        )

        # Exit code baseado no sucesso
        exit_code = 0 if update_stats.get("success", False) else 1
        sys.exit(exit_code)

    except Exception as e:
        updater.log_structured(
            "ERROR",
            "Falha crítica no job de KPI de reviews",
            error=str(e),
            error_type=type(e).__name__
        )
        sys.exit(1)

if __name__ == "__main__":
    # Verificar variáveis de ambiente necessárias
    required_vars = ["SUPABASE_URL", "SUPABASE_SERVICE_KEY"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        print(f"Erro: Variáveis de ambiente faltando: {', '.join(missing_vars)}")
        sys.exit(1)

    # Executar job
    asyncio.run(main())

# Tarefa Celery para agendamento automático
try:
    from backend.celery_app import celery_app

    @celery_app.task(name='backend.jobs.update_review_kpi.update_kpi_task')
    def update_kpi_task():
        """Tarefa Celery que executa a atualização de KPIs de reviews"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            # Executar o job assíncrono
            loop.run_until_complete(main())
            return {
                'status': 'success',
                'message': 'KPIs de reviews atualizados com sucesso'
            }
        except Exception as e:
            logger.error(f"Erro na tarefa Celery: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
        finally:
            loop.close()
except ImportError:
    # Se não conseguir importar Celery, continua funcionando como script standalone
    pass
