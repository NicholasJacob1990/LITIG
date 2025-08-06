# -*- coding: utf-8 -*-
"""
v3/config.py - Configurações Centralizadas

Centraliza TODAS as configurações do algoritmo v2.11, substituindo
os múltiplos os.getenv() espalhados pelo código.

Benefícios:
- Validação centralizada de tipos
- Documentação de todas as variáveis
- Defaults seguros
- Facilita testes com mocks
"""

import os
from typing import Optional, Dict, Any
from dataclasses import dataclass


@dataclass 
class RedisConfig:
    """Configurações do Redis/Cache."""
    url: str
    timeout_seconds: int
    default_ttl_hours: int
    
    def __init__(self):
        self.url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.timeout_seconds = int(os.getenv("REDIS_TIMEOUT", "5"))
        self.default_ttl_hours = int(os.getenv("CACHE_TTL_HOURS", "24"))


@dataclass
class AcademicConfig:
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str]
    openai_deep_key: Optional[str]
    uni_rank_ttl_hours: int
    journal_rank_ttl_hours: int
    rate_limit_delay: float
    circuit_breaker_threshold: int
    
    def __init__(self):
        self.perplexity_api_key = os.getenv("PERPLEXITY_API_KEY")
        self.openai_deep_key = os.getenv("OPENAI_DEEP_KEY")
        self.uni_rank_ttl_hours = int(os.getenv("UNI_RANK_TTL_H", "168"))  # 7 dias
        self.journal_rank_ttl_hours = int(os.getenv("JOUR_RANK_TTL_H", "72"))  # 3 dias
        self.rate_limit_delay = float(os.getenv("ACADEMIC_RATE_DELAY", "0.5"))
        self.circuit_breaker_threshold = int(os.getenv("ACADEMIC_CB_THRESHOLD", "5"))


@dataclass
class LTRConfig:
    """Configurações do Learning-to-Rank."""
    endpoint_url: Optional[str]
    timeout_seconds: int
    max_parallel_requests: int
    
    def __init__(self):
        self.endpoint_url = os.getenv("LTR_ENDPOINT")
        self.timeout_seconds = int(os.getenv("LTR_TIMEOUT", "10"))
        self.max_parallel_requests = int(os.getenv("LTR_MAX_PARALLEL", "20"))


@dataclass 
class AlgorithmConfig:
    """Configurações principais do algoritmo."""
    embedding_dimension: int
    default_preset: str
    conflict_timeout: float
    premium_exclusive_minutes: int
    price_decay_k: float
    geo_decay_beta: float
    
    def __init__(self):
        self.embedding_dimension = int(os.getenv("EMBEDDING_DIM", "384"))
        self.default_preset = os.getenv("DEFAULT_PRESET", "balanced")
        self.conflict_timeout = float(os.getenv("CONFLICT_TIMEOUT", "2.0"))
        self.premium_exclusive_minutes = int(os.getenv("PREMIUM_EXCLUSIVE_MIN", "60"))
        self.price_decay_k = 5.0  # Constante do algoritmo
        self.geo_decay_beta = 0.1  # Constante do algoritmo


@dataclass
class FeatureWeights:
    """Pesos das features do algoritmo v2.11."""
    A: float = 0.22  # Area Match
    S: float = 0.17  # Case Similarity  
    T: float = 0.10  # Success Rate
    G: float = 0.07  # Geo Score
    Q: float = 0.07  # Qualification
    U: float = 0.05  # Urgency Capacity
    R: float = 0.05  # Review Score
    C: float = 0.03  # Soft Skills
    E: float = 0.02  # Firm Reputation
    P: float = 0.02  # Price Fit
    M: float = 0.14  # Maturity Score
    I: float = 0.02  # Interaction Score (IEP)
    L: float = 0.04  # Languages & Events (v2.11)
    
    def validate(self) -> bool:
        """Valida se a soma dos pesos é aproximadamente 1."""
        total = sum([
            self.A, self.S, self.T, self.G, self.Q, self.U, self.R,
            self.C, self.E, self.P, self.M, self.I, self.L
        ])
        return abs(total - 1.0) < 0.01


