# -*- coding: utf-8 -*-
"""
performance/rate_limiters.py

Sistema de rate limiters inteligentes para APIs externas e operações custosas.
"""

import asyncio
import time
from typing import Dict, Optional, Callable, Any, List
from dataclasses import dataclass, field
from contextlib import asynccontextmanager


@dataclass
class RateLimitConfig:
    """Configuração de rate limiting."""
    requests_per_second: float
    burst_capacity: int = 10
    backoff_multiplier: float = 1.5
    max_backoff: float = 60.0
    retry_attempts: int = 3


class TokenBucket:
    """
    Implementação de Token Bucket para rate limiting suave.
    
    Permite rajadas controladas mantendo taxa média.
    """
    
    def __init__(self, rate: float, capacity: int):
        """
        Inicializa token bucket.
        
        Args:
            rate: Tokens por segundo
            capacity: Capacidade máxima do bucket
        """
        self.rate = rate
        self.capacity = capacity
        self.tokens = capacity
        self.last_update = time.time()
        self._lock = asyncio.Lock()
    
    async def acquire(self, tokens: int = 1) -> bool:
        """
        Tenta adquirir tokens.
        
        Args:
            tokens: Número de tokens necessários
            
        Returns:
            True se tokens foram adquiridos
        """
        async with self._lock:
            now = time.time()
            
            # Adicionar tokens baseado no tempo decorrido
            elapsed = now - self.last_update
            self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
            self.last_update = now
            
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            
            return False
    
    async def wait_for_tokens(self, tokens: int = 1) -> float:
        """
        Espera até tokens estarem disponíveis.
        
        Args:
            tokens: Número de tokens necessários
            
        Returns:
            Tempo de espera em segundos
        """
        start_time = time.time()
        
        while not await self.acquire(tokens):
            # Calcular tempo de espera baseado na falta de tokens
            deficit = tokens - self.tokens
            wait_time = deficit / self.rate
            await asyncio.sleep(min(wait_time, 0.1))  # Max 100ms sleep
        
        return time.time() - start_time


