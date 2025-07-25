"""
Models do backend LITIG-1.
Classes Pydantic para validação de dados das APIs.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# Importar o modelo SQLAlchemy
from .premium_criteria import PremiumCriteria

# ===== ENUMS =====

class CaseStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class ContractStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    COMPLETED = "completed"
    TERMINATED = "terminated"

class FeeModel(str, Enum):
    HOURLY = "hourly"
    FIXED = "fixed"
    CONTINGENCY = "contingency"
    HYBRID = "hybrid"

# ===== CASE MODELS =====

class Case(BaseModel):
    id: Optional[str] = None
    title: str
    description: str
    case_type: str
    status: CaseStatus = CaseStatus.PENDING
    client_id: str
    lawyer_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class CaseUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[CaseStatus] = None
    lawyer_id: Optional[str] = None

# ===== CONTRACT MODELS =====

class Contract(BaseModel):
    id: Optional[str] = None
    case_id: str
    client_id: str
    lawyer_id: str
    status: ContractStatus = ContractStatus.DRAFT
    fee_model: FeeModel
    amount: Optional[float] = None
    terms: str
    created_at: Optional[datetime] = None

# ===== REQUEST/RESPONSE MODELS =====

class TriageRequest(BaseModel):
    case_description: str
    case_type: Optional[str] = None
    urgency: Optional[str] = "medium"
    location: Optional[str] = None
    budget_range: Optional[str] = None

class TriageResponse(BaseModel):
    success: bool
    case_id: str
    recommended_lawyers: List[Dict[str, Any]]
    analysis: Dict[str, Any]
    confidence_score: float

class MatchRequest(BaseModel):
    case_id: str
    requirements: Dict[str, Any]
    preferences: Optional[Dict[str, Any]] = None
    max_results: int = Field(default=10, ge=1, le=50)

class MatchResponse(BaseModel):
    success: bool
    matches: List[Dict[str, Any]]
    total_count: int
    algorithm_version: str

class SimpleMatchmakingRequest(BaseModel):
    case_description: str
    case_type: str
    budget: Optional[float] = None
    urgency: str = "medium"
    location: Optional[str] = None

class ExplainRequest(BaseModel):
    case_id: str
    lawyer_id: str
    explanation_type: str = "match"

class ExplainResponse(BaseModel):
    success: bool
    explanation: str
    factors: List[Dict[str, Any]]
    confidence_score: float

class GetCaseExplanationRequest(BaseModel):
    case_id: str
    lawyer_id: str
    include_alternatives: bool = False

# ===== INTELLIGENT TRIAGE MODELS =====

class StartIntelligentTriageRequest(BaseModel):
    initial_message: str
    case_type: Optional[str] = None
    user_metadata: Optional[Dict[str, Any]] = None

class StartIntelligentTriageResponse(BaseModel):
    success: bool
    session_id: str
    ai_response: str
    next_questions: List[str]
    estimated_complexity: str

class ContinueConversationRequest(BaseModel):
    session_id: str
    user_message: str
    additional_context: Optional[Dict[str, Any]] = None

class ContinueConversationResponse(BaseModel):
    success: bool
    ai_response: str
    session_complete: bool
    next_questions: Optional[List[str]] = None
    triage_result: Optional[Dict[str, Any]] = None

class OrchestrationStatusResponse(BaseModel):
    success: bool
    status: str
    progress_percentage: float
    current_step: str
    estimated_completion: Optional[datetime] = None

# ===== OFFER MODELS =====

class OfferStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"

class Offer(BaseModel):
    id: Optional[str] = None
    case_id: str
    lawyer_id: str
    client_id: str
    amount: float
    description: str
    status: OfferStatus = OfferStatus.PENDING
    expires_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

class OfferCreate(BaseModel):
    case_id: str
    lawyer_id: str
    amount: float
    description: str
    expires_in_hours: int = Field(default=48, ge=1, le=168)

class OfferStatusUpdate(BaseModel):
    status: OfferStatus
    rejection_reason: Optional[str] = None

class OffersListResponse(BaseModel):
    success: bool
    offers: List[Offer]
    total_count: int
    page: int
    limit: int

# ===== TASK MODELS =====

class TaskResponse(BaseModel):
    success: bool
    task_id: str
    status: str
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    progress: float
    created_at: datetime
    updated_at: datetime

class TaskResultResponse(BaseModel):
    task_id: str
    result: Dict[str, Any]
    completed_at: datetime

class TaskCleanupResponse(BaseModel):
    success: bool
    cleaned_tasks: int

# ===== EXPORTS =====

__all__ = [
    # Enums
    "CaseStatus", "ContractStatus", "FeeModel", "OfferStatus",
    # Case Models
    "Case", "CaseUpdate", 
    # Contract Models
    "Contract",
    # Offer Models
    "Offer", "OfferCreate", "OfferStatusUpdate", "OffersListResponse",
    # Request/Response Models
    "TriageRequest", "TriageResponse",
    "MatchRequest", "MatchResponse",
    "SimpleMatchmakingRequest",
    "ExplainRequest", "ExplainResponse",
    "GetCaseExplanationRequest",
    # Intelligent Triage Models
    "StartIntelligentTriageRequest", "StartIntelligentTriageResponse",
    "ContinueConversationRequest", "ContinueConversationResponse",
    "OrchestrationStatusResponse",
    # Task Models
    "TaskResponse", "TaskStatusResponse", "TaskResultResponse", "TaskCleanupResponse",
    # Premium Models
    "PremiumCriteria"
] 