@dataclass
class Config:
    """Configuração master do algoritmo v3.0."""
    
    redis: RedisConfig
    academic: AcademicConfig  
    ltr: LTRConfig
    algorithm: AlgorithmConfig
    default_weights: FeatureWeights
    debug_mode: bool
    
    def __init__(self):
        self.redis = RedisConfig()
        self.academic = AcademicConfig()
        self.ltr = LTRConfig()
        self.algorithm = AlgorithmConfig()
        self.default_weights = FeatureWeights()
        self.debug_mode = os.getenv("DEBUG_MODE", "false").lower() == "true"
    
    def validate(self) -> list[str]:
        """Valida configuração e retorna lista de avisos."""
        warnings = []
        
        if not self.academic.perplexity_api_key:
            warnings.append("⚠️ PERPLEXITY_API_KEY não configurado - enriquecimento acadêmico desabilitado")
        
        if not self.ltr.endpoint_url:
            warnings.append("⚠️ LTR_ENDPOINT não configurado - Learning-to-Rank desabilitado")
        
        if not self.default_weights.validate():
            warnings.append("⚠️ Soma dos pesos das features não é 1.0")
        
        return warnings


# Singleton da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obtém instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance

def reload_config() -> Config:
    """Recarrega configuração (útil para testes)."""
    global _config_instance
    _config_instance = Config()
    return _config_instance


# Constantes exportadas para compatibilidade com v2.11
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.algorithm.embedding_dimension
PRICE_DECAY_K = config.algorithm.price_decay_k
GEO_DECAY_BETA = config.algorithm.geo_decay_beta

# Feature mapping para debugging
FEATURE_NAMES = {
    "A": "area_match",
    "S": "case_similarity", 
    "T": "success_rate",
    "G": "geo_score",
    "Q": "qualification_score",
    "U": "urgency_capacity", 
    "R": "review_score",
    "C": "soft_skill",
    "E": "firm_reputation",
    "P": "price_fit",
    "M": "maturity_score",
    "I": "interaction_score",
    "L": "languages_events_score"
}

FEATURE_DESCRIPTIONS = {
    "A": "Compatibilidade de área jurídica",
    "S": "Similaridade de casos anteriores", 
    "T": "Taxa de sucesso histórica",
    "G": "Proximidade geográfica",
    "Q": "Qualificação acadêmica enriquecida",
    "U": "Capacidade vs urgência do caso",
    "R": "Avaliações de clientes",
    "C": "Habilidades interpessoais",
    "E": "Reputação do escritório", 
    "P": "Adequação de preço",
    "M": "Maturidade profissional",
    "I": "Índice de engajamento na plataforma",
    "L": "Idiomas e participação em eventos"
} 
"""
v3/config.py - Configurações Centralizadas

Centraliza TODAS as configurações do algoritmo v2.11, substituindo
os múltiplos os.getenv() espalhados pelo código.

Benefícios:
- Validação centralizada de tipos
- Documentação de todas as variáveis
- Defaults seguros
- Facilita testes com mocks
"""

import os
from typing import Optional, Dict, Any
from dataclasses import dataclass


@dataclass 
class RedisConfig:
    """Configurações do Redis/Cache."""
    url: str
    timeout_seconds: int
    default_ttl_hours: int
    
    def __init__(self):
        self.url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.timeout_seconds = int(os.getenv("REDIS_TIMEOUT", "5"))
        self.default_ttl_hours = int(os.getenv("CACHE_TTL_HOURS", "24"))


@dataclass
class AcademicConfig:
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str]
    openai_deep_key: Optional[str]
    uni_rank_ttl_hours: int
    journal_rank_ttl_hours: int
    rate_limit_delay: float
    circuit_breaker_threshold: int
    
    def __init__(self):
        self.perplexity_api_key = os.getenv("PERPLEXITY_API_KEY")
        self.openai_deep_key = os.getenv("OPENAI_DEEP_KEY")
        self.uni_rank_ttl_hours = int(os.getenv("UNI_RANK_TTL_H", "168"))  # 7 dias
        self.journal_rank_ttl_hours = int(os.getenv("JOUR_RANK_TTL_H", "72"))  # 3 dias
        self.rate_limit_delay = float(os.getenv("ACADEMIC_RATE_DELAY", "0.5"))
        self.circuit_breaker_threshold = int(os.getenv("ACADEMIC_CB_THRESHOLD", "5"))