class SmartRateLimiter:
    """
    Rate limiter inteligente com adaptação automática e backoff.
    """
    
    def __init__(self, config: RateLimitConfig, name: str = "default"):
        """
        Inicializa rate limiter.
        
        Args:
            config: Configuração de rate limiting
            name: Nome do rate limiter para logging
        """
        self.config = config
        self.name = name
        self.bucket = TokenBucket(config.requests_per_second, config.burst_capacity)
        
        # Estatísticas e adaptação
        self.total_requests = 0
        self.failed_requests = 0
        self.avg_response_time = 0.0
        self.last_failure_time = 0.0
        self.current_backoff = 0.0
        
        # Histórico para adaptação
        self.recent_response_times: List[float] = []
        self.max_history_size = 100
    
    async def execute(self, func: Callable, *args, **kwargs) -> Any:
        """
        Executa função com rate limiting e retry inteligente.
        
        Args:
            func: Função a ser executada
            *args: Argumentos da função
            **kwargs: Argumentos nomeados da função
            
        Returns:
            Resultado da função
            
        Raises:
            Exception: Se todas as tentativas falharem
        """
        last_exception = None
        
        for attempt in range(self.config.retry_attempts):
            try:
                # Aplicar backoff se necessário
                if self.current_backoff > 0:
                    await asyncio.sleep(self.current_backoff)
                
                # Aguardar tokens disponíveis
                wait_time = await self.bucket.wait_for_tokens()
                
                # Executar função com timing
                start_time = time.time()
                result = await func(*args, **kwargs) if asyncio.iscoroutinefunction(func) else func(*args, **kwargs)
                response_time = time.time() - start_time
                
                # Registrar sucesso
                self._record_success(response_time, wait_time)
                
                return result
                
            except Exception as e:
                last_exception = e
                self._record_failure()
                
                # Backoff exponencial no último retry
                if attempt < self.config.retry_attempts - 1:
                    backoff = min(
                        self.config.backoff_multiplier ** attempt,
                        self.config.max_backoff
                    )
                    await asyncio.sleep(backoff)
        
        # Todas as tentativas falharam
        raise last_exception
    
    def _record_success(self, response_time: float, wait_time: float):
        """Registra sucesso e atualiza estatísticas."""
        self.total_requests += 1
        
        # Atualizar tempo médio de resposta
        alpha = 0.1  # Fator de suavização
        self.avg_response_time = (
            alpha * response_time + (1 - alpha) * self.avg_response_time
        )
        
        # Adicionar ao histórico
        self.recent_response_times.append(response_time)
        if len(self.recent_response_times) > self.max_history_size:
            self.recent_response_times.pop(0)
        
        # Reduzir backoff em caso de sucesso
        self.current_backoff *= 0.8
        if self.current_backoff < 0.1:
            self.current_backoff = 0.0
    
    def _record_failure(self):
        """Registra falha e ajusta backoff."""
        self.failed_requests += 1
        self.last_failure_time = time.time()
        
        # Aumentar backoff
        self.current_backoff = min(
            max(self.current_backoff * self.config.backoff_multiplier, 1.0),
            self.config.max_backoff
        )
    
    def get_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas do rate limiter."""
        success_rate = 1.0 - (self.failed_requests / max(self.total_requests, 1))
        
        return {
            "name": self.name,
            "total_requests": self.total_requests,
            "failed_requests": self.failed_requests,
            "success_rate": success_rate,
            "avg_response_time": self.avg_response_time,
            "current_backoff": self.current_backoff,
            "bucket_tokens": self.bucket.tokens,
            "recent_response_times": self.recent_response_times[-10:],  # Últimos 10
        }


class RateLimiterPool:
    """Pool de rate limiters para diferentes serviços/APIs."""
    
    def __init__(self):
        """Inicializa pool vazio."""
        self.limiters: Dict[str, SmartRateLimiter] = {}
    
    def add_limiter(self, name: str, config: RateLimitConfig) -> SmartRateLimiter:
        """
        Adiciona rate limiter ao pool.
        
        Args:
            name: Nome único do rate limiter
            config: Configuração do rate limiter
            
        Returns:
            Rate limiter criado
        """
        limiter = SmartRateLimiter(config, name)
        self.limiters[name] = limiter
        return limiter
    
    def get_limiter(self, name: str) -> Optional[SmartRateLimiter]:
        """Obtém rate limiter por nome."""
        return self.limiters.get(name)
    
    async def execute_with_limiter(self, limiter_name: str, func: Callable, *args, **kwargs) -> Any:
        """
        Executa função usando rate limiter específico.
        
        Args:
            limiter_name: Nome do rate limiter
            func: Função a executar
            *args: Argumentos da função
            **kwargs: Argumentos nomeados
            
        Returns:
            Resultado da função
            
        Raises:
            ValueError: Se rate limiter não existir
        """
        limiter = self.get_limiter(limiter_name)
        if not limiter:
            raise ValueError(f"Rate limiter '{limiter_name}' not found")
        
        return await limiter.execute(func, *args, **kwargs)
    
    def get_all_stats(self) -> Dict[str, Dict[str, Any]]:
        """Retorna estatísticas de todos os rate limiters."""
        return {name: limiter.get_stats() for name, limiter in self.limiters.items()}


# Pool global de rate limiters
_global_pool: Optional[RateLimiterPool] = None


def get_rate_limiter_pool() -> RateLimiterPool:
    """Obtém pool global de rate limiters."""
    global _global_pool
    if _global_pool is None:
        _global_pool = RateLimiterPool()
        _setup_default_limiters(_global_pool)
    return _global_pool


def _setup_default_limiters(pool: RateLimiterPool):
    """Configura rate limiters padrão para APIs conhecidas."""
    
    # Perplexity API
    pool.add_limiter("perplexity", RateLimitConfig(
        requests_per_second=0.5,  # 30 req/min
        burst_capacity=5,
        backoff_multiplier=2.0,
        max_backoff=30.0,
        retry_attempts=3
    ))
    
    # Escavador API
    pool.add_limiter("escavador", RateLimitConfig(
        requests_per_second=0.33,  # 20 req/min
        burst_capacity=3,
        backoff_multiplier=1.8,
        max_backoff=45.0,
        retry_attempts=2
    ))
    
    # LTR Service
    pool.add_limiter("ltr_service", RateLimitConfig(
        requests_per_second=10.0,  # 600 req/min
        burst_capacity=20,
        backoff_multiplier=1.2,
        max_backoff=5.0,
        retry_attempts=2
    ))
    
    # Redis Cache
    pool.add_limiter("redis_cache", RateLimitConfig(
        requests_per_second=100.0,  # 6000 req/min
        burst_capacity=50,
        backoff_multiplier=1.1,
        max_backoff=1.0,
        retry_attempts=1
    ))


# Context manager para uso simplificado
@asynccontextmanager
async def rate_limited(limiter_name: str):
    """
    Context manager para rate limiting simplificado.
    
    Args:
        limiter_name: Nome do rate limiter
    """
    pool = get_rate_limiter_pool()
    limiter = pool.get_limiter(limiter_name)
    
    if not limiter:
        raise ValueError(f"Rate limiter '{limiter_name}' not found")
    
    await limiter.bucket.wait_for_tokens()
    yield limiter


# Decorator para rate limiting automático
def rate_limit(limiter_name: str):
    """
    Decorator para aplicar rate limiting automaticamente.
    
    Args:
        limiter_name: Nome do rate limiter a usar
    """
    def decorator(func: Callable) -> Callable:
        async def async_wrapper(*args, **kwargs):
            pool = get_rate_limiter_pool()
            return await pool.execute_with_limiter(limiter_name, func, *args, **kwargs)
        
        def sync_wrapper(*args, **kwargs):
            # Para funções síncronas, criar event loop se necessário
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            return loop.run_until_complete(async_wrapper(*args, **kwargs))
        
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator
 
 