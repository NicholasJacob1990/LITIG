# -*- coding: utf-8 -*-
"""
di/container.py

Container de Dependency Injection para gerenciar dependências do sistema de matching.
"""

import logging
from typing import Dict, Any, TypeVar, Type, Optional, Callable
from functools import lru_cache

T = TypeVar('T')


class DIContainer:
    """
    Container de Dependency Injection simples e eficiente.
    
    Suporta:
    - Registro de singletons
    - Registro de factories 
    - Resolução automática de dependências
    - Configuração via settings
    """
    
    def __init__(self):
        self._singletons: Dict[str, Any] = {}
        self._factories: Dict[str, Callable] = {}
        self._instances: Dict[str, Any] = {}
        self._logger = logging.getLogger(__name__)
    
    def register_singleton(self, name: str, instance: Any):
        """
        Registra uma instância singleton.
        
        Args:
            name: Nome do serviço
            instance: Instância a ser registrada
        """
        self._singletons[name] = instance
        self._logger.debug(f"Registered singleton: {name}")
    
    def register_factory(self, name: str, factory: Callable):
        """
        Registra uma factory function.
        
        Args:
            name: Nome do serviço
            factory: Function que cria a instância
        """
        self._factories[name] = factory
        self._logger.debug(f"Registered factory: {name}")
    
    def get(self, name: str) -> Any:
        """
        Resolve uma dependência pelo nome.
        
        Args:
            name: Nome do serviço
            
        Returns:
            Instância do serviço
            
        Raises:
            ValueError: Se o serviço não for encontrado
        """
        # Verificar singletons primeiro
        if name in self._singletons:
            return self._singletons[name]
        
        # Verificar se já foi instanciado via factory
        if name in self._instances:
            return self._instances[name]
        
        # Usar factory se disponível
        if name in self._factories:
            instance = self._factories[name]()
            self._instances[name] = instance
            self._logger.debug(f"Created instance from factory: {name}")
            return instance
        
        raise ValueError(f"Service '{name}' not registered in DI container")
    
    def get_optional(self, name: str) -> Optional[Any]:
        """
        Resolve uma dependência opcional.
        
        Args:
            name: Nome do serviço
            
        Returns:
            Instância do serviço ou None se não encontrado
        """
        try:
            return self.get(name)
        except ValueError:
            return None
    
    def has(self, name: str) -> bool:
        """
        Verifica se um serviço está registrado.
        
        Args:
            name: Nome do serviço
            
        Returns:
            True se registrado
        """
        return (name in self._singletons or 
                name in self._factories or 
                name in self._instances)
    
    def clear(self):
        """Limpa todos os registros (útil para testes)."""
        self._singletons.clear()
        self._factories.clear()
        self._instances.clear()
        self._logger.debug("DI container cleared")
    
    def list_services(self) -> Dict[str, str]:
        """
        Lista todos os serviços registrados.
        
        Returns:
            Dict com nome do serviço e tipo de registro
        """
        services = {}
        
        for name in self._singletons:
            services[name] = "singleton"
        
        for name in self._factories:
            services[name] = "factory"
        
        for name in self._instances:
            if name not in services:  # Evitar duplicatas
                services[name] = "instance"
        
        return services


# Container global (singleton pattern)
_container: Optional[DIContainer] = None


def get_container() -> DIContainer:
    """Obtém o container global de DI."""
    global _container
    if _container is None:
        _container = DIContainer()
    return _container


def reset_container():
    """Reseta o container global (útil para testes)."""
    global _container
    if _container:
        _container.clear()
    _container = None


# Decorator para injeção automática
def inject(**dependencies):
    """
    Decorator para injeção automática de dependências.
    
    Usage:
        @inject(cache='redis_cache', logger='audit_logger')
        async def my_function(case, lawyers, cache=None, logger=None):
            # cache e logger serão injetados automaticamente
            pass
    """
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            container = get_container()
            
            # Injetar dependências que não foram fornecidas
            for param_name, service_name in dependencies.items():
                if param_name not in kwargs or kwargs[param_name] is None:
                    service = container.get_optional(service_name)
                    if service is not None:
                        kwargs[param_name] = service
            
            return await func(*args, **kwargs)
        
        def sync_wrapper(*args, **kwargs):
            container = get_container()
            
            # Injetar dependências que não foram fornecidas
            for param_name, service_name in dependencies.items():
                if param_name not in kwargs or kwargs[param_name] is None:
                    service = container.get_optional(service_name)
                    if service is not None:
                        kwargs[param_name] = service
            
            return func(*args, **kwargs)
        
        # Detectar se é async function
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator
 
 