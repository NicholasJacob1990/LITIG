# -*- coding: utf-8 -*-
"""
Configuração Otimizada de Retreino para Algoritmos LITIG
========================================================

Baseado em análise de performance, volume de dados e recursos computacionais.
"""

from celery.schedules import crontab

# ========================================================================
# 1. ALGORITMO PRINCIPAL (LTR) - Matching Advogado↔Caso
# ========================================================================
LTR_RETRAIN_CONFIG = {
    "schedule": crontab(day_of_week=0, hour=2, minute=0),  # Domingo 2h
    "data_collection": {
        "window_days": 14,              # ✅ 14 dias (vs. 30 atual)
        "min_samples": 200,             # ✅ 200 samples (vs. 100)
        "feedback_types": ["accepted", "declined", "completed"],
        "quality_threshold": 0.75       # nDCG@5 mínimo
    },
    "training": {
        "algorithm": "LGBMRanker",      # ✅ Mantém atual
        "max_time_hours": 2,
        "cross_validation": 5,
        "early_stopping": True
    },
    "validation": {
        "holdout_ratio": 0.2,
        "ab_test_duration_days": 7,
        "rollback_threshold": 0.05      # Se performance cair >5%
    }
}

# ========================================================================
# 2. ALGORITMO DE PARCERIAS - Matching Advogado↔Advogado  
# ========================================================================
PARTNERSHIP_RETRAIN_CONFIG = {
    # Retreino Completo (a cada 3 dias)
    "full_retrain": {
        "schedule": crontab(hour=1, minute=0, day_of_week="0,3"),  # Dom/Qua 1h
        "data_collection": {
            "window_days": 14,          # ✅ 14 dias (vs. 7 atual)  
            "min_samples": 75,          # ✅ 75 samples (vs. 50)
            "include_external": True    # Perfis externos via LLM
        },
        "ml_optimization": {
            "gradient_descent_steps": 100,
            "learning_rate": 0.01,
            "convergence_threshold": 0.001
        }
    },
    
    # Atualização Rápida (diária)  
    "quick_update": {
        "schedule": crontab(hour=1, minute=30),  # Diário 1:30h
        "operation": "weights_only",             # Apenas ajuste de pesos
        "min_samples": 20,                      # Feedback mínimo
        "max_time_minutes": 15                  # Execução rápida
    }
}

# ========================================================================
# 3. CLUSTERING - Agrupamento de Entidades
# ========================================================================
CLUSTERING_CONFIG = {
    "lawyer_clusters": {
        "schedule": crontab(hour="2,14"),       # ✅ 12h (vs. 8h)
        "algorithm": "hierarchical_clustering",
        "max_clusters": 50,
        "trigger_recommendations": True         # Dispara recomendações
    },
    
    "case_clusters": {
        "schedule": crontab(hour="0,8,16"),     # ✅ 8h (vs. 6h)
        "algorithm": "kmeans_plus",
        "incremental": True,                    # Não recalcula tudo
        "new_cases_threshold": 10               # Min casos para re-cluster
    }
}

# ========================================================================
# 4. FEATURES E EMBEDDINGS - Atualização de Características
# ========================================================================
FEATURES_CONFIG = {
    "embeddings_pca": {
        "schedule": crontab(day_of_week=0, hour=3, minute=30),  # ✅ Semanal
        "dimensions": 256,
        "variance_threshold": 0.95
    },
    
    "soft_skills": {
        "schedule": crontab(hour=2, minute=10, day_of_week="0,2,4"),  # ✅ 3x/semana
        "sentiment_analysis": True,
        "batch_size": 100
    },
    
    "geo_features": {
        "schedule": crontab(hour=4, minute=0),  # ✅ Diário
        "address_validation": True,
        "distance_matrix_update": True
    },
    
    "lawyer_availability": {
        "schedule": crontab(minute="*/30"),     # ✅ 30min (tempo real)
        "working_hours_only": True,
        "timezone_aware": True
    }
}

# ========================================================================
# 5. ÍNDICE DE ENGAJAMENTO (IEP) - Recém implementado
# ========================================================================
ENGAGEMENT_CONFIG = {
    "iep_calculation": {
        "schedule": crontab(hour=5, minute=0),  # ✅ Diário 5h
        "metrics": [
            "responsiveness", "activity", "initiative", 
            "completion_rate", "revenue_share", "community"
        ],
        "window_days": 30,                      # Histórico de engajamento
        "trend_analysis": True
    }
}

# ========================================================================
# 6. MONITORAMENTO E HEALTH CHECKS
# ========================================================================
MONITORING_CONFIG = {
    "model_health": {
        "schedule": crontab(minute="*/15"),     # ✅ 15min
        "metrics": ["latency", "accuracy", "availability"],
        "alert_thresholds": {
            "latency_p95_ms": 50,
            "accuracy_drop": 0.05,
            "error_rate": 0.01
        }
    },
    
    "data_quality": {
        "schedule": crontab(hour="*/2"),        # ✅ 2h
        "checks": ["completeness", "consistency", "freshness"],
        "auto_correction": True
    }
}

# ========================================================================
# 7. CONFIGURAÇÃO ADAPTATIVA BASEADA EM VOLUME
# ========================================================================
ADAPTIVE_CONFIG = {
    "volume_thresholds": {
        "low": {"samples_per_day": 50, "retrain_frequency": "weekly"},
        "medium": {"samples_per_day": 200, "retrain_frequency": "3_days"},  
        "high": {"samples_per_day": 500, "retrain_frequency": "daily"},
        "very_high": {"samples_per_day": 1000, "retrain_frequency": "12_hours"}
    },
    
    "auto_scaling": {
        "enable": True,
        "monitor_window_hours": 24,
        "adjustment_factor": 1.5                # Multiplicador para recursos
    }
}

