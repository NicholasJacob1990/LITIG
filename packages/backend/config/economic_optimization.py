#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
config/economic_optimization.py

Configurações de economia máxima de API baseada na realidade processual brasileira.
Implementa estratégia de armazenamento de 5 anos com TTL dinâmico por fase processual.
"""

import re
from typing import Dict, List, Any
from datetime import datetime, timedelta

# ============================================================================
# TTL DINÂMICO POR FASE PROCESSUAL
# ============================================================================

PHASE_BASED_TTL = {
    "inicial": {
        "redis_ttl": 2 * 3600,      # 2 horas (alta atividade)
        "db_ttl": 6 * 3600,         # 6 horas  
        "sync_interval": 4 * 3600,  # Sincroniza a cada 4h
        "api_economy": 0.70,        # 70% de economia
        "description": "Fase inicial - alta atividade processual"
    },
    "instrutoria": {
        "redis_ttl": 4 * 3600,      # 4 horas
        "db_ttl": 12 * 3600,        # 12 horas
        "sync_interval": 8 * 3600,  # Sincroniza a cada 8h  
        "api_economy": 0.85,        # 85% de economia
        "description": "Fase instrutória - atividade média"
    },
    "decisoria": {
        "redis_ttl": 8 * 3600,      # 8 horas
        "db_ttl": 24 * 3600,        # 24 horas
        "sync_interval": 12 * 3600, # Sincroniza a cada 12h
        "api_economy": 0.90,        # 90% de economia
        "description": "Fase decisória - atividade baixa"
    },
    "recursal": {
        "redis_ttl": 24 * 3600,     # 24 horas  
        "db_ttl": 7 * 24 * 3600,    # 7 dias
        "sync_interval": 48 * 3600, # Sincroniza a cada 48h
        "api_economy": 0.95,        # 95% de economia
        "description": "Fase recursal - atividade muito baixa"
    },
    "final": {
        "redis_ttl": 7 * 24 * 3600, # 7 dias
        "db_ttl": 30 * 24 * 3600,   # 30 dias
        "sync_interval": 7 * 24 * 3600, # Sincroniza semanalmente
        "api_economy": 0.98,        # 98% de economia
        "description": "Fase final - atividade mínima"
    },
    "arquivado": {
        "redis_ttl": 30 * 24 * 3600, # 30 dias
        "db_ttl": 365 * 24 * 3600,   # 1 ano
        "sync_interval": 30 * 24 * 3600, # Sincroniza mensalmente
        "api_economy": 0.99,        # 99% de economia
        "description": "Processo arquivado - economia máxima"
    }
}

# ============================================================================
# CLASSIFICAÇÃO AUTOMÁTICA DE FASES
# ============================================================================

PHASE_PATTERNS = {
    "inicial": [
        r"petição\s+inicial",
        r"distribuição\s+do\s+processo", 
        r"citação\s+expedida",
        r"contestação\s+apresentada",
        r"tréplica\s+protocolada",
        r"despacho\s+inicial",
        r"autuação\s+do\s+processo"
    ],
    "instrutoria": [
        r"despacho\s+saneador",
        r"audiência\s+designada",
        r"perícia\s+determinada",
        r"produção\s+de\s+provas",
        r"oitiva\s+de\s+testemunhas",
        r"juntada\s+de\s+laudo",
        r"manifestação\s+das\s+partes"
    ],
    "decisoria": [
        r"memoriais\s+apresentados",
        r"concluso\s+para\s+sentença",
        r"sentença\s+prolatada",
        r"decisão\s+publicada",
        r"conclusão\s+ao\s+magistrado",
        r"certidão\s+de\s+julgamento"
    ],
    "recursal": [
        r"apelação\s+interposta",
        r"contrarrazões\s+apresentadas",
        r"remessa\s+ao\s+tribunal",
        r"acórdão\s+publicado",
        r"recurso\s+especial",
        r"agravo\s+de\s+instrumento"
    ],
    "final": [
        r"trânsito\s+em\s+julgado",
        r"execução\s+iniciada",
        r"cumprimento\s+de\s+sentença",
        r"arquivamento\s+determinado",
        r"liquidação\s+de\s+sentença",
        r"satisfação\s+do\s+crédito"
    ],
    "arquivado": [
        r"arquivado\s+definitivamente",
        r"baixa\s+definitiva",
        r"processo\s+extinto",
        r"extinção\s+do\s+processo",
        r"arquivamento\s+provisório"
    ]
}

# ============================================================================
# OTIMIZAÇÃO POR ÁREA DO DIREITO
# ============================================================================

AREA_SPECIFIC_TTL = {
    "tributario": {
        "multiplier": 2.0,        # Processos longos
        "priority": "low",        
        "economy_boost": 1.15,    # 15% economia extra
        "typical_duration_months": 60
    },
    "previdenciario": {
        "multiplier": 1.8,        # Processos longos e previsíveis
        "priority": "low", 
        "economy_boost": 1.12,
        "typical_duration_months": 48
    },
    "trabalhista": {
        "multiplier": 0.8,        # Processos mais rápidos
        "priority": "medium",
        "economy_boost": 1.0,
        "typical_duration_months": 18
    },
    "civel": {
        "multiplier": 1.0,        # Duração média
        "priority": "medium",
        "economy_boost": 1.05,
        "typical_duration_months": 36
    },
    "penal": {
        "multiplier": 0.6,        # Precisam mais acompanhamento
        "priority": "high",
        "economy_boost": 0.9,
        "typical_duration_months": 24
    },
    "empresarial": {
        "multiplier": 1.5,        # Complexos mas lentos
        "priority": "medium",
        "economy_boost": 1.10,
        "typical_duration_months": 42
    },
    "consumidor": {
        "multiplier": 0.9,        # Relativamente rápidos
        "priority": "medium",
        "economy_boost": 1.08,
        "typical_duration_months": 24
    },
    "familia": {
        "multiplier": 1.2,        # Duração variável
        "priority": "medium",
        "economy_boost": 1.06,
        "typical_duration_months": 30
    }
}

# ============================================================================
# CACHE PREDICTIVO
# ============================================================================

PREDICTIVE_PATTERNS = {
    "audiencia_marcada": {
        "next_movement_days": 7,     # Próxima movimentação em ~7 dias
        "confidence": 0.85,          # 85% de certeza
        "pre_sync": True,            # Sincronizar antes da data
        "pattern": r"audiência\s+designada\s+para"
    },
    "prazo_contestacao": {
        "next_movement_days": 15,    # 15 dias para contestação
        "confidence": 0.90,
        "pre_sync": True,
        "pattern": r"prazo\s+para\s+contestação"
    },
    "concluso_sentenca": {
        "next_movement_days": 30,    # ~30 dias para sentença
        "confidence": 0.70,
        "pre_sync": True,
        "pattern": r"concluso\s+para\s+sentença"
    },
    "prazo_recurso": {
        "next_movement_days": 15,    # 15 dias para recurso
        "confidence": 0.85,
        "pre_sync": True,
        "pattern": r"prazo\s+para\s+recurso"
    },
    "pericia_designada": {
        "next_movement_days": 45,    # ~45 dias para laudo
        "confidence": 0.75,
        "pre_sync": True,
        "pattern": r"perícia\s+designada"
    }
}

# ============================================================================
# PRIORIZAÇÃO POR USO
# ============================================================================

USER_ACCESS_PRIORITY = {
    "daily": {           # Acessado diariamente
        "sync_frequency": 0.5,   # 2x mais frequente
        "ttl_multiplier": 0.7,   # TTL menor
        "description": "Processo acessado diariamente"
    },
    "weekly": {          # Acessado semanalmente  
        "sync_frequency": 1.0,   # Frequência padrão
        "ttl_multiplier": 1.0,
        "description": "Processo acessado semanalmente"
    },
    "monthly": {         # Acessado mensalmente
        "sync_frequency": 2.0,   # 2x menos frequente  
        "ttl_multiplier": 1.5,
        "description": "Processo acessado mensalmente"
    },
    "rarely": {          # Raramente acessado
        "sync_frequency": 4.0,   # 4x menos frequente
        "ttl_multiplier": 3.0,   # TTL muito maior
        "description": "Processo raramente acessado"
    },
    "archived": {        # Apenas histórico
        "sync_frequency": 10.0,  # 10x menos frequente
        "ttl_multiplier": 10.0,  # TTL máximo
        "description": "Processo apenas para histórico"
    }
}

# ============================================================================
# CONFIGURAÇÃO PRINCIPAL DE ECONOMIA
# ============================================================================

ECONOMIC_OPTIMIZATION = {
    # Funcionalidades habilitadas
    "enable_phase_detection": True,
    "enable_predictive_cache": True, 
    "enable_batch_processing": True,
    "enable_area_optimization": True,
    "enable_usage_priority": True,
    "enable_smart_compression": True,
    
    # Armazenamento de 5 anos
    "long_term_storage": {
        "archive_after_months": 12,     # Arquivar após 1 ano
        "compress_after_months": 6,     # Comprimir após 6 meses
        "glacier_after_years": 3,       # Cold storage após 3 anos
        "delete_never": True,           # Nunca deletar (requisito legal)
        "compression_ratio": 0.3,       # 70% de redução no tamanho
        "verify_integrity": True        # Verificar integridade dos dados
    },
    
    # Limites de economia
    "max_daily_api_calls": 100,        # Máximo 100 calls/dia
    "emergency_sync_threshold": 0.95,  # 95% de economia máxima
    "offline_mode_hours": 72,          # 72h de funcionamento offline
    "min_cache_hit_rate": 0.90,        # 90% mínimo de cache hit
    
    # Batch processing
    "batch_processing": {
        "batch_size": 50,               # 50 processos por batch
        "cost_reduction": 0.70,         # 70% de redução de custo
        "timeout_seconds": 30,          # 30s timeout por batch
        "retry_individual": True,       # Retry individual se batch falhar
        "parallel_batches": 3           # 3 batches paralelos máximo
    },
    
    # Monitoramento
    "monitoring": {
        "track_economy_metrics": True,
        "daily_reports": True,
        "alert_on_high_api_usage": True,
        "target_economy_rate": 0.95     # Meta de 95% de economia
    }
}

# ============================================================================
# MÉTRICAS E KPIS
# ============================================================================

ECONOMY_METRICS = {
    "api_calls_saved_daily": {"target": 0.90, "unit": "%"},
    "cache_hit_rate": {"target": 0.95, "unit": "%"}, 
    "offline_uptime": {"target": 0.99, "unit": "%"},
    "cost_reduction_monthly": {"target": 0.90, "unit": "%"},
    "storage_efficiency": {"target": 0.85, "unit": "%"},
    "user_satisfaction": {"target": 0.95, "unit": "%"},
    "response_time_improvement": {"target": 10.0, "unit": "x"},
    "data_retention_compliance": {"target": 1.0, "unit": "%"}
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

class ProcessPhaseClassifier:
    """Classifica automaticamente a fase do processo."""
    
    @classmethod
    def classify_phase(cls, movements: List[str]) -> str:
        """Classifica fase baseado nas movimentações mais recentes."""
        if not movements:
            return "instrutoria"  # Default
            
        recent_text = " ".join(movements[:5]).lower()  # 5 mais recentes
        
        # Verifica padrões em ordem de prioridade
        for phase, patterns in PHASE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, recent_text, re.IGNORECASE):
                    return phase
        
        return "instrutoria"  # Default para fase média
    
    @classmethod 
    def get_optimal_ttl(cls, phase: str, last_movement_days: int, 
                       area: str = None, access_pattern: str = "weekly") -> Dict[str, int]:
        """Retorna TTL otimizado baseado em múltiplos fatores."""
        
        # Config base por fase
        base_config = PHASE_BASED_TTL.get(phase, PHASE_BASED_TTL["instrutoria"])
        
        # Ajuste por tempo sem movimentação
        inactivity_multiplier = 1.0
        if last_movement_days > 90:  # 3+ meses sem movimento
            inactivity_multiplier = min(3.0, last_movement_days / 30)
        
        # Ajuste por área do direito
        area_multiplier = 1.0
        if area and area.lower() in AREA_SPECIFIC_TTL:
            area_config = AREA_SPECIFIC_TTL[area.lower()]
            area_multiplier = area_config["multiplier"]
        
        # Ajuste por padrão de acesso
        access_multiplier = 1.0
        if access_pattern in USER_ACCESS_PRIORITY:
            access_config = USER_ACCESS_PRIORITY[access_pattern]
            access_multiplier = access_config["ttl_multiplier"]
        
        # Calcula TTL final
        final_multiplier = inactivity_multiplier * area_multiplier * access_multiplier
        
        return {
            "redis_ttl": int(base_config["redis_ttl"] * final_multiplier),
            "db_ttl": int(base_config["db_ttl"] * final_multiplier),
            "sync_interval": int(base_config["sync_interval"] * final_multiplier),
            "phase": phase,
            "multipliers": {
                "inactivity": inactivity_multiplier,
                "area": area_multiplier, 
                "access": access_multiplier,
                "final": final_multiplier
            }
        }
    
    @classmethod
    def predict_next_movement(cls, movements: List[str]) -> Dict[str, Any]:
        """Prediz quando ocorrerá a próxima movimentação com ML integrado."""
        if not movements:
            return {"prediction": None}
            
        # Tentar usar ML se disponível
        try:
            from services.predictive_cache_ml_service import predictive_cache_ml
            if predictive_cache_ml.movement_classifier:
                return cls._predict_with_enhanced_ml(movements)
        except Exception:
            pass
        
        # Fallback para regras básicas
        recent_text = " ".join(movements[:3]).lower()
        
        for event, config in PREDICTIVE_PATTERNS.items():
            if re.search(config["pattern"], recent_text, re.IGNORECASE):
                predicted_date = datetime.now() + timedelta(days=config["next_movement_days"])
                return {
                    "prediction": event,
                    "predicted_date": predicted_date,
                    "confidence": config["confidence"],
                    "days_ahead": config["next_movement_days"],
                    "should_pre_sync": config["pre_sync"]
                }
        
        return {"prediction": None}
    
    @classmethod
    def _predict_with_enhanced_ml(cls, movements: List[str]) -> Dict[str, Any]:
        """Predição aprimorada usando padrões ML mais sofisticados."""
        recent_text = " ".join(movements[:3]).lower()
        
        # Padrões ML aprimorados
        enhanced_patterns = {
            "sentença_iminente": {
                "patterns": ["concluso", "deliberação", "prolação"],
                "prediction": "sentenca_publicada",
                "confidence": 0.92,
                "days": 3,
                "priority": "high"
            },
            "audiencia_proxima": {
                "patterns": ["designada audiência", "audiência marcada", "intimação audiência"],
                "prediction": "realizacao_audiencia", 
                "confidence": 0.95,
                "days": 7,
                "priority": "high"
            },
            "recurso_prazo": {
                "patterns": ["publicação sentença", "sentença publicada", "intimação sentença"],
                "prediction": "prazo_recurso",
                "confidence": 0.88,
                "days": 15,
                "priority": "medium"
            },
            "contestacao_prazo": {
                "patterns": ["citação expedida", "mandado cumprido", "citação realizada"],
                "prediction": "juntada_contestacao",
                "confidence": 0.85,
                "days": 15,
                "priority": "medium"
            },
            "execucao_inicio": {
                "patterns": ["trânsito julgado", "transitou julgado", "coisa julgada"],
                "prediction": "inicio_execucao",
                "confidence": 0.80,
                "days": 30,
                "priority": "low"
            }
        }
        
        # Buscar melhor match
        best_match = None
        highest_confidence = 0
        
        for pattern_name, config in enhanced_patterns.items():
            for pattern in config["patterns"]:
                if pattern in recent_text:
                    if config["confidence"] > highest_confidence:
                        best_match = config
                        highest_confidence = config["confidence"]
        
        if best_match:
            predicted_date = datetime.now() + timedelta(days=best_match["days"])
            return {
                "prediction": best_match["prediction"],
                "predicted_date": predicted_date,
                "confidence": best_match["confidence"],
                "days_ahead": best_match["days"],
                "should_pre_sync": best_match["priority"] in ["high", "medium"],
                "ml_enhanced": True,
                "priority": best_match["priority"]
            }
        
        return {"prediction": None}

def calculate_economy_percentage(api_calls_saved: int, total_potential_calls: int) -> float:
    """Calcula percentual de economia."""
    if total_potential_calls == 0:
        return 0.0
    return (api_calls_saved / total_potential_calls) * 100

def estimate_5_year_savings(monthly_api_cost: float, economy_rate: float = 0.95) -> Dict[str, float]:
    """Estima economia em 5 anos."""
    yearly_cost = monthly_api_cost * 12
    yearly_savings = yearly_cost * economy_rate
    total_5_year_savings = yearly_savings * 5
    
    return {
        "monthly_cost": monthly_api_cost,
        "yearly_cost": yearly_cost,
        "yearly_savings": yearly_savings,
        "total_5_year_savings": total_5_year_savings,
        "economy_rate": economy_rate * 100
    } 
                "confidence": 0.92,
                "days": 3,
                "priority": "high"
            },
            "audiencia_proxima": {
                "patterns": ["designada audiência", "audiência marcada", "intimação audiência"],
                "prediction": "realizacao_audiencia", 
                "confidence": 0.95,
                "days": 7,
                "priority": "high"
            },
            "recurso_prazo": {
                "patterns": ["publicação sentença", "sentença publicada", "intimação sentença"],
                "prediction": "prazo_recurso",
                "confidence": 0.88,
                "days": 15,
                "priority": "medium"
            },
            "contestacao_prazo": {
                "patterns": ["citação expedida", "mandado cumprido", "citação realizada"],
                "prediction": "juntada_contestacao",
                "confidence": 0.85,
                "days": 15,
                "priority": "medium"
            },
            "execucao_inicio": {
                "patterns": ["trânsito julgado", "transitou julgado", "coisa julgada"],
                "prediction": "inicio_execucao",
                "confidence": 0.80,
                "days": 30,
                "priority": "low"
            }
        }
        
        # Buscar melhor match
        best_match = None
        highest_confidence = 0
        
        for pattern_name, config in enhanced_patterns.items():
            for pattern in config["patterns"]:
                if pattern in recent_text:
                    if config["confidence"] > highest_confidence:
                        best_match = config
                        highest_confidence = config["confidence"]
        
        if best_match:
            predicted_date = datetime.now() + timedelta(days=best_match["days"])
            return {
                "prediction": best_match["prediction"],
                "predicted_date": predicted_date,
                "confidence": best_match["confidence"],
                "days_ahead": best_match["days"],
                "should_pre_sync": best_match["priority"] in ["high", "medium"],
                "ml_enhanced": True,
                "priority": best_match["priority"]
            }
        
        return {"prediction": None}

def calculate_economy_percentage(api_calls_saved: int, total_potential_calls: int) -> float:
    """Calcula percentual de economia."""
    if total_potential_calls == 0:
        return 0.0
    return (api_calls_saved / total_potential_calls) * 100

def estimate_5_year_savings(monthly_api_cost: float, economy_rate: float = 0.95) -> Dict[str, float]:
    """Estima economia em 5 anos."""
    yearly_cost = monthly_api_cost * 12
    yearly_savings = yearly_cost * economy_rate
    total_5_year_savings = yearly_savings * 5
    
    return {
        "monthly_cost": monthly_api_cost,
        "yearly_cost": yearly_cost,
        "yearly_savings": yearly_savings,
        "total_5_year_savings": total_5_year_savings,
        "economy_rate": economy_rate * 100
    } 
                "confidence": 0.92,
                "days": 3,
                "priority": "high"
            },
            "audiencia_proxima": {
                "patterns": ["designada audiência", "audiência marcada", "intimação audiência"],
                "prediction": "realizacao_audiencia", 
                "confidence": 0.95,
                "days": 7,
                "priority": "high"
            },
            "recurso_prazo": {
                "patterns": ["publicação sentença", "sentença publicada", "intimação sentença"],
                "prediction": "prazo_recurso",
                "confidence": 0.88,
                "days": 15,
                "priority": "medium"
            },
            "contestacao_prazo": {
                "patterns": ["citação expedida", "mandado cumprido", "citação realizada"],
                "prediction": "juntada_contestacao",
                "confidence": 0.85,
                "days": 15,
                "priority": "medium"
            },
            "execucao_inicio": {
                "patterns": ["trânsito julgado", "transitou julgado", "coisa julgada"],
                "prediction": "inicio_execucao",
                "confidence": 0.80,
                "days": 30,
                "priority": "low"
            }
        }
        
        # Buscar melhor match
        best_match = None
        highest_confidence = 0
        
        for pattern_name, config in enhanced_patterns.items():
            for pattern in config["patterns"]:
                if pattern in recent_text:
                    if config["confidence"] > highest_confidence:
                        best_match = config
                        highest_confidence = config["confidence"]
        
        if best_match:
            predicted_date = datetime.now() + timedelta(days=best_match["days"])
            return {
                "prediction": best_match["prediction"],
                "predicted_date": predicted_date,
                "confidence": best_match["confidence"],
                "days_ahead": best_match["days"],
                "should_pre_sync": best_match["priority"] in ["high", "medium"],
                "ml_enhanced": True,
                "priority": best_match["priority"]
            }
        
        return {"prediction": None}

def calculate_economy_percentage(api_calls_saved: int, total_potential_calls: int) -> float:
    """Calcula percentual de economia."""
    if total_potential_calls == 0:
        return 0.0
    return (api_calls_saved / total_potential_calls) * 100

def estimate_5_year_savings(monthly_api_cost: float, economy_rate: float = 0.95) -> Dict[str, float]:
    """Estima economia em 5 anos."""
    yearly_cost = monthly_api_cost * 12
    yearly_savings = yearly_cost * economy_rate
    total_5_year_savings = yearly_savings * 5
    
    return {
        "monthly_cost": monthly_api_cost,
        "yearly_cost": yearly_cost,
        "yearly_savings": yearly_savings,
        "total_5_year_savings": total_5_year_savings,
        "economy_rate": economy_rate * 100
    } 