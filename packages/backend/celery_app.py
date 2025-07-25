# backend/celery_app.py
import os

from celery import Celery
from celery.schedules import crontab
from dotenv import load_dotenv

load_dotenv()

# Define a URL do Redis. Padrão para localhost se não estiver definida.
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Cria a instância do Celery
celery_app = Celery(
    "worker",
    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0"),
    backend=os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0"),
    include=[
        "packages.backend.tasks.triage_tasks",
        "packages.backend.tasks.jusbrasil_tasks",
        "packages.backend.tasks.firm_tasks"
    ]
)

# Configurações opcionais
celery_app.conf.update(
    task_track_started=True,
    result_expires=3600,  # Os resultados das tarefas expiram em 1 hora
    timezone='America/Sao_Paulo',
    enable_utc=True,
)

# Configurar tarefas periódicas
celery_app.conf.beat_schedule = {
    'expire-offers': {
        'task': 'backend.jobs.expire_offers.expire_offers_task',
        'schedule': crontab(minute=0),  # Toda hora
        'options': {'queue': 'periodic'}
    },
    'jusbrasil-sync': {
        'task': 'backend.jobs.jusbrasil_sync.sync_all_lawyers_task',
        'schedule': crontab(hour=3, minute=0),  # 3:00 AM diário
        'options': {'queue': 'periodic'}
    },
    'update-review-kpi': {
        'task': 'backend.jobs.update_review_kpi.update_kpi_task',
        'schedule': crontab(hour=4, minute=0),  # 4:00 AM diário
        'options': {'queue': 'periodic'}
    },
    'ltr-weekly': {
        'task': 'backend.jobs.ltr_weekly.run_weekly_ltr',
        'schedule': crontab(hour=2, minute=0, day_of_week='sat'),  # Sábado 02:00
        'options': {'queue': 'periodic'}
    },
    'calculate-equity': {
        'task': 'backend.jobs.calculate_equity.calculate_equity_task',
        'schedule': crontab(hour=2, minute=0),  # 2:00 AM diário
        'options': {'queue': 'periodic'}
    },
    'train-pca-embeddings': {
        'task': 'backend.jobs.train_pca_embeddings.train_pca_task',
        'schedule': crontab(hour=3, minute=30, day_of_week='sun'),
        'options': {'queue': 'periodic'}
    },
    'update-softskill': {
        'task': 'backend.jobs.sentiment_reviews.update_softskill',
        'schedule': crontab(hour=2, minute=10),
        'options': {'queue': 'periodic'}
    },
    'weekly-report': {
        'task': 'backend.jobs.automated_reports.generate_weekly_report',
        'schedule': crontab(day_of_week=1, hour=9, minute=0),  # Segunda-feira às 9h
        'options': {'queue': 'periodic'}
    },
    'monthly-report': {
        'task': 'backend.jobs.automated_reports.generate_monthly_report',
        'schedule': crontab(day_of_month=1, hour=10, minute=0),  # Dia 1 do mês às 10h
        'options': {'queue': 'periodic'}
    },
    'auto-retrain-ltr': {
        'task': 'backend.jobs.auto_retrain.auto_retrain_task',
        'schedule': crontab(day_of_week=0, hour=2, minute=0),  # Domingo às 2h
        'options': {'queue': 'periodic'}
    },
    'monitor-ab-tests': {
        'task': 'backend.jobs.auto_retrain.monitor_ab_tests',
        'schedule': crontab(minute='*/15'),  # A cada 15 minutos
        'options': {'queue': 'periodic'}
    },
    'cleanup-old-models': {
        'task': 'backend.jobs.auto_retrain.cleanup_old_models',
        'schedule': crontab(day_of_week=1, hour=3, minute=0),  # Segunda-feira às 3h
        'options': {'queue': 'periodic'}
    },
    'provider-weekly-notifications': {
        'task': 'provider_notifications.send_weekly_notifications',
        'schedule': crontab(day_of_week=1, hour=9, minute=0),  # Segunda-feira às 9h
        'options': {'queue': 'notifications'}
    },
    'cleanup-old-notifications': {
        'task': 'provider_notifications.cleanup_old_notifications',
        'schedule': crontab(day_of_month=1, hour=4, minute=0),  # Dia 1 do mês às 4h
        'options': {'queue': 'periodic'}
    },
}

if __name__ == "__main__":
    celery_app.start()