@dataclass
class LTRConfig:
    """Configurações do Learning-to-Rank."""
    endpoint_url: Optional[str]
    timeout_seconds: int
    max_parallel_requests: int
    
    def __init__(self):
        self.endpoint_url = os.getenv("LTR_ENDPOINT")
        self.timeout_seconds = int(os.getenv("LTR_TIMEOUT", "10"))
        self.max_parallel_requests = int(os.getenv("LTR_MAX_PARALLEL", "20"))


@dataclass 
class AlgorithmConfig:
    """Configurações principais do algoritmo."""
    embedding_dimension: int
    default_preset: str
    conflict_timeout: float
    premium_exclusive_minutes: int
    price_decay_k: float
    geo_decay_beta: float
    
    def __init__(self):
        self.embedding_dimension = int(os.getenv("EMBEDDING_DIM", "384"))
        self.default_preset = os.getenv("DEFAULT_PRESET", "balanced")
        self.conflict_timeout = float(os.getenv("CONFLICT_TIMEOUT", "2.0"))
        self.premium_exclusive_minutes = int(os.getenv("PREMIUM_EXCLUSIVE_MIN", "60"))
        self.price_decay_k = 5.0  # Constante do algoritmo
        self.geo_decay_beta = 0.1  # Constante do algoritmo


@dataclass
class FeatureWeights:
    """Pesos das features do algoritmo v2.11."""
    A: float = 0.22  # Area Match
    S: float = 0.17  # Case Similarity  
    T: float = 0.10  # Success Rate
    G: float = 0.07  # Geo Score
    Q: float = 0.07  # Qualification
    U: float = 0.05  # Urgency Capacity
    R: float = 0.05  # Review Score
    C: float = 0.03  # Soft Skills
    E: float = 0.02  # Firm Reputation
    P: float = 0.02  # Price Fit
    M: float = 0.14  # Maturity Score
    I: float = 0.02  # Interaction Score (IEP)
    L: float = 0.04  # Languages & Events (v2.11)
    
    def validate(self) -> bool:
        """Valida se a soma dos pesos é aproximadamente 1."""
        total = sum([
            self.A, self.S, self.T, self.G, self.Q, self.U, self.R,
            self.C, self.E, self.P, self.M, self.I, self.L
        ])
        return abs(total - 1.0) < 0.01


@dataclass
class Config:
    """Configuração master do algoritmo v3.0."""
    
    redis: RedisConfig
    academic: AcademicConfig  
    ltr: LTRConfig
    algorithm: AlgorithmConfig
    default_weights: FeatureWeights
    debug_mode: bool
    
    def __init__(self):
        self.redis = RedisConfig()
        self.academic = AcademicConfig()
        self.ltr = LTRConfig()
        self.algorithm = AlgorithmConfig()
        self.default_weights = FeatureWeights()
        self.debug_mode = os.getenv("DEBUG_MODE", "false").lower() == "true"
    
    def validate(self) -> list[str]:
        """Valida configuração e retorna lista de avisos."""
        warnings = []
        
        if not self.academic.perplexity_api_key:
            warnings.append("⚠️ PERPLEXITY_API_KEY não configurado - enriquecimento acadêmico desabilitado")
        
        if not self.ltr.endpoint_url:
            warnings.append("⚠️ LTR_ENDPOINT não configurado - Learning-to-Rank desabilitado")
        
        if not self.default_weights.validate():
            warnings.append("⚠️ Soma dos pesos das features não é 1.0")
        
        return warnings


# Singleton da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obtém instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance

def reload_config() -> Config:
    """Recarrega configuração (útil para testes)."""
    global _config_instance
    _config_instance = Config()
    return _config_instance


