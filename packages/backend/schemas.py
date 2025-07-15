from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

class AllocationType(str, Enum):
    """Tipos de alocação de casos conforme ARQUITETURA_GERAL_DO_SISTEMA.md"""
    PLATFORM_MATCH_DIRECT = "platform_match_direct"
    PLATFORM_MATCH_PARTNERSHIP = "platform_match_partnership"
    PARTNERSHIP_PROACTIVE_SEARCH = "partnership_proactive_search"
    PARTNERSHIP_PLATFORM_SUGGESTION = "partnership_platform_suggestion"
    INTERNAL_DELEGATION = "internal_delegation"

class CaseContextualData(BaseModel):
    """Dados contextuais específicos por tipo de alocação"""
    allocation_type: AllocationType
    match_score: Optional[float] = Field(None, description="Score do match (0-100)")
    response_deadline: Optional[datetime] = Field(None, description="Prazo limite para resposta")
    partner_id: Optional[str] = Field(None, description="ID do parceiro em casos de parceria")
    delegated_by: Optional[str] = Field(None, description="ID do usuário que delegou")
    context_metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados contextuais")
    
    # Dados específicos por contexto
    partner_name: Optional[str] = Field(None, description="Nome do parceiro")
    partner_specialization: Optional[str] = Field(None, description="Especialização do parceiro")
    partner_rating: Optional[float] = Field(None, description="Rating do parceiro")
    your_share: Optional[int] = Field(None, description="Sua parte na parceria (%)")
    partner_share: Optional[int] = Field(None, description="Parte do parceiro (%)")
    collaboration_area: Optional[str] = Field(None, description="Área de colaboração")
    response_time_left: Optional[str] = Field(None, description="Tempo restante para resposta")
    distance: Optional[float] = Field(None, description="Distância em km")
    estimated_value: Optional[float] = Field(None, description="Valor estimado")
    initiator_name: Optional[str] = Field(None, description="Nome do iniciador da parceria")
    sla_hours: Optional[int] = Field(None, description="SLA em horas")
    conversion_rate: Optional[float] = Field(None, description="Taxa de conversão")
    complexity_score: Optional[int] = Field(None, description="Score de complexidade (1-10)")
    hours_budgeted: Optional[int] = Field(None, description="Horas orçadas")
    hourly_rate: Optional[float] = Field(None, description="Valor por hora")

class CaseContextualResponse(BaseModel):
    """Resposta de caso com dados contextuais"""
    id: str
    client_id: str
    lawyer_id: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime
    
    # Dados contextuais
    contextual_data: CaseContextualData
    
    # Dados básicos do caso
    summary: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    ai_analysis: Optional[Dict[str, Any]] = None

class CaseKPIsByContext(BaseModel):
    """KPIs específicos por contexto de alocação"""
    allocation_type: AllocationType
    kpis: List[Dict[str, Any]]
    
    class Config:
        schema_extra = {
            "example": {
                "allocation_type": "platform_match_direct",
                "kpis": [
                    {"icon": "🎯", "label": "Match Score", "value": "94%"},
                    {"icon": "📍", "label": "Distância", "value": "12km"},
                    {"icon": "💰", "label": "Valor", "value": "R$ 8.500"},
                    {"icon": "⏱️", "label": "SLA", "value": "2h 15min"}
                ]
            }
        }

class CaseActionsResponse(BaseModel):
    """Ações contextuais disponíveis para o caso"""
    primary_action: Dict[str, str]
    secondary_actions: List[Dict[str, str]]
    
    class Config:
        schema_extra = {
            "example": {
                "primary_action": {"label": "Aceitar Caso", "action": "accept_case"},
                "secondary_actions": [
                    {"label": "Ver Perfil do Cliente", "action": "view_client_profile"},
                    {"label": "Solicitar Informações", "action": "request_info"}
                ]
            }
        }

class CaseHighlightResponse(BaseModel):
    """Destaque contextual do caso"""
    text: str
    color: str
    
    class Config:
        schema_extra = {
            "example": {
                "text": "🎯 Match direto para você",
                "color": "blue"
            }
        }

class ContextualCaseDetailsResponse(BaseModel):
    """Resposta completa com todos os dados contextuais"""
    case: CaseContextualResponse
    kpis: CaseKPIsByContext
    actions: CaseActionsResponse
    highlight: CaseHighlightResponse 