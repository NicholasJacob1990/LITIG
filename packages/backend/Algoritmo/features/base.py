# -*- coding: utf-8 -*-
"""
features/base.py

Base strategy e interface para cálculo de features do sistema de matching.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any
from ..models.domain import Case, Lawyer


class FeatureStrategy(ABC):
    """Interface base para strategies de cálculo de features."""
    
    def __init__(self, case: Case, lawyer: Lawyer):
        self.case = case
        self.lawyer = lawyer
        self.cv = lawyer.curriculo_json
    
    @abstractmethod
    def calculate(self) -> Dict[str, float]:
        """
        Calcula as features desta strategy.
        
        Returns:
            Dict com chaves sendo os nomes das features e valores sendo scores 0-1
        """
        pass
    
    @property
    def feature_names(self) -> list:
        """Lista de nomes das features que esta strategy calcula."""
        return list(self.calculate().keys())


class FeatureCalculatorContext:
    """Context que orquestra múltiplas strategies de features."""
    
    def __init__(self, case: Case, lawyer: Lawyer):
        self.case = case
        self.lawyer = lawyer
        self._strategies = []
    
    def add_strategy(self, strategy: FeatureStrategy):
        """Adiciona uma strategy de features."""
        self._strategies.append(strategy)
    
    def calculate_all(self) -> Dict[str, float]:
        """Calcula todas as features de todas as strategies."""
        all_features = {}
        for strategy in self._strategies:
            features = strategy.calculate()
            all_features.update(features)
        return all_features
    
    async def calculate_all_async(self) -> Dict[str, float]:
        """Versão assíncrona para features que requerem I/O."""
        all_features = {}
        for strategy in self._strategies:
            if hasattr(strategy, 'calculate_async'):
                features = await strategy.calculate_async()
            else:
                features = strategy.calculate()
            all_features.update(features)
        return all_features
 
 