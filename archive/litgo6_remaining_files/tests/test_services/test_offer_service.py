"""
Testes para o OfferService (backend/services/offer_service.py)
"""
import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from datetime import datetime, timedelta
from uuid import uuid4

from backend.services import offer_service
from backend.models import OfferStatusUpdate
from backend.algoritmo_match import Lawyer, Case, KPI

@pytest.fixture
def mock_supabase_client():
    """Fixture para mockar o cliente Supabase retornado por get_supabase_client."""
    mock = MagicMock()
    mock.table.return_value.upsert.return_value.execute.return_value.data = [
        {"id": "offer-1"}, {"id": "offer-2"}
    ]
    return mock

@pytest.mark.asyncio
async def test_create_offers_from_ranking_success(mock_supabase_client):
    """
    Testa a criação de ofertas a partir de um ranking de advogados.
    """
    case = Case(id=str(uuid4()), area="Civil", subarea="Familia", urgency_h=24, coords=(0,0))
    kpi_data = KPI(success_rate=0.8, cases_30d=10, capacidade_mensal=20, avaliacao_media=4.5, tempo_resposta_h=12)
    ranking = [
        Lawyer(id=str(uuid4()), nome="Advogado 1", scores={"fair": 0.9, "raw": 0.8, "equity": 0.1}, tags_expertise=[], geo_latlon=(0,0), curriculo_json={}, kpi=kpi_data),
        Lawyer(id=str(uuid4()), nome="Advogado 2", scores={"fair": 0.8, "raw": 0.7, "equity": 0.2}, tags_expertise=[], geo_latlon=(0,0), curriculo_json={}, kpi=kpi_data),
    ]
    
    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        offer_ids = await offer_service.create_offers_from_ranking(case, ranking)
        
        assert len(offer_ids) == 2
        assert offer_ids == ["offer-1", "offer-2"]
        
        # Verifica se o upsert foi chamado com os dados corretos
        upsert_call = mock_supabase_client.table("offers").upsert.call_args
        assert len(upsert_call.args[0]) == 2
        assert upsert_call.args[0][0]["case_id"] == str(case.id)
        assert upsert_call.args[0][1]["lawyer_id"] == str(ranking[1].id)

@pytest.mark.asyncio
async def test_create_offers_from_ranking_empty(mock_supabase_client):
    """
    Testa a função com um ranking vazio. Não deve criar ofertas.
    """
    case = Case(id=str(uuid4()), area="Civil", subarea="Familia", urgency_h=24, coords=(0,0))
    
    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        offer_ids = await offer_service.create_offers_from_ranking(case, [])
        
        assert offer_ids == []
        mock_supabase_client.table("offers").upsert.assert_not_called()

def create_mock_offer(offer_id, case_id, lawyer_id, status):
    """Helper para criar um dicionário de oferta completo para os mocks."""
    now = datetime.utcnow()
    return {
        "id": str(offer_id),
        "case_id": str(case_id),
        "lawyer_id": str(lawyer_id),
        "status": status,
        "sent_at": now.isoformat(),
        "responded_at": None,
        "expires_at": (now + timedelta(hours=24)).isoformat(),
        "fair_score": 0.8,
        "raw_score": 0.7,
        "equity_weight": 0.1,
        "last_offered_at": None,
        "created_at": now.isoformat(),
        "updated_at": now.isoformat()
    }

@pytest.mark.asyncio
async def test_update_offer_status_success(mock_supabase_client):
    offer_id = uuid4()
    lawyer_id = uuid4()
    case_id = uuid4()
    status_update = OfferStatusUpdate(status="interested")
    
    existing_offer_data = create_mock_offer(offer_id, case_id, lawyer_id, "pending")
    existing_offer_data["case"] = {"id": str(case_id)}
    existing_offer_data["lawyer"] = {"id": str(lawyer_id)}
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = existing_offer_data
    
    updated_offer_data = {**existing_offer_data, "status": "interested"}
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.single.return_value.execute.return_value.data = updated_offer_data

    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        result = await offer_service.update_offer_status(offer_id, status_update, lawyer_id)
        
        assert result is not None
        assert result.status == "interested"
        update_call = mock_supabase_client.table("offers").update.call_args
        assert update_call.args[0]["status"] == "interested"

@pytest.mark.asyncio
async def test_update_offer_status_not_found(mock_supabase_client):
    """
    Testa a atualização de uma oferta que não é encontrada ou não pertence ao advogado.
    """
    # Mock para não encontrar a oferta
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = None

    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        result = await offer_service.update_offer_status(uuid4(), OfferStatusUpdate(status="interested"), uuid4())
        assert result is None

@pytest.mark.asyncio
async def test_get_offers_by_case_success(mock_supabase_client):
    case_id = uuid4()
    client_id = uuid4()
    
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = {"id": str(case_id)}
    
    offer1 = create_mock_offer(uuid4(), case_id, uuid4(), "interested")
    offer2 = create_mock_offer(uuid4(), case_id, uuid4(), "pending")
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [offer1, offer2]

    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        response = await offer_service.get_offers_by_case(case_id, client_id)
        
        assert response.total == 2
        assert response.interested_count == 1
        assert response.offers[0].status == "interested"

@pytest.mark.asyncio
async def test_close_other_offers_success(mock_supabase_client):
    """
    Testa o fechamento de outras ofertas quando uma é aceita.
    """
    case_id = uuid4()
    accepted_offer_id = uuid4()

    # Mock da resposta do update
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.neq.return_value.in_.return_value.execute.return_value.data = [
        {"id": "offer-closed-1"}, {"id": "offer-closed-2"}
    ]

    with patch('backend.services.offer_service.get_supabase_client', return_value=mock_supabase_client):
        closed_count = await offer_service.close_other_offers(case_id, accepted_offer_id)
        
        assert closed_count == 2
        update_call = mock_supabase_client.table("offers").update.call_args
        assert update_call.args[0]["status"] == "closed" 