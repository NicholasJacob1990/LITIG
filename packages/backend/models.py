# backend/models.py
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Literal, Optional, Tuple
from uuid import UUID

from pydantic import BaseModel

# Pydantic DTOs (Data Transfer Objects)


class TriageRequest(BaseModel):
    """Payload para a nova rota de triagem."""
    texto_cliente: str
    coords: Optional[Tuple[float, float]] = None


class TriageResponse(BaseModel):
    """Resposta da rota de triagem."""
    case_id: str
    area: str
    subarea: str
    urgency_h: int
    summary_embedding: List[float]


class DetailedTriageAnalysis(BaseModel):
    """Análise detalhada de triagem com campos ricos do OpenAI."""
    classificacao: Dict[str, str]
    dados_extraidos: Dict[str, Any]
    analise_viabilidade: Dict[str, Any]
    urgencia: Dict[str, Any]
    aspectos_tecnicos: Dict[str, Any]
    recomendacoes: Dict[str, Any]


class CaseResponse(BaseModel):
    """Resposta após a criação de um caso."""
    case_id: str


class MatchRequest(BaseModel):
    """Payload para solicitar um match."""
    case_id: str
    exclude_ids: Optional[List[str]] = None  # IDs de advogados a serem excluídos
    k: int = 5
    preset: str = "balanced"
    area: Optional[str] = None      # Permite sobrepor a área do caso
    subarea: Optional[str] = None   # Permite sobrepor a subárea do caso
    radius_km: Optional[int] = None # Raio máximo de busca em km


class MatchFeatures(BaseModel):
    """Scores detalhados das features do match."""
    A: float
    S: float
    T: float
    G: float
    Q: float
    U: float
    R: float
    C: Optional[float] = 0.0


class MatchResult(BaseModel):
    """Informações de um advogado que deu match."""
    lawyer_id: str
    nome: str
    fair: float
    equity: float
    features: MatchFeatures
    breakdown: Optional[Dict[str, float]] = None
    weights_used: Optional[Dict[str, float]] = None
    preset_used: Optional[str] = None
    # Campos adicionais para o card no frontend
    avatar_url: Optional[str] = None
    is_available: bool = False
    primary_area: str
    rating: Optional[float] = None
    distance_km: Optional[float] = None


class MatchResponse(BaseModel):
    """Resposta da requisição de match."""
    case_id: str
    matches: List[MatchResult]


class ExplainRequest(BaseModel):
    """Payload para a rota de explicação."""
    case_id: str
    lawyer_ids: List[str]


class ExplainResponse(BaseModel):
    """Resposta da rota de explicação."""
    explanations: Dict[str, str]  # Dicionário de lawyer_id para explicação

# === MÓDULO OFFERS - Fases 4 & 5 ===


class Offer(BaseModel):
    """Modelo de uma oferta enviada para um advogado."""
    id: UUID
    case_id: UUID
    lawyer_id: UUID
    status: Literal["pending", "interested", "declined", "expired", "closed"]
    sent_at: datetime
    responded_at: Optional[datetime] = None
    expires_at: datetime
    fair_score: Optional[float] = None
    raw_score: Optional[float] = None
    equity_weight: Optional[float] = None
    last_offered_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime


class OfferStatusUpdate(BaseModel):
    """Payload para atualizar o status de uma oferta."""
    status: Literal["interested", "declined"]


class OfferCreate(BaseModel):
    """Payload para criar uma nova oferta."""
    case_id: UUID
    lawyer_id: UUID
    fair_score: float
    raw_score: float
    equity_weight: float
    last_offered_at: Optional[datetime] = None


class OfferResponse(BaseModel):
    """Resposta com informações da oferta."""
    id: UUID
    case_id: UUID
    lawyer_id: UUID
    status: str
    sent_at: datetime
    responded_at: Optional[datetime] = None
    expires_at: datetime
    fair_score: Optional[float] = None


class OffersListResponse(BaseModel):
    """Lista de ofertas para um caso."""
    case_id: UUID
    offers: List[Offer]
    total: int
    interested_count: int

# ============================================================================
# CONTRATOS
# ============================================================================


class FeeModel(BaseModel):
    """Modelo de honorários (simplificado)."""
    type: str
    percent: Optional[float] = None
    value: Optional[float] = None
    rate: Optional[float] = None


class ContractStatus(str, Enum):
    PENDING_SIGNATURE = "pending_signature"
    ACTIVE = "active"
    CANCELLED = "cancelled"


class Contract(BaseModel):
    id: UUID
    case_id: UUID
    lawyer_id: UUID
    client_id: UUID
    status: ContractStatus
    fee_model: Dict[str, Any]
    created_at: datetime
    signed_client: Optional[datetime] = None
    signed_lawyer: Optional[datetime] = None
    doc_url: Optional[str] = None
    updated_at: datetime
    interested_count: Optional[int] = None


class Explanation(BaseModel):
    lawyer_id: str
    raw_score: float
    features: MatchFeatures
    breakdown: Optional[Dict[str, float]] = None
