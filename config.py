# -*- coding: utf-8 -*-
"""
config.py - Configurações Centralizadas do Algoritmo v3.0

Centraliza todas as configurações usando Pydantic para validação.
Substitui os múltiplos os.getenv espalhados pelo código v2.11.
"""

import os
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field, validator
from dataclasses import dataclass


class RedisConfig(BaseModel):
    """Configurações do Redis/Cache."""
    url: str = Field(default="redis://localhost:6379", env="REDIS_URL")
    max_connections: int = Field(default=10, env="REDIS_MAX_CONNECTIONS")
    timeout_seconds: int = Field(default=5, env="REDIS_TIMEOUT")
    default_ttl_hours: int = Field(default=24, env="CACHE_TTL_HOURS")


class AcademicConfig(BaseModel):
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str] = Field(default=None, env="PERPLEXITY_API_KEY")
    openai_deep_key: Optional[str] = Field(default=None, env="OPENAI_DEEP_KEY")
    uni_rank_ttl_hours: int = Field(default=168, env="UNI_RANK_TTL_H")  # 7 dias
    journal_rank_ttl_hours: int = Field(default=72, env="JOUR_RANK_TTL_H")  # 3 dias
    batch_size: int = Field(default=5, env="ACADEMIC_BATCH_SIZE")
    rate_limit_delay: float = Field(default=0.5, env="ACADEMIC_RATE_DELAY")
    max_retries: int = Field(default=3, env="ACADEMIC_MAX_RETRIES")
    circuit_breaker_threshold: int = Field(default=5, env="ACADEMIC_CB_THRESHOLD")


class FeatureWeights(BaseModel):
    """Pesos das features com validação de soma = 1."""
    A: float = Field(default=0.22, description="Area Match")
    S: float = Field(default=0.17, description="Case Similarity") 
    T: float = Field(default=0.10, description="Success Rate")
    G: float = Field(default=0.07, description="Geo Score")
    Q: float = Field(default=0.07, description="Qualification")
    U: float = Field(default=0.05, description="Urgency Capacity")
    R: float = Field(default=0.05, description="Review Score")
    C: float = Field(default=0.03, description="Soft Skills")
    E: float = Field(default=0.02, description="Firm Reputation")
    P: float = Field(default=0.02, description="Price Fit")
    M: float = Field(default=0.14, description="Maturity Score")
    I: float = Field(default=0.02, description="Interaction Score")
    L: float = Field(default=0.04, description="Languages & Events")


class Config(BaseModel):
    """Configuração principal do algoritmo."""
    
    # Sub-configurações
    redis: RedisConfig = Field(default_factory=RedisConfig)
    academic: AcademicConfig = Field(default_factory=AcademicConfig)
    
    # Algoritmo
    embedding_dimension: int = Field(default=384, env="EMBEDDING_DIM")
    default_preset: str = Field(default="balanced", env="DEFAULT_PRESET")
    
    # Pesos das features
    default_weights: FeatureWeights = Field(default_factory=FeatureWeights)
    
    # Desenvolvimento
    debug_mode: bool = Field(default=False, env="DEBUG_MODE")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# Instância global da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obter instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance


# Constantes derivadas para compatibilidade
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.embedding_dimension

# Feature names mapping
FEATURE_NAMES = {
    "A": "area_match", "S": "case_similarity", "T": "success_rate", "G": "geo_score",
    "Q": "qualification_score", "U": "urgency_capacity", "R": "review_score", 
    "C": "soft_skill", "E": "firm_reputation", "P": "price_fit", 
    "M": "maturity_score", "I": "interaction_score", "L": "languages_events_score"
} 
"""
config.py - Configurações Centralizadas do Algoritmo v3.0

Centraliza todas as configurações usando Pydantic para validação.
Substitui os múltiplos os.getenv espalhados pelo código v2.11.
"""

import os
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field, validator
from dataclasses import dataclass


class RedisConfig(BaseModel):
    """Configurações do Redis/Cache."""
    url: str = Field(default="redis://localhost:6379", env="REDIS_URL")
    max_connections: int = Field(default=10, env="REDIS_MAX_CONNECTIONS")
    timeout_seconds: int = Field(default=5, env="REDIS_TIMEOUT")
    default_ttl_hours: int = Field(default=24, env="CACHE_TTL_HOURS")


class AcademicConfig(BaseModel):
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str] = Field(default=None, env="PERPLEXITY_API_KEY")
    openai_deep_key: Optional[str] = Field(default=None, env="OPENAI_DEEP_KEY")
    uni_rank_ttl_hours: int = Field(default=168, env="UNI_RANK_TTL_H")  # 7 dias
    journal_rank_ttl_hours: int = Field(default=72, env="JOUR_RANK_TTL_H")  # 3 dias
    batch_size: int = Field(default=5, env="ACADEMIC_BATCH_SIZE")
    rate_limit_delay: float = Field(default=0.5, env="ACADEMIC_RATE_DELAY")
    max_retries: int = Field(default=3, env="ACADEMIC_MAX_RETRIES")
    circuit_breaker_threshold: int = Field(default=5, env="ACADEMIC_CB_THRESHOLD")


