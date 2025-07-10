from celery.schedules import crontab

# Configuração de tarefas periódicas
CELERY_BEAT_SCHEDULE = {
    # ... existing schedules ...

    # Sincronização com Jusbrasil
    'sync-jusbrasil-daily': {
        'task': 'backend.jobs.jusbrasil_sync.sync_all_lawyers_task',
        'schedule': crontab(hour=2, minute=0),  # Todo dia às 2:00 AM
        'options': {'queue': 'jusbrasil'},
    },

    # Sincronização incremental (mais frequente para casos urgentes)
    'sync-jusbrasil-incremental': {
        'task': 'backend.jobs.jusbrasil_sync.sync_incremental_task',
        'schedule': crontab(minute=0, hour='*/6'),  # A cada 6 horas
        'options': {'queue': 'jusbrasil'},
    },

    # Limpeza de dados antigos
    'cleanup-jusbrasil-data': {
        'task': 'backend.jobs.jusbrasil_sync.cleanup_old_data_task',
        'schedule': crontab(hour=1, minute=0, day_of_week=1),  # Toda segunda às 1:00 AM
        'options': {'queue': 'maintenance'},
    },
}

# Configuração de filas
CELERY_TASK_ROUTES = {
    # ... existing routes ...

    # Fila específica para tarefas do Jusbrasil
    'backend.jobs.jusbrasil_sync.*': {'queue': 'jusbrasil'},
}

# Configuração de rate limiting para API do Jusbrasil
CELERY_TASK_ANNOTATIONS = {
    # ... existing annotations ...

    'backend.jobs.jusbrasil_sync.sync_all_lawyers_task': {
        'rate_limit': '1/m',  # 1 execução por minuto
        'time_limit': 3600,   # 1 hora de timeout
        'soft_time_limit': 3000,  # 50 minutos de soft limit
    },

    'backend.jobs.jusbrasil_sync.sync_incremental_task': {
        'rate_limit': '4/h',  # 4 execuções por hora
        'time_limit': 1800,   # 30 minutos de timeout
        'soft_time_limit': 1500,  # 25 minutos de soft limit
    },
}
