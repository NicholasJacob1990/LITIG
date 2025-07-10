# tests/test_offers.py
import pytest
from unittest.mock import patch, AsyncMock
from uuid import uuid4
from datetime import datetime, timedelta

from backend.services.offer_service import (
    create_offers_from_ranking, update_offer_status, 
    get_offers_by_case, expire_pending_offers
)
from backend.models import OfferStatusUpdate
from backend.algoritmo_match import Case, Lawyer, KPI


@pytest.fixture
def mock_case():
    """Fixture para um caso de teste."""
    return Case(
        id=str(uuid4()),
        area="Trabalhista",
        subarea="Justa Causa",
        urgency_h=48,
        coords=(-23.55, -46.63),
    )


@pytest.fixture
def mock_lawyers():
    """Fixture para advogados de teste."""
    lawyers = []
    for i in range(3):
        lawyer = Lawyer(
            id=str(uuid4()),
            nome=f"Advogado {i+1}",
            tags_expertise=["Trabalhista"],
            geo_latlon=(-23.5 + i*0.01, -46.6 + i*0.01),
            curriculo_json={"anos_experiencia": 10},
            kpi=KPI(
                success_rate=0.9,
                cases_30d=5,
                capacidade_mensal=20,
                avaliacao_media=4.5,
                tempo_resposta_h=12
            ),
            scores={
                "fair": 0.8 + i*0.05,
                "raw": 0.7 + i*0.05,
                "equity": 0.9,
                "features": {}
            }
        )
        lawyers.append(lawyer)
    return lawyers


@pytest.mark.asyncio
async def test_create_offers_from_ranking(mock_case, mock_lawyers):
    """
    Testa a criação de ofertas a partir de um ranking.
    """
    mock_supabase_response = {
        "data": [
            {"id": str(uuid4())} for _ in mock_lawyers
        ]
    }
    
    with patch('backend.services.offer_service.get_supabase_client') as mock_get_supa:
        mock_supa_client = mock_get_supa.return_value
        mock_table = mock_supa_client.table.return_value
        mock_upsert = mock_table.upsert.return_value
        mock_execute = mock_upsert.execute.return_value
        mock_execute.data = mock_supabase_response["data"]
        
        offer_ids = await create_offers_from_ranking(mock_case, mock_lawyers)
        
        # Verifica se as ofertas foram criadas
        assert len(offer_ids) == len(mock_lawyers)
        mock_table.upsert.assert_called_once()


@pytest.mark.asyncio
async def test_create_offers_empty_ranking(mock_case):
    """
    Testa a criação de ofertas com ranking vazio.
    """
    offer_ids = await create_offers_from_ranking(mock_case, [])
    assert offer_ids == []


@pytest.mark.asyncio
async def test_expire_pending_offers():
    """
    Testa a expiração de ofertas pendentes.
    """
    with patch('backend.services.offer_service.get_supabase_client') as mock_get_supa:
        mock_supa_client = mock_get_supa.return_value
        mock_rpc = mock_supa_client.rpc.return_value
        mock_execute = mock_rpc.execute.return_value
        mock_execute.data = 5  # 5 ofertas expiradas
        
        expired_count = await expire_pending_offers()
        
        assert expired_count == 5
        mock_supa_client.rpc.assert_called_once_with("expire_pending_offers")
