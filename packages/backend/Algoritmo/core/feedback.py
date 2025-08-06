# -*- coding: utf-8 -*-
"""
core/feedback.py

Facade para recording de outcomes e feedback do sistema de matching.
"""

import logging
from datetime import datetime
from typing import Dict, List, Optional, Any
from .base import BaseFacade


class FeedbackFacade(BaseFacade):
    """Facade para registro de feedback e outcomes dos matches."""
    
    def __init__(self, cache=None, db_session=None, logger=None):
        super().__init__(cache, db_session, logger)
        
        if logger is None:
            self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """Inicializa serviços necessários para feedback."""
        if self.logger:
            self.logger.info("FeedbackFacade initialized")
    
    async def record_case_outcome(
        self, 
        case_id: str, 
        lawyer_id: str, 
        client_id: str,
        hired: bool, 
        client_satisfaction: float = 3.0,
        case_success: bool = False,
        case_outcome_value: Optional[float] = None,
        response_time_hours: Optional[float] = None,
        case_duration_days: Optional[int] = None,
        lawyer_rank_position: int = 1,
        total_candidates: int = 5,
        match_score: float = 0.0,
        features_used: Optional[Dict[str, float]] = None,
        preset_used: str = "balanced",
        feedback_notes: Optional[str] = None
    ) -> bool:
        """
        Registra outcome de um caso para aprendizado do algoritmo.
        
        Este método deve ser chamado quando:
        1. Cliente contrata um advogado (hired=True)
        2. Cliente rejeita todos os candidatos (hired=False)
        3. Caso é finalizado com sucesso/insucesso
        4. Cliente avalia a experiência
        
        Args:
            case_id: ID do caso
            lawyer_id: ID do advogado (o que foi contratado ou melhor ranqueado)
            client_id: ID do cliente  
            hired: Se o cliente contratou este advogado
            client_satisfaction: Rating 0.0-5.0 da satisfação do cliente
            case_success: Se o caso foi bem-sucedido
            case_outcome_value: Valor recuperado/economizado (opcional)
            response_time_hours: Tempo real de resposta do advogado
            case_duration_days: Duração do caso em dias
            lawyer_rank_position: Posição do advogado no ranking
            total_candidates: Total de candidatos apresentados
            match_score: Score do match calculado
            features_used: Features e seus valores usados no cálculo
            preset_used: Preset usado no matching
            feedback_notes: Notas adicionais do feedback
            
        Returns:
            True se gravado com sucesso, False caso contrário
        """
        try:
            outcome_data = {
                "case_id": case_id,
                "lawyer_id": lawyer_id,
                "client_id": client_id,
                "hired": hired,
                "client_satisfaction": client_satisfaction,
                "case_success": case_success,
                "case_outcome_value": case_outcome_value,
                "response_time_hours": response_time_hours,
                "case_duration_days": case_duration_days,
                "lawyer_rank_position": lawyer_rank_position,
                "total_candidates": total_candidates,
                "match_score": match_score,
                "features_used": features_used or {},
                "preset_used": preset_used,
                "feedback_notes": feedback_notes,
                "recorded_at": datetime.utcnow().isoformat(),
            }
            
            # Log do feedback
            if self.logger:
                self.logger.info("Case outcome recorded", {
                    "case_id": case_id,
                    "hired": hired,
                    "satisfaction": client_satisfaction,
                    "success": case_success,
                    "preset": preset_used
                })
            
            # Aqui seria a integração com banco de dados para persistir o feedback
            # Por enquanto, apenas logging estruturado
            await self._persist_feedback(outcome_data)
            
            return True
            
        except Exception as e:
            if self.logger:
                self.logger.error("Error recording case outcome", {
                    "case_id": case_id,
                    "error": str(e)
                })
            return False
    
    async def record_multiple_outcomes(
        self,
        case_id: str,
        client_id: str,
        outcomes: List[Dict[str, Any]],
        case_context: Optional[Dict[str, Any]] = None
    ) -> int:
        """
        Registra múltiplos outcomes para um caso (ex: múltiplos candidatos).
        
        Args:
            case_id: ID do caso
            client_id: ID do cliente
            outcomes: Lista de outcomes para diferentes advogados
            case_context: Contexto adicional do caso
            
        Returns:
            Número de outcomes registrados com sucesso
        """
        success_count = 0
        
        for outcome in outcomes:
            # Adicionar informações padrão
            outcome.update({
                "case_id": case_id,
                "client_id": client_id,
            })
            
            # Extrair campos obrigatórios
            lawyer_id = outcome.get("lawyer_id", "")
            hired = outcome.get("hired", False)
            
            success = await self.record_case_outcome(
                case_id=case_id,
                lawyer_id=lawyer_id,
                client_id=client_id,
                hired=hired,
                **{k: v for k, v in outcome.items() 
                   if k not in ["case_id", "lawyer_id", "client_id", "hired"]}
            )
            
            if success:
                success_count += 1
        
        if self.logger:
            self.logger.info("Multiple outcomes recorded", {
                "case_id": case_id,
                "total_outcomes": len(outcomes),
                "successful": success_count
            })
        
        return success_count
    
    async def get_feedback_summary(
        self, 
        lawyer_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Obtém resumo de feedback para um advogado.
        
        Args:
            lawyer_id: ID do advogado
            start_date: Data inicial do período (opcional)
            end_date: Data final do período (opcional)
            
        Returns:
            Dicionário com estatísticas de feedback
        """
        # Implementação futura - buscar dados persistidos
        return {
            "lawyer_id": lawyer_id,
            "total_cases": 0,
            "hire_rate": 0.0,
            "avg_satisfaction": 0.0,
            "success_rate": 0.0,
            "avg_response_time": 0.0,
            "period": {
                "start": start_date.isoformat() if start_date else None,
                "end": end_date.isoformat() if end_date else None
            }
        }
    
    async def _persist_feedback(self, outcome_data: Dict[str, Any]):
        """
        Persiste feedback no banco de dados.
        
        Args:
            outcome_data: Dados do outcome a persistir
        """
        # Implementação futura - integração com DB
        # Por enquanto, apenas log estruturado
        if self.logger:
            self.logger.debug("Feedback data prepared for persistence", outcome_data)


def create_feedback_facade(cache=None, db_session=None, logger=None) -> FeedbackFacade:
    """Factory function para criar FeedbackFacade."""
    return FeedbackFacade(cache=cache, db_session=db_session, logger=logger)
 
 