# -*- coding: utf-8 -*-
"""
features/__init__.py

Módulo de features calculadas em strategies para o sistema de matching.
"""

from .base import FeatureStrategy, FeatureCalculatorContext
from .core_matching import CoreMatchingFeatures
from .geographic import GeographicFeatures
from .performance import PerformanceFeatures
from .calculator import ModernFeatureCalculator, create_feature_calculator

__all__ = [
    "FeatureStrategy",
    "FeatureCalculatorContext",
    "CoreMatchingFeatures",
    "GeographicFeatures", 
    "PerformanceFeatures",
    "ModernFeatureCalculator",
    "create_feature_calculator",
]




