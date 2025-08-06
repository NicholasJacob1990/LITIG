# -*- coding: utf-8 -*-
"""
features/geographic.py

Strategy para cálculo de features geográficas do sistema de matching.
"""

import numpy as np
from typing import Dict
from .base import FeatureStrategy
from ..utils.math_utils import haversine


class GeographicFeatures(FeatureStrategy):
    """Strategy para features relacionadas à localização geográfica."""
    
    def calculate(self) -> Dict[str, float]:
        """
        Calcula features geográficas.
        
        Returns:
            Dict com feature "G" (geo_score)
        """
        return {
            "G": self.geo_score()
        }
    
    def geo_score(self) -> float:
        """
        Score baseado na distância geográfica entre caso e advogado.
        
        Returns:
            Score 0-1 (1 = próximo, 0 = muito distante)
        """
        dist = haversine(self.case.coords, self.lawyer.geo_latlon)
        return float(np.clip(1 - dist / self.case.radius_km, 0, 1))
 
 