# Constantes exportadas para compatibilidade com v2.11
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.algorithm.embedding_dimension
PRICE_DECAY_K = config.algorithm.price_decay_k
GEO_DECAY_BETA = config.algorithm.geo_decay_beta

# Feature mapping para debugging
FEATURE_NAMES = {
    "A": "area_match",
    "S": "case_similarity", 
    "T": "success_rate",
    "G": "geo_score",
    "Q": "qualification_score",
    "U": "urgency_capacity", 
    "R": "review_score",
    "C": "soft_skill",
    "E": "firm_reputation",
    "P": "price_fit",
    "M": "maturity_score",
    "I": "interaction_score",
    "L": "languages_events_score"
}

FEATURE_DESCRIPTIONS = {
    "A": "Compatibilidade de área jurídica",
    "S": "Similaridade de casos anteriores", 
    "T": "Taxa de sucesso histórica",
    "G": "Proximidade geográfica",
    "Q": "Qualificação acadêmica enriquecida",
    "U": "Capacidade vs urgência do caso",
    "R": "Avaliações de clientes",
    "C": "Habilidades interpessoais",
    "E": "Reputação do escritório", 
    "P": "Adequação de preço",
    "M": "Maturidade profissional",
    "I": "Índice de engajamento na plataforma",
    "L": "Idiomas e participação em eventos"
} 
"""
v3/config.py - Configurações Centralizadas

Centraliza TODAS as configurações do algoritmo v2.11, substituindo
os múltiplos os.getenv() espalhados pelo código.

Benefícios:
- Validação centralizada de tipos
- Documentação de todas as variáveis
- Defaults seguros
- Facilita testes com mocks
"""

import os
from typing import Optional, Dict, Any
from dataclasses import dataclass


@dataclass 
class RedisConfig:
    """Configurações do Redis/Cache."""
    url: str
    timeout_seconds: int
    default_ttl_hours: int
    
    def __init__(self):
        self.url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.timeout_seconds = int(os.getenv("REDIS_TIMEOUT", "5"))
        self.default_ttl_hours = int(os.getenv("CACHE_TTL_HOURS", "24"))


@dataclass
class AcademicConfig:
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str]
    openai_deep_key: Optional[str]
    uni_rank_ttl_hours: int
    journal_rank_ttl_hours: int
    rate_limit_delay: float
    circuit_breaker_threshold: int
    
    def __init__(self):
        self.perplexity_api_key = os.getenv("PERPLEXITY_API_KEY")
        self.openai_deep_key = os.getenv("OPENAI_DEEP_KEY")
        self.uni_rank_ttl_hours = int(os.getenv("UNI_RANK_TTL_H", "168"))  # 7 dias
        self.journal_rank_ttl_hours = int(os.getenv("JOUR_RANK_TTL_H", "72"))  # 3 dias
        self.rate_limit_delay = float(os.getenv("ACADEMIC_RATE_DELAY", "0.5"))
        self.circuit_breaker_threshold = int(os.getenv("ACADEMIC_CB_THRESHOLD", "5"))


@dataclass
class LTRConfig:
    """Configurações do Learning-to-Rank."""
    endpoint_url: Optional[str]
    timeout_seconds: int
    max_parallel_requests: int
    
    def __init__(self):
        self.endpoint_url = os.getenv("LTR_ENDPOINT")
        self.timeout_seconds = int(os.getenv("LTR_TIMEOUT", "10"))
        self.max_parallel_requests = int(os.getenv("LTR_MAX_PARALLEL", "20"))


@dataclass 
class AlgorithmConfig:
    """Configurações principais do algoritmo."""
    embedding_dimension: int
    default_preset: str
    conflict_timeout: float
    premium_exclusive_minutes: int
    price_decay_k: float
    geo_decay_beta: float
    
    def __init__(self):
        self.embedding_dimension = int(os.getenv("EMBEDDING_DIM", "384"))
        self.default_preset = os.getenv("DEFAULT_PRESET", "balanced")
        self.conflict_timeout = float(os.getenv("CONFLICT_TIMEOUT", "2.0"))
        self.premium_exclusive_minutes = int(os.getenv("PREMIUM_EXCLUSIVE_MIN", "60"))
        self.price_decay_k = 5.0  # Constante do algoritmo
        self.geo_decay_beta = 0.1  # Constante do algoritmo


