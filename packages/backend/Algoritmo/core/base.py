# -*- coding: utf-8 -*-
"""
core/base.py

Base facade e interfaces para orquestração do sistema de matching.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from ..models.domain import Case, Lawyer, LawFirm


class BaseFacade(ABC):
    """Base facade para componentes de orquestração do matching."""
    
    def __init__(self, cache=None, db_session=None, logger=None):
        self.cache = cache
        self.db_session = db_session
        self.logger = logger
    
    @abstractmethod
    async def initialize(self):
        """Inicialização assíncrona da facade."""
        pass


class MatchingContext:
    """Context que coordena múltiplas facades do sistema de matching."""
    
    def __init__(self):
        self._facades = {}
        self._initialized = False
    
    def register_facade(self, name: str, facade: BaseFacade):
        """Registra uma facade no context."""
        self._facades[name] = facade
    
    def get_facade(self, name: str) -> Optional[BaseFacade]:
        """Recupera uma facade pelo nome."""
        return self._facades.get(name)
    
    async def initialize_all(self):
        """Inicializa todas as facades registradas."""
        for facade in self._facades.values():
            await facade.initialize()
        self._initialized = True
    
    @property
    def is_initialized(self) -> bool:
        """Verifica se o context está inicializado."""
        return self._initialized
 
 