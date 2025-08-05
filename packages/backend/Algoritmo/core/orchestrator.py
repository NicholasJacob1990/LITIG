# -*- coding: utf-8 -*-
"""
core/orchestrator.py

Facade principal que orquestra todas as facades do sistema de matching.
"""

import logging
from typing import Dict, List, Optional, Set, Any
from .base import MatchingContext
from .ranking import RankingFacade, create_ranking_facade
from .feedback import FeedbackFacade, create_feedback_facade
from ..models.domain import Case, Lawyer, LawFirm


class MatchingOrchestrator:
    """
    Facade principal que orquestra todas as operações de matching.
    
    Esta classe serve como ponto de entrada único para o sistema de matching,
    delegando operações específicas para as facades especializadas.
    """
    
    def __init__(self, cache=None, db_session=None, logger=None):
        """
        Inicializa o orquestrador com dependências.
        
        Args:
            cache: Instância do cache (Redis)
            db_session: Sessão do banco de dados
            logger: Logger para auditoria
        """
        self.cache = cache
        self.db_session = db_session
        self.logger = logger or logging.getLogger(__name__)
        
        # Inicializar context de facades
        self.context = MatchingContext()
        self._setup_facades()
    
    def _setup_facades(self):
        """Configura todas as facades necessárias."""
        # Ranking facade
        ranking_facade = create_ranking_facade(
            cache=self.cache,
            db_session=self.db_session,
            logger=self.logger
        )
        self.context.register_facade("ranking", ranking_facade)
        
        # Feedback facade
        feedback_facade = create_feedback_facade(
            cache=self.cache,
            db_session=self.db_session,
            logger=self.logger
        )
        self.context.register_facade("feedback", feedback_facade)
    
    async def initialize(self):
        """Inicializa todas as facades."""
        await self.context.initialize_all()
        self.logger.info("MatchingOrchestrator initialized with all facades")
    
    # ===============================
    # Ranking Operations
    # ===============================
    
    async def rank_lawyers(
        self, 
        case: Case, 
        lawyers: List[Lawyer], 
        *, 
        top_n: int = 5,
        preset: str = "balanced",
        exclude_ids: Optional[Set[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Classifica advogados para um caso.
        
        Args:
            case: Caso para matching
            lawyers: Lista de advogados candidatos
            top_n: Número máximo de resultados
            preset: Preset de pesos a usar
            exclude_ids: IDs de advogados a excluir
            
        Returns:
            Lista de advogados ranqueados com scores detalhados
        """
        ranking_facade = self.context.get_facade("ranking")
        if not ranking_facade:
            raise RuntimeError("RankingFacade not initialized")
        
        return await ranking_facade.rank_lawyers(
            case=case,
            lawyers=lawyers,
            top_n=top_n,
            preset=preset,
            exclude_ids=exclude_ids
        )
    
    async def rank_firms(
        self, 
        case: Case, 
        firms: List[LawFirm], 
        *, 
        top_n: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Classifica escritórios de advocacia para um caso.
        
        Args:
            case: Caso para matching
            firms: Lista de escritórios candidatos
            top_n: Número máximo de resultados
            
        Returns:
            Lista de escritórios ranqueados
        """
        ranking_facade = self.context.get_facade("ranking")
        if not ranking_facade:
            raise RuntimeError("RankingFacade not initialized")
        
        return await ranking_facade.rank_firms(case=case, firms=firms, top_n=top_n)
    
    # ===============================
    # Feedback Operations
    # ===============================
    
    async def record_case_outcome(
        self, 
        case_id: str, 
        lawyer_id: str, 
        client_id: str,
        hired: bool, 
        **kwargs
    ) -> bool:
        """
        Registra outcome de um caso.
        
        Args:
            case_id: ID do caso
            lawyer_id: ID do advogado
            client_id: ID do cliente
            hired: Se foi contratado
            **kwargs: Outros parâmetros de feedback
            
        Returns:
            True se registrado com sucesso
        """
        feedback_facade = self.context.get_facade("feedback")
        if not feedback_facade:
            raise RuntimeError("FeedbackFacade not initialized")
        
        return await feedback_facade.record_case_outcome(
            case_id=case_id,
            lawyer_id=lawyer_id,
            client_id=client_id,
            hired=hired,
            **kwargs
        )
    
    async def record_multiple_outcomes(
        self,
        case_id: str,
        client_id: str,
        outcomes: List[Dict[str, Any]]
    ) -> int:
        """
        Registra múltiplos outcomes para um caso.
        
        Args:
            case_id: ID do caso
            client_id: ID do cliente
            outcomes: Lista de outcomes
            
        Returns:
            Número de outcomes registrados com sucesso
        """
        feedback_facade = self.context.get_facade("feedback")
        if not feedback_facade:
            raise RuntimeError("FeedbackFacade not initialized")
        
        return await feedback_facade.record_multiple_outcomes(
            case_id=case_id,
            client_id=client_id,
            outcomes=outcomes
        )
    
    # ===============================
    # Unified Operations
    # ===============================
    
    async def complete_matching_flow(
        self,
        case: Case,
        lawyers: List[Lawyer],
        *,
        top_n: int = 5,
        preset: str = "balanced",
        exclude_ids: Optional[Set[str]] = None,
        auto_record: bool = False,
        client_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Fluxo completo de matching com ranking e registro opcional.
        
        Args:
            case: Caso para matching
            lawyers: Lista de candidatos
            top_n: Número de resultados
            preset: Preset a usar
            exclude_ids: IDs a excluir
            auto_record: Se deve registrar automaticamente o matching
            client_id: ID do cliente (necessário se auto_record=True)
            
        Returns:
            Resultado completo com ranking e metadados
        """
        # Executar ranking
        ranked_lawyers = await self.rank_lawyers(
            case=case,
            lawyers=lawyers,
            top_n=top_n,
            preset=preset,
            exclude_ids=exclude_ids
        )
        
        result = {
            "case_id": case.id,
            "matched_lawyers": ranked_lawyers,
            "preset_used": preset,
            "total_candidates": len(lawyers),
            "returned_results": len(ranked_lawyers),
            "timestamp": "utcnow().isoformat()"
        }
        
        # Registro automático opcional
        if auto_record and client_id and ranked_lawyers:
            # Registrar matching realizado (não hiring ainda)
            for i, lawyer_data in enumerate(ranked_lawyers):
                await self.record_case_outcome(
                    case_id=case.id,
                    lawyer_id=lawyer_data["lawyer_id"],
                    client_id=client_id,
                    hired=False,  # Ainda não foi contratado
                    lawyer_rank_position=i + 1,
                    total_candidates=len(lawyers),
                    match_score=lawyer_data["total_score"],
                    features_used=lawyer_data.get("raw_features", {}),
                    preset_used=preset
                )
            
            result["auto_recorded"] = True
        
        self.logger.info("Complete matching flow executed", {
            "case_id": case.id,
            "results_count": len(ranked_lawyers),
            "preset": preset,
            "auto_recorded": auto_record
        })
        
        return result


def create_matching_orchestrator(cache=None, db_session=None, logger=None) -> MatchingOrchestrator:
    """Factory function para criar MatchingOrchestrator."""
    return MatchingOrchestrator(cache=cache, db_session=db_session, logger=logger)
 
 