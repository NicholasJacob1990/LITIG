# -*- coding: utf-8 -*-
"""
config/settings.py

Configurações centralizadas para o sistema de matching jurídico.
Usa apenas stdlib para evitar dependências externas.
"""

import os
from typing import Dict, Optional


class MatchingSettings:
    """Configurações principais do algoritmo de matching."""
    
    def __init__(self):
        # Dimensões e constantes básicas
        self.embedding_dim = 384
        
        # Timeouts e decay
        self.conflict_timeout_sec = float(os.getenv("CONFLICT_TIMEOUT", "2.0"))
        self.price_decay_k = float(os.getenv("PRICE_DECAY_K", "5.0"))
        self.success_fee_mult = float(os.getenv("SUCCESS_FEE_MULT", "10.0"))
        
        # Redis
        self.redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        
        # LTR Service
        self.ltr_endpoint = os.getenv("LTR_ENDPOINT", "http://ltr-service:8080/ltr/score")
        self.ltr_weights_path = os.getenv("LTR_WEIGHTS_PATH")
        
        # Academic Enrichment APIs
        self.perplexity_api_key = os.getenv("PERPLEXITY_API_KEY")
        self.openai_deep_key = os.getenv("OPENAI_DEEP_KEY")
        self.uni_rank_ttl_h = int(os.getenv("UNI_RANK_TTL_H", "720"))  # 30 dias
        self.jour_rank_ttl_h = int(os.getenv("JOUR_RANK_TTL_H", "720"))  # 30 dias
        
        # Deep Research timeouts
        self.deep_poll_secs = int(os.getenv("DEEP_POLL_SECS", "10"))
        self.deep_max_min = int(os.getenv("DEEP_MAX_MIN", "15"))
        
        # Rate limiting
        self.perplexity_rate_limit = 30
        self.escavador_rate_limit = 20


class PresetWeights:
    """Pesos dos presets de matching."""
    
    def __init__(self):
        # Pesos padrão hardcoded como fallback
        self.hardcoded_fallback = {
            "A": 0.22, "S": 0.17, "T": 0.10, "G": 0.07,
            "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
            "E": 0.02, "P": 0.02, "M": 0.14, "I": 0.02,
            "L": 0.04  # Feature L (Languages & Events)
        }
        
        # Presets principais
        self.balanced = {
            "A": 0.22, "S": 0.17, "T": 0.10, "G": 0.07,
            "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
            "E": 0.02, "P": 0.02, "M": 0.14, "I": 0.02, "L": 0.04
        }
        
        self.economic = {
            "A": 0.15, "S": 0.20, "T": 0.08, "G": 0.05,
            "Q": 0.05, "U": 0.10, "R": 0.08, "C": 0.05,
            "E": 0.03, "P": 0.15, "M": 0.04, "I": 0.01, "L": 0.01
        }
        
        self.premium = {
            "A": 0.28, "S": 0.18, "T": 0.12, "G": 0.08,
            "Q": 0.10, "U": 0.04, "R": 0.03, "C": 0.02,
            "E": 0.04, "P": 0.01, "M": 0.08, "I": 0.01, "L": 0.01
        }
        
        self.geographic = {
            "A": 0.15, "S": 0.10, "T": 0.05, "G": 0.25,
            "Q": 0.05, "U": 0.08, "R": 0.05, "C": 0.02,
            "E": 0.02, "P": 0.03, "M": 0.18, "I": 0.01, "L": 0.01
        }
        
        self.corporate = {
            "A": 0.18, "S": 0.15, "T": 0.08, "G": 0.05,
            "Q": 0.08, "U": 0.06, "R": 0.06, "C": 0.04,
            "E": 0.12, "P": 0.05, "M": 0.10, "I": 0.02, "L": 0.01
        }
        
        # Validar todos os presets
        self._validate_all_presets()
    
    def _validate_all_presets(self):
        """Valida se todos os presets somam aproximadamente 1.0."""
        presets = {
            "balanced": self.balanced,
            "economic": self.economic,
            "premium": self.premium,
            "geographic": self.geographic,
            "corporate": self.corporate,
            "hardcoded_fallback": self.hardcoded_fallback,
        }
        
        for name, weights in presets.items():
            total = sum(weights.values())
            if abs(total - 1.0) > 1e-6:
                raise ValueError(f"Preset '{name}' não soma 1.0 (soma={total:.6f})")


class TextPatterns:
    """Padrões de texto para análise de reviews."""
    
    def __init__(self):
        self.positive_patterns = [
            r'\batencioso\b', r'\bdedicado\b', r'\bprofissional\b', r'\bcompetente\b',
            r'\beficiente\b', r'\bcordial\b', r'\bprestativo\b', r'\bresponsavel\b',
            r'\bpontual\b', r'\borganizado\b', r'\bcomunicativo\b', r'\bclaro\b',
            r'\btransparente\b', r'\bconfiavel\b', r'\bexcelente\b', r'\botimo\b',
            r'\bbom\b', r'\bsatisfeito\b', r'\brecomendo\b', r'\bgentil\b',
            r'\beducado\b', r'\bpaciente\b', r'\bcompreensivo\b', r'\bdisponivel\b',
            r'\bagil\b', r'\brapido\b', r'\bpositivo\b'
        ]
        
        self.negative_patterns = [
            r'\bdemor\w+\b', r'\blent\w+\b', r'\batras\w+\b', r'\bruim\b',
            r'\bpessim\w+\b', r'\bterr[ií]vel\b', r'\bdesorganizad\w+\b',
            r'\bignor\w+\b', r'\bmalcriad\w+\b', r'\bdesrespeitoso\b',
            r'\birresponsavel\b', r'\bincompetente\b', r'\bineficiente\b',
            r'\bconfus\w+\b', r'\bnao\s+recomendo\b', r'\bfraco\b',
            r'\binsatisfeit\w+\b', r'\bperdeu\b', r'\bdesapont\w+\b'
        ]


# Instâncias globais das configurações
settings = MatchingSettings()
preset_weights = PresetWeights()
text_patterns = TextPatterns()

# Para manter backward compatibility
EMBEDDING_DIM = settings.embedding_dim
CONFLICT_TIMEOUT_SEC = settings.conflict_timeout_sec
PRICE_DECAY_K = settings.price_decay_k
SUCCESS_FEE_MULT = settings.success_fee_mult
REDIS_URL = settings.redis_url
LTR_ENDPOINT = settings.ltr_endpoint

# Academic Enrichment
PERPLEXITY_API_KEY = settings.perplexity_api_key
OPENAI_DEEP_KEY = settings.openai_deep_key
UNI_RANK_TTL_H = settings.uni_rank_ttl_h
JOUR_RANK_TTL_H = settings.jour_rank_ttl_h
DEEP_POLL_SECS = settings.deep_poll_secs
DEEP_MAX_MIN = settings.deep_max_min

# Presets
PRESET_WEIGHTS = {
    "balanced": preset_weights.balanced,
    "economic": preset_weights.economic,
    "premium": preset_weights.premium,
    "geographic": preset_weights.geographic,
    "corporate": preset_weights.corporate,
}

HARDCODED_FALLBACK_WEIGHTS = preset_weights.hardcoded_fallback

# Text patterns  
_POSITIVE_PATTERNS = text_patterns.positive_patterns
_NEGATIVE_PATTERNS = text_patterns.negative_patterns
 
 