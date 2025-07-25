"""
Testes de integração para API de critérios premium.
Testa CRUD completo com banco de dados real.
"""

import pytest
from httpx import AsyncClient
from models.premium_criteria import PremiumCriteria


@pytest.mark.asyncio
async def test_list_premium_criteria_empty(client: AsyncClient):
    """
    Testa listagem de critérios quando não há nenhum no banco.
    """
    response = await client.get("/admin/premium-criteria/")
    
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_create_premium_criteria(client: AsyncClient, sample_premium_criteria_data):
    """
    Testa criação de um novo critério premium via API.
    """
    response = await client.post(
        "/admin/premium-criteria/", 
        json=sample_premium_criteria_data
    )
    
    assert response.status_code == 201
    data = response.json()
    
    # Verificar se os dados retornados estão corretos
    assert data["service_code"] == "tributario"
    assert data["subservice_code"] == "imposto_de_renda"
    assert data["name"] == "IR Premium > 100k"
    assert data["enabled"] is True
    assert data["min_valor_causa"] == 100000
    assert "id" in data
    assert "created_at" in data


@pytest.mark.asyncio
async def test_get_premium_criteria_by_id(client: AsyncClient, db_session, sample_premium_criteria_data):
    """
    Testa busca de critério específico por ID.
    """
    # Criar critério diretamente no banco
    criteria = PremiumCriteria(**sample_premium_criteria_data)
    db_session.add(criteria)
    await db_session.commit()
    await db_session.refresh(criteria)
    
    # Buscar via API
    response = await client.get(f"/admin/premium-criteria/{criteria.id}")
    
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == criteria.id
    assert data["name"] == "IR Premium > 100k"


@pytest.mark.asyncio
async def test_get_nonexistent_criteria_returns_404(client: AsyncClient):
    """
    Testa que buscar critério inexistente retorna 404.
    """
    response = await client.get("/admin/premium-criteria/99999")
    
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_update_premium_criteria(client: AsyncClient, db_session, sample_premium_criteria_data):
    """
    Testa atualização de critério existente.
    """
    # Criar critério inicial
    criteria = PremiumCriteria(**sample_premium_criteria_data)
    db_session.add(criteria)
    await db_session.commit()
    await db_session.refresh(criteria)
    
    # Dados para atualização
    update_data = {
        "name": "IR Premium Atualizado",
        "min_valor_causa": 200000,
        "enabled": False
    }
    
    # Atualizar via API
    response = await client.put(
        f"/admin/premium-criteria/{criteria.id}", 
        json=update_data
    )
    
    assert response.status_code == 200
    data = response.json()
    
    # Verificar se as alterações foram aplicadas
    assert data["name"] == "IR Premium Atualizado"
    assert data["min_valor_causa"] == 200000
    assert data["enabled"] is False
    
    # Campos não alterados devem permanecer iguais
    assert data["service_code"] == "tributario"
    assert data["subservice_code"] == "imposto_de_renda"


@pytest.mark.asyncio
async def test_update_nonexistent_criteria_returns_404(client: AsyncClient):
    """
    Testa que atualizar critério inexistente retorna 404.
    """
    update_data = {"name": "Teste"}
    
    response = await client.put("/admin/premium-criteria/99999", json=update_data)
    
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_premium_criteria(client: AsyncClient, db_session, sample_premium_criteria_data):
    """
    Testa exclusão de critério premium.
    """
    # Criar critério para deletar
    criteria = PremiumCriteria(**sample_premium_criteria_data)
    db_session.add(criteria)
    await db_session.commit()
    await db_session.refresh(criteria)
    
    # Deletar via API
    response = await client.delete(f"/admin/premium-criteria/{criteria.id}")
    
    assert response.status_code == 204
    
    # Verificar que foi realmente deletado
    get_response = await client.get(f"/admin/premium-criteria/{criteria.id}")
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_delete_nonexistent_criteria_returns_404(client: AsyncClient):
    """
    Testa que deletar critério inexistente retorna 404.
    """
    response = await client.delete("/admin/premium-criteria/99999")
    
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_list_multiple_criteria_ordered_by_id(client: AsyncClient, db_session):
    """
    Testa listagem de múltiplos critérios ordenados por ID.
    """
    # Criar múltiplos critérios
    criteria_list = [
        PremiumCriteria(
            service_code="tributario",
            subservice_code="irpf",
            name="IRPF Simples",
            enabled=True,
            min_valor_causa=50000
        ),
        PremiumCriteria(
            service_code="trabalhista", 
            subservice_code="rescisao",
            name="Rescisão Complexa",
            enabled=True,
            complexity_levels=["HIGH"]
        ),
        PremiumCriteria(
            service_code="civil",
            subservice_code="contratos",
            name="Contratos Premium",
            enabled=False,
            min_valor_causa=100000
        )
    ]
    
    for criteria in criteria_list:
        db_session.add(criteria)
    await db_session.commit()
    
    # Listar via API
    response = await client.get("/admin/premium-criteria/")
    
    assert response.status_code == 200
    data = response.json()
    
    assert len(data) == 3
    
    # Verificar que estão ordenados por ID
    ids = [item["id"] for item in data]
    assert ids == sorted(ids)
    
    # Verificar alguns campos específicos
    names = [item["name"] for item in data]
    assert "IRPF Simples" in names
    assert "Rescisão Complexa" in names
    assert "Contratos Premium" in names


@pytest.mark.asyncio
async def test_criteria_validation_errors(client: AsyncClient):
    """
    Testa validação de dados inválidos na criação de critérios.
    """
    # Dados inválidos - service_code obrigatório ausente
    invalid_data = {
        "name": "Critério Inválido",
        "enabled": True
        # service_code ausente
    }
    
    response = await client.post("/admin/premium-criteria/", json=invalid_data)
    
    # Deveria retornar erro de validação (422)
    assert response.status_code == 422 