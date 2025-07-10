"""
Tarefa Celery para expirar ofertas automaticamente
"""
import asyncio

from backend.celery_app import celery_app
from backend.jobs.expire_offers import expire_offers_job


@celery_app.task(name='backend.jobs.expire_offers.expire_offers_task')
def expire_offers_task():
    """Tarefa Celery que executa o job de expiração de ofertas"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    try:
        # Executar o job assíncrono
        result = loop.run_until_complete(expire_offers_job())
        return {
            'status': 'success',
            'expired_count': result
        }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e)
        }
    finally:
        loop.close()
