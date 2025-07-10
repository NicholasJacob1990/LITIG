#!/usr/bin/env python3
"""
Job para expirar ofertas pendentes que passaram do prazo.
Executa via cron job periodicamente (ex: a cada hora).

Uso:
    python3 backend/jobs/expire_offers.py

Cron:
    0 * * * * /usr/bin/python3 /path/to/project/backend/jobs/expire_offers.py
"""
import asyncio
import logging
import os
import sys
from datetime import datetime

from backend.services.offer_service import expire_pending_offers

# Adiciona o diretório raiz ao path para importar módulos
sys.path.append(
    os.path.dirname(
        os.path.dirname(
            os.path.dirname(
                os.path.abspath(__file__)))))


# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        # logging.FileHandler('logs/expire_offers.log'),  # Comentado - diretório
        # não existe
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)


async def main():
    """
    Função principal do job de expiração de ofertas.
    """
    logger.info("=== INICIANDO JOB DE EXPIRAÇÃO DE OFERTAS ===")
    start_time = datetime.utcnow()

    try:
        # Expira ofertas pendentes
        expired_count = await expire_pending_offers()

        end_time = datetime.utcnow()
        duration = (end_time - start_time).total_seconds()

        logger.info(f"Job concluído com sucesso!")
        logger.info(f"Ofertas expiradas: {expired_count}")
        logger.info(f"Duração: {duration:.2f} segundos")
        logger.info("=== FIM DO JOB DE EXPIRAÇÃO ===")

        return expired_count

    except Exception as e:
        logger.error(f"Erro durante a execução do job: {e}")
        logger.error("=== JOB FINALIZADO COM ERRO ===")
        raise


if __name__ == "__main__":
    # Cria diretório de logs se não existir
    os.makedirs("logs", exist_ok=True)

    try:
        result = asyncio.run(main())
        print(f"Job executado com sucesso. Ofertas expiradas: {result}")
        sys.exit(0)
    except Exception as e:
        print(f"Erro na execução do job: {e}")
        sys.exit(1)


# Tarefa Celery para agendamento automático
try:
    from backend.celery_app import celery_app

    @celery_app.task(name='backend.jobs.expire_offers.expire_offers_task')
    def expire_offers_task():
        """Tarefa Celery que executa o job de expiração de ofertas"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            # Executar o job assíncrono
            result = loop.run_until_complete(main())
            return {
                'status': 'success',
                'expired_count': result
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
