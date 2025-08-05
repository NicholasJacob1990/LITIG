# -*- coding: utf-8 -*-
"""
core/ranking.py

Facade para lógica de ranking e scoring de advogados.
"""

import asyncio
import logging
from typing import Dict, List, Optional, Set, Any
from .base import BaseFacade
from ..models.domain import Case, Lawyer, LawFirm
from ..features import ModernFeatureCalculator
from ..config import PRESET_WEIGHTS


class RankingFacade(BaseFacade):
    """Facade para orquestração do ranking de advogados."""
    
    def __init__(self, cache=None, db_session=None, logger=None):
        super().__init__(cache, db_session, logger)
        self.ml_service = None
        self._ml_service_initialized = False
        
        if logger is None:
            self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """Inicializa serviços necessários para ranking."""
        # Inicialização de ML service será implementada conforme necessário
        self._ml_service_initialized = True
        if self.logger:
            self.logger.info("RankingFacade initialized")
    
    async def rank_lawyers(
        self, 
        case: Case, 
        lawyers: List[Lawyer], 
        *, 
        top_n: int = 5,
        preset: str = "balanced",
        model_version: Optional[str] = None,
        exclude_ids: Optional[Set[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Classifica advogados para um caso usando features modernas.
        
        Args:
            case: Caso para matching
            lawyers: Lista de advogados candidatos
            top_n: Número máximo de resultados
            preset: Preset de pesos a usar
            model_version: Versão do modelo (para futuro)
            exclude_ids: IDs de advogados a excluir
            
        Returns:
            Lista de advogados ranqueados com scores
        """
        if not lawyers:
            return []
        
        # Filtrar advogados excluídos
        if exclude_ids:
            lawyers = [lw for lw in lawyers if lw.id not in exclude_ids]
            if not lawyers:
                return []
        
        # Log inicial
        if self.logger:
            self.logger.info("Starting lawyer ranking", {
                "case_id": case.id,
                "num_lawyers": len(lawyers),
                "preset": preset,
                "top_n": top_n
            })
        
        # Obter pesos do preset
        weights = self._get_preset_weights(preset)
        
        # Calcular scores para todos os advogados
        lawyer_scores = []
        for lawyer in lawyers:
            score_data = await self._calculate_lawyer_score(case, lawyer, weights, preset)
            lawyer_scores.append(score_data)
        
        # Ordenar por score total
        lawyer_scores.sort(key=lambda x: x['total_score'], reverse=True)
        
        # Retornar top_n resultados
        results = lawyer_scores[:top_n]
        
        if self.logger:
            self.logger.info("Ranking completed", {
                "case_id": case.id,
                "results_count": len(results),
                "top_score": results[0]['total_score'] if results else 0
            })
        
        return results
    
    async def _calculate_lawyer_score(
        self, 
        case: Case, 
        lawyer: Lawyer, 
        weights: Dict[str, float], 
        preset: str
    ) -> Dict[str, Any]:
        """Calcula score total para um advogado usando ModernFeatureCalculator."""
        
        # Usar o novo FeatureCalculator
        calculator = ModernFeatureCalculator(case, lawyer)
        features = await calculator.all_async()
        
        # Calcular score ponderado
        total_score = 0.0
        weighted_features = {}
        
        for feature_key, weight in weights.items():
            feature_value = features.get(feature_key, 0.0)
            weighted_score = feature_value * weight
            weighted_features[feature_key] = {
                "raw_value": feature_value,
                "weight": weight,
                "weighted_score": weighted_score
            }
            total_score += weighted_score
        
        return {
            "lawyer_id": lawyer.id,
            "lawyer_name": lawyer.nome,
            "total_score": round(total_score, 4),
            "features": weighted_features,
            "preset_used": preset,
            "raw_features": features
        }
    
    def _get_preset_weights(self, preset: str) -> Dict[str, float]:
        """Obtém pesos do preset especificado."""
        weights = PRESET_WEIGHTS.get(preset)
        if not weights:
            if self.logger:
                self.logger.warning(f"Preset '{preset}' not found, using 'balanced'")
            weights = PRESET_WEIGHTS.get("balanced", {})
        
        return weights
    
    async def rank_firms(
        self, 
        case: Case, 
        firms: List[LawFirm], 
        *, 
        top_n: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Ranking específico para escritórios de advocacia.
        
        Args:
            case: Caso para matching
            firms: Lista de escritórios candidatos
            top_n: Número máximo de resultados
            
        Returns:
            Lista de escritórios ranqueados
        """
        if not firms:
            return []
        
        # Usar preset corporativo para firms
        return await self.rank_lawyers(
            case, 
            firms,  # LawFirm herda de Lawyer
            top_n=top_n, 
            preset="corporate"
        )


def create_ranking_facade(cache=None, db_session=None, logger=None) -> RankingFacade:
    """Factory function para criar RankingFacade."""
    return RankingFacade(cache=cache, db_session=db_session, logger=logger)
 
 