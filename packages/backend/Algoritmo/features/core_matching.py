# -*- coding: utf-8 -*-
"""
features/core_matching.py

Strategy para features básicas de matching (área e similaridade de casos).
"""

import numpy as np
from typing import Dict
from .base import FeatureStrategy
from ..utils.math_utils import cosine_similarity


class CoreMatchingFeatures(FeatureStrategy):
    """Strategy para features centrais de matching."""
    
    def calculate(self) -> Dict[str, float]:
        """
        Calcula features básicas de matching.
        
        Returns:
            Dict com features "A" (area_match) e "C" (case_similarity)
        """
        return {
            "A": self.area_match(),
            "C": self.case_similarity()
        }
    
    def area_match(self) -> float:
        """
        Verifica se o advogado tem expertise na área do caso.
        
        Returns:
            1.0 se há match de área, 0.0 caso contrário
        """
        return 1.0 if self.case.area in self.lawyer.tags_expertise else 0.0
    
    def case_similarity(self) -> float:
        """
        Combina similaridade de casos práticos com pareceres técnicos.
        
        Returns:
            Score 0-1 baseado na similaridade dos embeddings
        """
        # ── 2-a) Similaridade com casos práticos ──────────────────────
        sim_hist = 0.0
        embeddings_hist = self.lawyer.casos_historicos_embeddings
        if embeddings_hist and self.case.summary_embedding is not None:
            sims_hist = [cosine_similarity(self.case.summary_embedding, e) for e in embeddings_hist]
            outcomes = self.lawyer.case_outcomes
            if outcomes and len(outcomes) == len(sims_hist):
                weights = [1.0 if outcome else 0.8 for outcome in outcomes]
                sim_hist = float(np.average(sims_hist, weights=weights))
            else:
                sim_hist = float(np.mean(sims_hist))

        # ── 2-b) Similaridade com pareceres ───────────────────────────
        sim_par = 0.0
        if self.lawyer.pareceres and self.case.summary_embedding is not None:
            sims_par = [cosine_similarity(self.case.summary_embedding, p.embedding) for p in self.lawyer.pareceres]
            sim_par = float(max(sims_par)) if sims_par else 0.0

        # ── 2-c) Combinação ponderada ─────────────────────────────────
        if sim_par == 0:
            return sim_hist
        return 0.6 * sim_hist + 0.4 * sim_par
 
 