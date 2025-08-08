# -*- coding: utf-8 -*-
"""
features/performance.py

Strategy para features de performance e histórico de sucesso.
"""

import numpy as np
from typing import Dict
from .base import FeatureStrategy


class PerformanceFeatures(FeatureStrategy):
    """Strategy para features de performance histórica."""
    
    def calculate(self) -> Dict[str, float]:
        """
        Calcula features de performance.
        
        Returns:
            Dict com feature "S" (success_rate)
        """
        return {
            "T": self.success_rate()
        }
    
    def success_rate(self) -> float:
        """
        Success rate ponderado por valor econômico recuperado.

        Fórmula:
        1. Se houver dados de valor ⇒ taxa_ponderada = valor_recuperado / valor_total.
           • Penaliza amostras < 20 casos com fator (n/20).
        2. Caso contrário, cai no cálculo anterior (wins/cases) com smoothing.
        3. Multiplicador `success_status` mantém lógica V/P/N.
        
        Returns:
            Score 0-1 de taxa de sucesso
        """
        status_mult = {"V": 1.0, "P": 0.4, "N": 0.0}.get(self.lawyer.kpi.success_status, 0.0)

        kpi = self.lawyer.kpi
        if kpi.valor_total_30d > 0:
            base = kpi.valor_recuperado_30d / kpi.valor_total_30d
            # Penaliza baixa amostragem (<20 casos)
            sample_factor = min(1.0, kpi.cases_30d / 20.0)
            weighted = base * sample_factor
            return float(np.clip(weighted * status_mult, 0, 1))

        # --- fallback antigo ---
        key = f"{self.case.area}/{self.case.subarea}"
        granular = self.lawyer.kpi_subarea.get(key)
        total_cases = kpi.cases_30d or 1
        alpha = beta = 1
        if granular is not None:
            wins = int(granular * total_cases)
            base = (wins + alpha) / (total_cases + alpha + beta)
        else:
            wins_general = int(kpi.success_rate * total_cases)
            base = (wins_general + alpha) / (total_cases + alpha + beta)

        return float(np.clip(base * status_mult, 0, 1))
 
 