@dataclass
class FeatureWeights:
    """Pesos das features do algoritmo v2.11."""
    A: float = 0.22  # Area Match
    S: float = 0.17  # Case Similarity  
    T: float = 0.10  # Success Rate
    G: float = 0.07  # Geo Score
    Q: float = 0.07  # Qualification
    U: float = 0.05  # Urgency Capacity
    R: float = 0.05  # Review Score
    C: float = 0.03  # Soft Skills
    E: float = 0.02  # Firm Reputation
    P: float = 0.02  # Price Fit
    M: float = 0.14  # Maturity Score
    I: float = 0.02  # Interaction Score (IEP)
    L: float = 0.04  # Languages & Events (v2.11)
    
    def validate(self) -> bool:
        """Valida se a soma dos pesos é aproximadamente 1."""
        total = sum([
            self.A, self.S, self.T, self.G, self.Q, self.U, self.R,
            self.C, self.E, self.P, self.M, self.I, self.L
        ])
        return abs(total - 1.0) < 0.01


@dataclass
class Config:
    """Configuração master do algoritmo v3.0."""
    
    redis: RedisConfig
    academic: AcademicConfig  
    ltr: LTRConfig
    algorithm: AlgorithmConfig
    default_weights: FeatureWeights
    debug_mode: bool
    
    def __init__(self):
        self.redis = RedisConfig()
        self.academic = AcademicConfig()
        self.ltr = LTRConfig()
        self.algorithm = AlgorithmConfig()
        self.default_weights = FeatureWeights()
        self.debug_mode = os.getenv("DEBUG_MODE", "false").lower() == "true"
    
    def validate(self) -> list[str]:
        """Valida configuração e retorna lista de avisos."""
        warnings = []
        
        if not self.academic.perplexity_api_key:
            warnings.append("⚠️ PERPLEXITY_API_KEY não configurado - enriquecimento acadêmico desabilitado")
        
        if not self.ltr.endpoint_url:
            warnings.append("⚠️ LTR_ENDPOINT não configurado - Learning-to-Rank desabilitado")
        
        if not self.default_weights.validate():
            warnings.append("⚠️ Soma dos pesos das features não é 1.0")
        
        return warnings


# Singleton da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obtém instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance

def reload_config() -> Config:
    """Recarrega configuração (útil para testes)."""
    global _config_instance
    _config_instance = Config()
    return _config_instance


# Constantes exportadas para compatibilidade com v2.11
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.algorithm.embedding_dimension
PRICE_DECAY_K = config.algorithm.price_decay_k
GEO_DECAY_BETA = config.algorithm.geo_decay_beta

# Feature mapping para debugging
FEATURE_NAMES = {
    "A": "area_match",
    "S": "case_similarity", 
    "T": "success_rate",
    "G": "geo_score",
    "Q": "qualification_score",
    "U": "urgency_capacity", 
    "R": "review_score",
    "C": "soft_skill",
    "E": "firm_reputation",
    "P": "price_fit",
    "M": "maturity_score",
    "I": "interaction_score",
    "L": "languages_events_score"
}

FEATURE_DESCRIPTIONS = {
    "A": "Compatibilidade de área jurídica",
    "S": "Similaridade de casos anteriores", 
    "T": "Taxa de sucesso histórica",
    "G": "Proximidade geográfica",
    "Q": "Qualificação acadêmica enriquecida",
    "U": "Capacidade vs urgência do caso",
    "R": "Avaliações de clientes",
    "C": "Habilidades interpessoais",
    "E": "Reputação do escritório", 
    "P": "Adequação de preço",
    "M": "Maturidade profissional",
    "I": "Índice de engajamento na plataforma",
    "L": "Idiomas e participação em eventos"
} 