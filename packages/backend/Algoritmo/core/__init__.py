# -*- coding: utf-8 -*-
"""
core/__init__.py

Módulo core com facades de orquestração para o sistema de matching.
"""

from .base import BaseFacade, MatchingContext
from .ranking import RankingFacade, create_ranking_facade
from .feedback import FeedbackFacade, create_feedback_facade
from .orchestrator import MatchingOrchestrator, create_matching_orchestrator

__all__ = [
    "BaseFacade",
    "MatchingContext",
    "RankingFacade",
    "create_ranking_facade",
    "FeedbackFacade", 
    "create_feedback_facade",
    "MatchingOrchestrator",
    "create_matching_orchestrator",
]




