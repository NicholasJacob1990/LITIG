"""
Testes para os modelos reais do backend
"""
import pytest
from datetime import datetime
from uuid import uuid4
from backend.models import (
    TriageRequest, TriageResponse, DetailedTriageAnalysis,
    CaseResponse, MatchRequest, MatchFeatures, MatchResult,
    MatchResponse, ExplainRequest, ExplainResponse,
    Offer, OfferStatusUpdate, OfferCreate, OfferResponse,
    OffersListResponse, FeeModel, ContractStatus, Contract,
    Explanation
)


def test_triage_request():
    """Testa o modelo TriageRequest"""
    request = TriageRequest(
        texto_cliente="Fui demitido sem justa causa",
        coords=(-23.5505, -46.6333)
    )
    assert request.texto_cliente == "Fui demitido sem justa causa"
    assert request.coords == (-23.5505, -46.6333)
    
    # Teste sem coordenadas
    request2 = TriageRequest(texto_cliente="Problema com contrato")
    assert request2.coords is None


def test_triage_response():
    """Testa o modelo TriageResponse"""
    response = TriageResponse(
        case_id="case123",
        area="trabalhista",
        subarea="rescisão",
        urgency_h=48,
        summary_embedding=[0.1, 0.2, 0.3]
    )
    assert response.case_id == "case123"
    assert response.area == "trabalhista"
    assert response.urgency_h == 48
    assert len(response.summary_embedding) == 3


def test_detailed_triage_analysis():
    """Testa o modelo DetailedTriageAnalysis"""
    analysis = DetailedTriageAnalysis(
        classificacao={"area": "trabalhista", "subarea": "rescisão"},
        dados_extraidos={"valor": 5000, "tempo_empresa": "2 anos"},
        analise_viabilidade={"viavel": True, "probabilidade": 0.8},
        urgencia={"nivel": "alta", "horas": 24},
        aspectos_tecnicos={"complexidade": "média"},
        recomendacoes={"acao": "procurar advogado imediatamente"}
    )
    assert analysis.classificacao["area"] == "trabalhista"
    assert analysis.dados_extraidos["valor"] == 5000
    assert analysis.analise_viabilidade["viavel"] is True


def test_match_features():
    """Testa o modelo MatchFeatures"""
    features = MatchFeatures(
        A=0.8,
        S=0.9,
        T=0.7,
        G=0.85,
        Q=0.95,
        U=0.6,
        R=0.88,
        C=0.75
    )
    assert features.A == 0.8
    assert features.S == 0.9
    assert features.C == 0.75
    
    # Teste com C opcional
    features2 = MatchFeatures(A=0.8, S=0.9, T=0.7, G=0.85, Q=0.95, U=0.6, R=0.88)
    assert features2.C == 0.0  # Valor padrão


def test_match_result():
    """Testa o modelo MatchResult"""
    features = MatchFeatures(A=0.8, S=0.9, T=0.7, G=0.85, Q=0.95, U=0.6, R=0.88)
    result = MatchResult(
        lawyer_id="lawyer123",
        nome="Dr. João Silva",
        fair=0.85,
        equity=0.9,
        features=features,
        primary_area="trabalhista",
        is_available=True,
        rating=4.5,
        distance_km=5.2
    )
    assert result.lawyer_id == "lawyer123"
    assert result.fair == 0.85
    assert result.is_available is True
    assert result.distance_km == 5.2


def test_match_response():
    """Testa o modelo MatchResponse"""
    features = MatchFeatures(A=0.8, S=0.9, T=0.7, G=0.85, Q=0.95, U=0.6, R=0.88)
    match1 = MatchResult(
        lawyer_id="lawyer1",
        nome="Dr. João",
        fair=0.85,
        equity=0.9,
        features=features,
        primary_area="trabalhista"
    )
    match2 = MatchResult(
        lawyer_id="lawyer2",
        nome="Dra. Maria",
        fair=0.82,
        equity=0.88,
        features=features,
        primary_area="trabalhista"
    )
    
    response = MatchResponse(
        case_id="case123",
        matches=[match1, match2]
    )
    assert response.case_id == "case123"
    assert len(response.matches) == 2
    assert response.matches[0].nome == "Dr. João"


def test_offer_model():
    """Testa o modelo Offer"""
    offer_id = uuid4()
    case_id = uuid4()
    lawyer_id = uuid4()
    now = datetime.now()
    
    offer = Offer(
        id=offer_id,
        case_id=case_id,
        lawyer_id=lawyer_id,
        status="pending",
        sent_at=now,
        expires_at=datetime(2024, 12, 31),
        fair_score=0.85,
        raw_score=0.9,
        equity_weight=0.8,
        created_at=now,
        updated_at=now
    )
    
    assert offer.id == offer_id
    assert offer.status == "pending"
    assert offer.fair_score == 0.85
    assert offer.responded_at is None


def test_offer_status_update():
    """Testa o modelo OfferStatusUpdate"""
    update = OfferStatusUpdate(status="interested")
    assert update.status == "interested"
    
    update2 = OfferStatusUpdate(status="declined")
    assert update2.status == "declined"


def test_contract_model():
    """Testa o modelo Contract"""
    contract_id = uuid4()
    case_id = uuid4()
    lawyer_id = uuid4()
    client_id = uuid4()
    now = datetime.now()
    
    contract = Contract(
        id=contract_id,
        case_id=case_id,
        lawyer_id=lawyer_id,
        client_id=client_id,
        status=ContractStatus.PENDING_SIGNATURE,
        fee_model={"type": "percentage", "value": 30},
        created_at=now,
        updated_at=now,
        interested_count=3
    )
    
    assert contract.id == contract_id
    assert contract.status == ContractStatus.PENDING_SIGNATURE
    assert contract.fee_model["value"] == 30
    assert contract.signed_client is None
    assert contract.signed_lawyer is None


def test_fee_model():
    """Testa o modelo FeeModel"""
    # Honorários por porcentagem
    fee1 = FeeModel(type="percentage", percent=30.0)
    assert fee1.type == "percentage"
    assert fee1.percent == 30.0
    
    # Honorários fixos
    fee2 = FeeModel(type="fixed", value=5000.0)
    assert fee2.type == "fixed"
    assert fee2.value == 5000.0
    
    # Honorários por hora
    fee3 = FeeModel(type="hourly", rate=250.0)
    assert fee3.type == "hourly"
    assert fee3.rate == 250.0


def test_explanation_model():
    """Testa o modelo Explanation"""
    features = MatchFeatures(A=0.8, S=0.9, T=0.7, G=0.85, Q=0.95, U=0.6, R=0.88)
    explanation = Explanation(
        lawyer_id="lawyer123",
        raw_score=0.87,
        features=features,
        breakdown={"expertise": 0.9, "location": 0.8}
    )
    
    assert explanation.lawyer_id == "lawyer123"
    assert explanation.raw_score == 0.87
    assert explanation.features.A == 0.8
    assert explanation.breakdown["expertise"] == 0.9 