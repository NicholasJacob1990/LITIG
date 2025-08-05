# -*- coding: utf-8 -*-
"""
modern_matching.py

Versão moderna do MatchmakingAlgorithm usando Dependency Injection e facades.
"""

import logging
from typing import List, Dict, Set, Optional, Any
from .di import setup_di_container, get_matching_orchestrator, inject
from .models.domain import Case, Lawyer, LawFirm


class ModernMatchmakingAlgorithm:
    """
    Versão moderna do algoritmo de matching usando DI e facades.
    
    Esta classe mantém a interface original mas delega todas as operações
    para as facades especializadas via Dependency Injection.
    """
    
    def __init__(self, cache=None, db_session=None, logger=None):
        """
        Inicializa o algoritmo moderno.
        
        Args:
            cache: Cache Redis (opcional)
            db_session: Sessão do banco (opcional)
            logger: Logger (opcional)
        """
        # Configurar DI container
        setup_di_container(
            db_session=db_session,
            logger=logger
        )
        
        # Obter orchestrator via DI
        self.orchestrator = get_matching_orchestrator()
        self.logger = logger or logging.getLogger(__name__)
    
    async def initialize(self):
        """Inicializa o algoritmo e suas dependências."""
        await self.orchestrator.initialize()
        self.logger.info("ModernMatchmakingAlgorithm initialized")
    
    @inject(orchestrator="matching_orchestrator")
    async def rank(
        self, 
        case: Case, 
        lawyers: List[Lawyer], 
        *, 
        top_n: int = 5,
        preset: str = "balanced", 
        model_version: Optional[str] = None,
        exclude_ids: Optional[Set[str]] = None, 
        expand_search: bool = False,
        orchestrator=None
    ) -> List[Dict[str, Any]]:
        """
        Classifica advogados para um caso.
        
        Args:
            case: Caso para matching
            lawyers: Lista de advogados candidatos  
            top_n: Número máximo de resultados
            preset: Preset de pesos a usar
            model_version: Versão do modelo (futuro)
            exclude_ids: IDs de advogados a excluir
            expand_search: Busca híbrida (futuro)
            orchestrator: Injetado automaticamente via DI
            
        Returns:
            Lista de advogados ranqueados
        """
        if orchestrator is None:
            orchestrator = self.orchestrator
        
        # Delegar para o orchestrator
        results = await orchestrator.rank_lawyers(
            case=case,
            lawyers=lawyers,
            top_n=top_n,
            preset=preset,
            exclude_ids=exclude_ids
        )
        
        # Converter para formato compatível com a interface original
        recommendations = []
        for result in results:
            # Simular objeto Recommendation para backward compatibility
            rec = {
                "lawyer_id": result["lawyer_id"],
                "lawyer_name": result["lawyer_name"],
                "score": result["total_score"],
                "features": result["raw_features"],
                "ranking_position": len(recommendations) + 1,
                "preset_used": result["preset_used"]
            }
            recommendations.append(rec)
        
        self.logger.info("Ranking completed", {
            "case_id": case.id,
            "results_count": len(recommendations),
            "preset": preset
        })
        
        return recommendations
    
    @inject(orchestrator="matching_orchestrator")
    async def record_case_outcome(
        self, 
        case_id: str, 
        lawyer_id: str, 
        client_id: str,
        hired: bool, 
        orchestrator=None,
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
            orchestrator: Injetado automaticamente via DI
            
        Returns:
            True se registrado com sucesso
        """
        if orchestrator is None:
            orchestrator = self.orchestrator
        
        return await orchestrator.record_case_outcome(
            case_id=case_id,
            lawyer_id=lawyer_id,
            client_id=client_id,
            hired=hired,
            **kwargs
        )
    
    @inject(orchestrator="matching_orchestrator")
    async def record_multiple_outcomes(
        self,
        case_id: str,
        client_id: str,
        outcomes: List[Dict[str, Any]],
        case_context: Optional[Dict[str, Any]] = None,
        orchestrator=None
    ) -> int:
        """
        Registra múltiplos outcomes para um caso.
        
        Args:
            case_id: ID do caso
            client_id: ID do cliente
            outcomes: Lista de outcomes
            case_context: Contexto adicional
            orchestrator: Injetado automaticamente via DI
            
        Returns:
            Número de outcomes registrados com sucesso
        """
        if orchestrator is None:
            orchestrator = self.orchestrator
        
        return await orchestrator.record_multiple_outcomes(
            case_id=case_id,
            client_id=client_id,
            outcomes=outcomes
        )
    
    # Métodos de conveniência para manter compatibilidade
    
    async def rank_firms(
        self, 
        case: Case, 
        firms: List[LawFirm], 
        *, 
        top_n: int = 3
    ) -> List[Dict[str, Any]]:
        """Ranking específico para escritórios."""
        return await self.orchestrator.rank_firms(
            case=case,
            firms=firms,
            top_n=top_n
        )
    
    async def complete_matching_flow(
        self,
        case: Case,
        lawyers: List[Lawyer],
        *,
        auto_record: bool = False,
        client_id: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Fluxo completo de matching."""
        return await self.orchestrator.complete_matching_flow(
            case=case,
            lawyers=lawyers,
            auto_record=auto_record,
            client_id=client_id,
            **kwargs
        )


def create_modern_matching_algorithm(cache=None, db_session=None, logger=None) -> ModernMatchmakingAlgorithm:
    """Factory function para criar ModernMatchmakingAlgorithm."""
    return ModernMatchmakingAlgorithm(cache=cache, db_session=db_session, logger=logger)
 
 