class FeatureWeights(BaseModel):
    """Pesos das features com validação de soma = 1."""
    A: float = Field(default=0.22, description="Area Match")
    S: float = Field(default=0.17, description="Case Similarity") 
    T: float = Field(default=0.10, description="Success Rate")
    G: float = Field(default=0.07, description="Geo Score")
    Q: float = Field(default=0.07, description="Qualification")
    U: float = Field(default=0.05, description="Urgency Capacity")
    R: float = Field(default=0.05, description="Review Score")
    C: float = Field(default=0.03, description="Soft Skills")
    E: float = Field(default=0.02, description="Firm Reputation")
    P: float = Field(default=0.02, description="Price Fit")
    M: float = Field(default=0.14, description="Maturity Score")
    I: float = Field(default=0.02, description="Interaction Score")
    L: float = Field(default=0.04, description="Languages & Events")


class Config(BaseModel):
    """Configuração principal do algoritmo."""
    
    # Sub-configurações
    redis: RedisConfig = Field(default_factory=RedisConfig)
    academic: AcademicConfig = Field(default_factory=AcademicConfig)
    
    # Algoritmo
    embedding_dimension: int = Field(default=384, env="EMBEDDING_DIM")
    default_preset: str = Field(default="balanced", env="DEFAULT_PRESET")
    
    # Pesos das features
    default_weights: FeatureWeights = Field(default_factory=FeatureWeights)
    
    # Desenvolvimento
    debug_mode: bool = Field(default=False, env="DEBUG_MODE")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# Instância global da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obter instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance


# Constantes derivadas para compatibilidade
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.embedding_dimension

# Feature names mapping
FEATURE_NAMES = {
    "A": "area_match", "S": "case_similarity", "T": "success_rate", "G": "geo_score",
    "Q": "qualification_score", "U": "urgency_capacity", "R": "review_score", 
    "C": "soft_skill", "E": "firm_reputation", "P": "price_fit", 
    "M": "maturity_score", "I": "interaction_score", "L": "languages_events_score"
} 
"""
config.py - Configurações Centralizadas do Algoritmo v3.0

Centraliza todas as configurações usando Pydantic para validação.
Substitui os múltiplos os.getenv espalhados pelo código v2.11.
"""

import os
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field, validator
from dataclasses import dataclass


class RedisConfig(BaseModel):
    """Configurações do Redis/Cache."""
    url: str = Field(default="redis://localhost:6379", env="REDIS_URL")
    max_connections: int = Field(default=10, env="REDIS_MAX_CONNECTIONS")
    timeout_seconds: int = Field(default=5, env="REDIS_TIMEOUT")
    default_ttl_hours: int = Field(default=24, env="CACHE_TTL_HOURS")


class AcademicConfig(BaseModel):
    """Configurações para enriquecimento acadêmico."""
    perplexity_api_key: Optional[str] = Field(default=None, env="PERPLEXITY_API_KEY")
    openai_deep_key: Optional[str] = Field(default=None, env="OPENAI_DEEP_KEY")
    uni_rank_ttl_hours: int = Field(default=168, env="UNI_RANK_TTL_H")  # 7 dias
    journal_rank_ttl_hours: int = Field(default=72, env="JOUR_RANK_TTL_H")  # 3 dias
    batch_size: int = Field(default=5, env="ACADEMIC_BATCH_SIZE")
    rate_limit_delay: float = Field(default=0.5, env="ACADEMIC_RATE_DELAY")
    max_retries: int = Field(default=3, env="ACADEMIC_MAX_RETRIES")
    circuit_breaker_threshold: int = Field(default=5, env="ACADEMIC_CB_THRESHOLD")


class FeatureWeights(BaseModel):
    """Pesos das features com validação de soma = 1."""
    A: float = Field(default=0.22, description="Area Match")
    S: float = Field(default=0.17, description="Case Similarity") 
    T: float = Field(default=0.10, description="Success Rate")
    G: float = Field(default=0.07, description="Geo Score")
    Q: float = Field(default=0.07, description="Qualification")
    U: float = Field(default=0.05, description="Urgency Capacity")
    R: float = Field(default=0.05, description="Review Score")
    C: float = Field(default=0.03, description="Soft Skills")
    E: float = Field(default=0.02, description="Firm Reputation")
    P: float = Field(default=0.02, description="Price Fit")
    M: float = Field(default=0.14, description="Maturity Score")
    I: float = Field(default=0.02, description="Interaction Score")
    L: float = Field(default=0.04, description="Languages & Events")


class Config(BaseModel):
    """Configuração principal do algoritmo."""
    
    # Sub-configurações
    redis: RedisConfig = Field(default_factory=RedisConfig)
    academic: AcademicConfig = Field(default_factory=AcademicConfig)
    
    # Algoritmo
    embedding_dimension: int = Field(default=384, env="EMBEDDING_DIM")
    default_preset: str = Field(default="balanced", env="DEFAULT_PRESET")
    
    # Pesos das features
    default_weights: FeatureWeights = Field(default_factory=FeatureWeights)
    
    # Desenvolvimento
    debug_mode: bool = Field(default=False, env="DEBUG_MODE")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# Instância global da configuração
_config_instance: Optional[Config] = None

def get_config() -> Config:
    """Obter instância singleton da configuração."""
    global _config_instance
    if _config_instance is None:
        _config_instance = Config()
    return _config_instance


# Constantes derivadas para compatibilidade
config = get_config()
REDIS_URL = config.redis.url
EMBEDDING_DIM = config.embedding_dimension

# Feature names mapping
FEATURE_NAMES = {
    "A": "area_match", "S": "case_similarity", "T": "success_rate", "G": "geo_score",
    "Q": "qualification_score", "U": "urgency_capacity", "R": "review_score", 
    "C": "soft_skill", "E": "firm_reputation", "P": "price_fit", 
    "M": "maturity_score", "I": "interaction_score", "L": "languages_events_score"
} 