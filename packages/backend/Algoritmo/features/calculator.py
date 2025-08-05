# -*- coding: utf-8 -*-
"""
features/calculator.py

FeatureCalculator moderno usando Strategy Pattern mantendo backward compatibility.
"""

from typing import Dict
from .base import FeatureCalculatorContext
from .core_matching import CoreMatchingFeatures
from .geographic import GeographicFeatures
from .performance import PerformanceFeatures
from .enriched_semantic import EnrichedSemanticFeatures
from ..models.domain import Case, Lawyer


class ModernFeatureCalculator:
    """
    FeatureCalculator moderno usando Strategy Pattern.
    Mantém a mesma interface do FeatureCalculator original para backward compatibility.
    """
    
    def __init__(self, case: Case, lawyer: Lawyer):
        self.case = case
        self.lawyer = lawyer
        self.cv = lawyer.curriculo_json
        
        # Inicializar context com strategies
        self.context = FeatureCalculatorContext(case, lawyer)
        self._setup_strategies()
    
    def _setup_strategies(self):
        """Configura as strategies de features."""
        self.context.add_strategy(CoreMatchingFeatures(self.case, self.lawyer))
        self.context.add_strategy(GeographicFeatures(self.case, self.lawyer))
        self.context.add_strategy(PerformanceFeatures(self.case, self.lawyer))
        self.context.add_strategy(EnrichedSemanticFeatures(self.case, self.lawyer))
        # Outras strategies serão adicionadas gradualmente
    
    def all(self) -> Dict[str, float]:
        """
        Calcula todas as features disponíveis.
        
        Returns:
            Dict com todas as features calculadas
        """
        return self.context.calculate_all()
    
    async def all_async(self) -> Dict[str, float]:
        """
        Versão assíncrona para features que requerem I/O.
        
        Returns:
            Dict com todas as features calculadas
        """
        return await self.context.calculate_all_async()
    
    # Métodos individuais para backward compatibility
    def area_match(self) -> float:
        """Backward compatibility - area match."""
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        return strategy.area_match()
    
    def case_similarity(self) -> float:
        """Backward compatibility - case similarity."""
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        return strategy.case_similarity()
    
    def success_rate(self) -> float:
        """Backward compatibility - success rate."""
        strategy = PerformanceFeatures(self.case, self.lawyer)
        return strategy.success_rate()
    
    def geo_score(self) -> float:
        """Backward compatibility - geo score."""
        strategy = GeographicFeatures(self.case, self.lawyer)
        return strategy.geo_score()


# Factory function para facilitar testes e DI
def create_feature_calculator(case: Case, lawyer: Lawyer) -> ModernFeatureCalculator:
    """Factory function para criar FeatureCalculator."""
    return ModernFeatureCalculator(case, lawyer)
 
 