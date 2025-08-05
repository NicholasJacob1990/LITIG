# -*- coding: utf-8 -*-
"""
performance/__init__.py

Módulo de otimizações de performance para o sistema de matching.
"""

from .rate_limiters import (
    RateLimitConfig,
    SmartRateLimiter,
    RateLimiterPool,
    get_rate_limiter_pool,
    rate_limited,
    rate_limit,
)

__all__ = [
    "RateLimitConfig",
    "SmartRateLimiter", 
    "RateLimiterPool",
    "get_rate_limiter_pool",
    "rate_limited",
    "rate_limit",
]
 
 