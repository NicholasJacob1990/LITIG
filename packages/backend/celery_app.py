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
        "packages.backend.tasks.firm_tasks",
        "packages.backend.jobs.enrich_lawyer_profiles",  # 🆕 V2.1: Background enrichment jobs
        "packages.backend.jobs.case_match_retrain"  # 🆕 AutoML: Case matching retrain jobs
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
    # 🔧 SOFT SKILLS OTIMIZADO - 3x por semana ao invés de diário
    'update-softskill': {
        'task': 'backend.jobs.sentiment_reviews.update_softskill',
        'schedule': crontab(hour=2, minute=10, day_of_week='0,2,4'),  # Dom/Ter/Qui - Economia 57% CPU
        'options': {'queue': 'feature-engineering', 'priority': 4}
    },
    # 🆕 IEP (ÍNDICE DE ENGAJAMENTO) - CRÍTICO PARA TODOS ALGORITMOS
    'calculate-iep-daily': {
        'task': 'backend.jobs.calculate_engagement_scores.calculate_iep_task',
        'schedule': crontab(hour=5, minute=0),  # Diário às 5h
        'options': {'queue': 'analytics', 'priority': 9}
    },
    # 🆕 GEO FEATURES - LOCALIZAÇÃO E PROXIMIDADE
    'update-geo-features': {
        'task': 'backend.jobs.geo_updater.update_geo_features_task',
        'schedule': crontab(hour=4, minute=0),  # Diário às 4h  
        'options': {'queue': 'feature-engineering', 'priority': 5}
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
    # 🆕 Partnership ML Jobs - OTIMIZADO
    'auto-retrain-partnerships-full': {
        'task': 'backend.jobs.partnership_retrain.auto_retrain_partnerships_task',
        'schedule': crontab(hour=1, minute=0, day_of_week='0,3'),  # Dom/Qua 1h - Retreino completo
        'options': {'queue': 'ml-training', 'priority': 7}
    },
    'auto-retrain-partnerships-quick': {
        'task': 'backend.jobs.partnership_retrain.quick_weights_update_task',
        'schedule': crontab(hour=1, minute=30),  # Diário 1:30h - Ajuste rápido de pesos
        'options': {'queue': 'ml-quick', 'priority': 8}
    },
    'partnership-performance-report': {
        'task': 'backend.jobs.partnership_retrain.generate_performance_report',
        'schedule': crontab(day_of_week=1, hour=9, minute=30),  # Segunda-feira às 9:30h
        'options': {'queue': 'periodic'}
    },
    # 🆕 Case Match AutoML Jobs - Conforme PLANO_ACAO_AUTOML_ALGORITMO_MATCH.md
    'auto-retrain-case-matching': {
        'task': 'case_match_retrain.auto_retrain_case_matching_task',
        'schedule': crontab(hour=2, minute=0),  # Diário às 2h (após partnerships)
        'options': {'queue': 'ml-training', 'priority': 7}
    },
    'case-match-performance-report': {
        'task': 'case_match_retrain.generate_performance_report',
        'schedule': crontab(day_of_week=1, hour=9, minute=45),  # Segunda-feira às 9:45h
        'options': {'queue': 'periodic'}
    },
    'case-match-health-check': {
        'task': 'case_match_retrain.validate_model_health',
        'schedule': crontab(minute='*/30'),  # A cada 30 minutos (conforme plano)
        'options': {'queue': 'monitoring', 'priority': 9}
    },
    'partnership-health-check': {
        'task': 'backend.jobs.partnership_retrain.validate_model_health',
        'schedule': crontab(minute='*/30'),  # A cada 30 minutos
        'options': {'queue': 'periodic'}
    },
    'cleanup-old-models': {
        'task': 'backend.jobs.auto_retrain.cleanup_old_models',
        'schedule': crontab(day_of_week=1, hour=3, minute=0),  # Segunda-feira às 3h
        'options': {'queue': 'periodic'}
    },
    # 🆕 V2.1: Enriquecimento de Perfis Automatizado
    'enrich-active-lawyers-weekly': {
        'task': 'enrich_all_active_lawyers',
        'schedule': crontab(day_of_week=0, hour=6, minute=0),  # Domingo às 6h
        'kwargs': {'batch_size': 25, 'search_depth': 'quick'},
        'options': {'queue': 'enrichment', 'priority': 5}
    },
    # 🆕 V2.1: Enriquecimento de Perfis VIP (mensal, busca profunda)
    'enrich-vip-profiles-monthly': {
        'task': 'enrich_lawyer_profiles_batch',
        'schedule': crontab(day_of_month=1, hour=7, minute=0),  # Dia 1 do mês às 7h
        'kwargs': {
            'lawyer_ids': [],  # Será preenchido dinamicamente com IDs VIP
            'enable_web_search': True,
            'search_depth': 'standard'
        },
        'options': {'queue': 'enrichment', 'priority': 6}
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
    # 🔧 CLUSTERING OTIMIZADO - Economia 30% CPU
    'cluster-generation-cases': {
        'task': 'backend.jobs.cluster_generation_job.run_cluster_generation',
        'schedule': crontab(hour='0,8,16'),  # A cada 8 horas (vs. 6h) - Economia 25% CPU
        'args': ('case',),
        'options': {'queue': 'clustering', 'priority': 6}
    },
    'cluster-generation-lawyers': {
        'task': 'backend.jobs.cluster_generation_job.run_cluster_generation',
        'schedule': crontab(hour='2,14'),  # A cada 12 horas (vs. 8h) - Economia 33% CPU
        'args': ('lawyer',),
        'options': {'queue': 'clustering', 'priority': 6}
    },
}

if __name__ == "__main__":
    celery_app.start()
