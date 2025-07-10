"""
Testes básicos para os modelos do LITGO5
"""
import pytest
from datetime import datetime
from uuid import uuid4
from backend.models import (
    TriageRequest, TriageResponse, MatchRequest, MatchResponse,
    MatchResult, MatchFeatures, Contract, ContractStatus,
    ExplainRequest, ExplainResponse, OfferCreate, OfferStatusUpdate
)


def test_triage_request():
    """Testa modelo de request para triagem"""
    request = TriageRequest(
        texto_cliente="Texto para triagem",
        coords=(-23.5505, -46.6333)
    )
    
    assert request.texto_cliente == "Texto para triagem"
    assert request.coords == (-23.5505, -46.6333)


def test_triage_response():
    """Testa modelo de response para triagem"""
    response = TriageResponse(
        case_id="case-123",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        summary_embedding=[0.1, 0.2, 0.3]
    )
    
    assert response.case_id == "case-123"
    assert response.area == "Trabalhista"
    assert response.urgency_h == 48
    assert len(response.summary_embedding) == 3


def test_match_request():
    """Testa modelo de request para matching"""
    request = MatchRequest(
        case_id="case-123",
        k=5,
        preset="balanced"
    )
    
    assert request.case_id == "case-123"
    assert request.k == 5
    assert request.preset == "balanced"


def test_match_features():
    """Testa modelo de features do match"""
    features = MatchFeatures(
        A=0.8,
        S=0.7,
        T=0.9,
        G=0.6,
        Q=0.85,
        U=0.75,
        R=0.9,
        C=0.8
    )
    
    assert features.A == 0.8
    assert features.S == 0.7
    assert features.C == 0.8


def test_match_result():
    """Testa modelo de resultado do match"""
    features = MatchFeatures(A=0.8, S=0.7, T=0.9, G=0.6, Q=0.85, U=0.75, R=0.9)
    
    result = MatchResult(
        lawyer_id="lawyer-123",
        nome="Dr. João Silva",
        fair=0.85,
        equity=0.3,
        features=features,
        primary_area="Trabalhista"
    )
    
    assert result.lawyer_id == "lawyer-123"
    assert result.nome == "Dr. João Silva"
    assert result.fair == 0.85
    assert result.primary_area == "Trabalhista"


def test_match_response():
    """Testa modelo de response do match"""
    features = MatchFeatures(A=0.8, S=0.7, T=0.9, G=0.6, Q=0.85, U=0.75, R=0.9)
    match = MatchResult(
        lawyer_id="lawyer-123",
        nome="Dr. João Silva",
        fair=0.85,
        equity=0.3,
        features=features,
        primary_area="Trabalhista"
    )
    
    response = MatchResponse(
        case_id="case-123",
        matches=[match]
    )
    
    assert response.case_id == "case-123"
    assert len(response.matches) == 1
    assert response.matches[0].lawyer_id == "lawyer-123"


def test_explain_request():
    """Testa modelo de request para explicação"""
    request = ExplainRequest(
        case_id="case-123",
        lawyer_ids=["lawyer-1", "lawyer-2"]
    )
    
    assert request.case_id == "case-123"
    assert len(request.lawyer_ids) == 2


def test_explain_response():
    """Testa modelo de response para explicação"""
    response = ExplainResponse(
        explanations={
            "lawyer-1": "Explicação para lawyer 1",
            "lawyer-2": "Explicação para lawyer 2"
        }
    )
    
    assert len(response.explanations) == 2
    assert "lawyer-1" in response.explanations


def test_offer_create():
    """Testa modelo para criação de oferta"""
    offer_create = OfferCreate(
        case_id=uuid4(),
        lawyer_id=uuid4(),
        fair_score=0.85,
        raw_score=0.90,
        equity_weight=0.3
    )
    
    assert offer_create.fair_score == 0.85
    assert offer_create.raw_score == 0.90
    assert offer_create.equity_weight == 0.3


def test_offer_status_update():
    """Testa modelo para atualização de status de oferta"""
    update = OfferStatusUpdate(status="interested")
    
    assert update.status == "interested"


def test_contract_status_enum():
    """Testa enum de status de contrato"""
    assert ContractStatus.PENDING_SIGNATURE == "pending_signature"
    assert ContractStatus.ACTIVE == "active"
    assert ContractStatus.CANCELLED == "cancelled"


def test_contract_model():
    """Testa modelo de contrato"""
    contract = Contract(
        id=uuid4(),
        case_id=uuid4(),
        lawyer_id=uuid4(),
        client_id=uuid4(),
        status=ContractStatus.PENDING_SIGNATURE,
        fee_model={"type": "percentage", "percent": 30},
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    
    assert contract.status == ContractStatus.PENDING_SIGNATURE
    assert contract.fee_model["type"] == "percentage"
    assert isinstance(contract.created_at, datetime) 