# ========================================================================
# 8. INTEGRAÇÃO COM CELERY
# ========================================================================
CELERY_BEAT_SCHEDULE_OPTIMIZED = {
    # LTR Principal
    'auto-retrain-ltr-optimized': {
        'task': 'backend.jobs.auto_retrain.auto_retrain_task',
        'schedule': LTR_RETRAIN_CONFIG["schedule"],
        'options': {'queue': 'ml-training', 'priority': 9}
    },
    
    # Parcerias - Retreino Completo
    'partnership-retrain-full': {
        'task': 'backend.jobs.partnership_retrain.auto_retrain_partnerships_task',
        'schedule': PARTNERSHIP_RETRAIN_CONFIG["full_retrain"]["schedule"],
        'options': {'queue': 'ml-training', 'priority': 7}
    },
    
    # Parcerias - Atualização Rápida  
    'partnership-update-quick': {
        'task': 'backend.jobs.partnership_retrain.quick_weights_update',
        'schedule': PARTNERSHIP_RETRAIN_CONFIG["quick_update"]["schedule"],
        'options': {'queue': 'ml-quick', 'priority': 8}
    },
    
    # Clustering Otimizado
    'cluster-lawyers-optimized': {
        'task': 'backend.jobs.cluster_generation_job.run_cluster_generation',
        'schedule': CLUSTERING_CONFIG["lawyer_clusters"]["schedule"],
        'args': ('lawyer',),
        'options': {'queue': 'clustering', 'priority': 6}
    },
    
    'cluster-cases-optimized': {
        'task': 'backend.jobs.cluster_generation_job.run_cluster_generation', 
        'schedule': CLUSTERING_CONFIG["case_clusters"]["schedule"],
        'args': ('case',),
        'options': {'queue': 'clustering', 'priority': 6}
    },
    
    # Features Otimizadas
    'embeddings-weekly': {
        'task': 'backend.jobs.train_pca_embeddings.train_pca_task',
        'schedule': FEATURES_CONFIG["embeddings_pca"]["schedule"],
        'options': {'queue': 'feature-engineering', 'priority': 5}
    },
    
    'soft-skills-3x-week': {
        'task': 'backend.jobs.sentiment_reviews.update_softskill',
        'schedule': FEATURES_CONFIG["soft_skills"]["schedule"],
        'options': {'queue': 'feature-engineering', 'priority': 4}
    },
    
    'geo-features-daily': {
        'task': 'backend.jobs.geo_updater.update_geo_features',
        'schedule': FEATURES_CONFIG["geo_features"]["schedule"],
        'options': {'queue': 'feature-engineering', 'priority': 4}
    },
    
    # IEP - Índice de Engajamento
    'iep-calculation-daily': {
        'task': 'backend.jobs.calculate_engagement_scores.calculate_iep_task',
        'schedule': ENGAGEMENT_CONFIG["iep_calculation"]["schedule"],
        'options': {'queue': 'analytics', 'priority': 3}
    },
    
    # Monitoramento
    'model-health-check': {
        'task': 'backend.jobs.model_monitoring.health_check_task',
        'schedule': MONITORING_CONFIG["model_health"]["schedule"],
        'options': {'queue': 'monitoring', 'priority': 10}
    }
}

# ========================================================================
# 9. MÉTRICAS DE SUCESSO POR ALGORITMO
# ========================================================================
SUCCESS_METRICS = {
    "ltr_algorithm": {
        "primary": "ndcg_at_5",
        "threshold": 0.75,
        "secondary": ["precision_at_3", "recall_at_10", "fairness_gap"]
    },
    
    "partnership_algorithm": {
        "primary": "recommendation_acceptance_rate", 
        "threshold": 0.25,
        "secondary": ["cluster_coherence", "diversity_score"]
    },
    
    "engagement_index": {
        "primary": "correlation_with_success",
        "threshold": 0.6,
        "secondary": ["score_stability", "trend_prediction"]
    }
}

# ========================================================================
# 10. CONFIGURAÇÃO DE EMERGÊNCIA
# ========================================================================
EMERGENCY_CONFIG = {
    "fallback_models": {
        "enable": True,
        "max_age_hours": 72,                    # Modelo max 3 dias
        "performance_threshold": 0.7            # Performance mínima
    },
    
    "circuit_breaker": {
        "error_rate_threshold": 0.05,          # 5% erro = fallback
        "timeout_seconds": 30,
        "recovery_attempts": 3
    },
    
    "manual_override": {
        "enable": True,
        "require_approval": True,
        "audit_log": True
    }
}

if __name__ == "__main__":
    print("🎯 CONFIGURAÇÃO OTIMIZADA DE RETREINO")
    print("=" * 50)
    print(f"✅ LTR Principal: {LTR_RETRAIN_CONFIG['schedule']}")
    print(f"✅ Parcerias (Completo): {PARTNERSHIP_RETRAIN_CONFIG['full_retrain']['schedule']}")
    print(f"✅ Parcerias (Rápido): {PARTNERSHIP_RETRAIN_CONFIG['quick_update']['schedule']}")
    print(f"✅ Clustering Lawyers: {CLUSTERING_CONFIG['lawyer_clusters']['schedule']}")
    print(f"✅ Clustering Cases: {CLUSTERING_CONFIG['case_clusters']['schedule']}")
    print(f"✅ Embeddings: {FEATURES_CONFIG['embeddings_pca']['schedule']}")
    print(f"✅ Soft Skills: {FEATURES_CONFIG['soft_skills']['schedule']}")
    print(f"✅ IEP: {ENGAGEMENT_CONFIG['iep_calculation']['schedule']}")
    print("=" * 50)
    print("🚀 Configuração otimizada para máximo performance e eficiência!") 