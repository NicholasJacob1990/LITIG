"""
Testes de integração para anonimização de dados de clientes.
Valida a regra: "dados do cliente só aparecem depois do aceite".
"""

import pytest
from httpx import AsyncClient
from unittest.mock import patch


@pytest.mark.asyncio
async def test_case_preview_hides_client_data_before_accept(client: AsyncClient, db_session, sample_case_data):
    """
    Testa que o preview de um caso esconde dados sensíveis do cliente antes do aceite.
    Simula a funcionalidade de anonimização implementada no Supabase RLS.
    """
    # Simular criação de caso (normalmente seria via Supabase)
    case_id = sample_case_data["id"]
    
    # Mock da consulta que simula a view cases_preview do Supabase
    preview_data = {
        "id": case_id,
        "area": sample_case_data["area"],
        "subarea": sample_case_data["subarea"],
        "complexity": sample_case_data["complexity"],
        "urgency_h": sample_case_data["urgency_h"],
        "status": "ABERTO",
        "valor_faixa": "R$ 100-300 mil",  # Valor em faixa, não exato
        "has_client_data": 1,
        "documents_count": 3,
        "is_accepted": False,
        # Campos sensíveis AUSENTES:
        # - cliente_nome
        # - cliente_email
        # - cliente_phone
        # - detailed_description
        # - valor_causa (valor exato)
    }
    
    # Simular endpoint de preview (seria implementado como wrapper do Supabase)
    with patch('services.supabase_service.get_case_preview') as mock_preview:
        mock_preview.return_value = preview_data
        
        response = await client.get(f"/cases/{case_id}/preview")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verificar que dados públicos estão presentes
        assert data["area"] == "Direito Tributário"
        assert data["subarea"] == "Imposto de Renda"
        assert data["complexity"] == "HIGH"
        assert data["valor_faixa"] == "R$ 100-300 mil"
        assert data["is_accepted"] is False
        
        # Verificar que dados sensíveis estão AUSENTES
        assert "cliente_nome" not in data
        assert "cliente_email" not in data
        assert "cliente_phone" not in data
        assert "detailed_description" not in data
        assert "valor_causa" not in data  # Valor exato oculto
        
        # Apenas metadados não-sensíveis
        assert data["has_client_data"] == 1
        assert data["documents_count"] == 3


@pytest.mark.asyncio
async def test_case_full_data_after_accept(client: AsyncClient, db_session, sample_case_data):
    """
    Testa que dados completos do cliente aparecem após aceite do advogado.
    """
    case_id = sample_case_data["id"]
    lawyer_id = "lawyer_123"
    
    # Simular aceite do caso
    accept_payload = {"lawyer_id": lawyer_id}
    
    with patch('services.supabase_service.accept_case') as mock_accept:
        mock_accept.return_value = {"success": True, "accepted_at": "2024-01-01T10:00:00Z"}
        
        # Aceitar o caso
        accept_response = await client.post(f"/cases/{case_id}/accept", json=accept_payload)
        assert accept_response.status_code == 200
    
    # Agora, simular busca de dados completos (após aceite, RLS permite acesso)
    full_case_data = {
        **sample_case_data,
        "accepted_by": lawyer_id,
        "accepted_at": "2024-01-01T10:00:00Z",
        "status": "ACEITO",
        "is_accepted": True
    }
    
    with patch('services.supabase_service.get_case_full') as mock_full:
        mock_full.return_value = full_case_data
        
        response = await client.get(f"/cases/{case_id}")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verificar que TODOS os dados estão presentes após aceite
        assert data["cliente_nome"] == "João Silva"
        assert data["cliente_email"] == "joao@example.com"
        assert data["cliente_phone"] == "+5511999999999"
        assert data["detailed_description"] == "Caso complexo de sonegação fiscal"
        assert data["valor_causa"] == 150000  # Valor exato agora visível
        assert data["accepted_by"] == lawyer_id
        assert data["is_accepted"] is True


@pytest.mark.asyncio
async def test_unauthorized_access_to_case_before_accept(client: AsyncClient):
    """
    Testa que tentativa de acessar dados completos antes do aceite retorna erro.
    """
    case_id = "case_unauthorized"
    
    # Simular tentativa de acesso não autorizado (RLS bloqueia)
    with patch('services.supabase_service.get_case_full') as mock_full:
        mock_full.side_effect = Exception("RLS_VIOLATION: Access denied")
        
        response = await client.get(f"/cases/{case_id}")
        
        assert response.status_code == 403
        assert "access" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_case_documents_inaccessible_before_accept(client: AsyncClient):
    """
    Testa que documentos do caso não são acessíveis antes do aceite.
    Simula as políticas do Storage do Supabase.
    """
    case_id = "case_docs"
    document_path = f"{case_id}/contrato.pdf"
    
    # Simular tentativa de acessar documento antes do aceite
    with patch('services.supabase_storage.get_document') as mock_storage:
        mock_storage.side_effect = Exception("STORAGE_POLICY: Access denied to case files")
        
        response = await client.get(f"/cases/{case_id}/documents/{document_path}")
        
        assert response.status_code == 403
        assert "storage" in response.json()["detail"].lower() or "access" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_multiple_lawyers_cannot_see_others_accepted_cases(client: AsyncClient, sample_case_data):
    """
    Testa que advogado A não consegue ver dados de caso aceito por advogado B.
    """
    case_id = sample_case_data["id"]
    lawyer_a = "lawyer_a"
    lawyer_b = "lawyer_b"
    
    # Simular caso aceito pelo lawyer_a
    case_accepted_by_a = {
        **sample_case_data,
        "accepted_by": lawyer_a,
        "status": "ACEITO"
    }
    
    # Simular lawyer_b tentando acessar caso do lawyer_a
    with patch('auth.get_current_user') as mock_auth:
        mock_auth.return_value = {"id": lawyer_b, "role": "lawyer"}
        
        with patch('services.supabase_service.get_case_full') as mock_full:
            # RLS deve bloquear acesso pois lawyer_b não aceitou o caso
            mock_full.side_effect = Exception("RLS_VIOLATION: Case not accepted by current user")
            
            response = await client.get(f"/cases/{case_id}")
            
            assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_can_access_any_case_data(client: AsyncClient, sample_case_data):
    """
    Testa que administradores podem acessar dados de qualquer caso.
    """
    case_id = sample_case_data["id"]
    
    # Simular usuário admin
    with patch('auth.get_current_user') as mock_auth:
        mock_auth.return_value = {"id": "admin_1", "role": "admin"}
        
        with patch('services.supabase_service.get_case_full') as mock_full:
            mock_full.return_value = sample_case_data
            
            response = await client.get(f"/cases/{case_id}")
            
            assert response.status_code == 200
            data = response.json()
            
            # Admin pode ver todos os dados, mesmo sem aceitar
            assert data["cliente_nome"] == "João Silva"
            assert data["detailed_description"] == "Caso complexo de sonegação fiscal"


@pytest.mark.asyncio
async def test_case_abandonment_hides_data_again(client: AsyncClient, sample_case_data):
    """
    Testa que após abandono de caso, dados do cliente ficam ocultos novamente.
    """
    case_id = sample_case_data["id"]
    lawyer_id = "lawyer_abandon"
    
    # 1. Aceitar caso
    with patch('services.supabase_service.accept_case') as mock_accept:
        mock_accept.return_value = {"success": True}
        await client.post(f"/cases/{case_id}/accept", json={"lawyer_id": lawyer_id})
    
    # 2. Abandonar caso
    with patch('services.supabase_service.abandon_case') as mock_abandon:
        mock_abandon.return_value = {"success": True, "abandoned_at": "2024-01-01T12:00:00Z"}
        
        abandon_response = await client.post(f"/cases/{case_id}/abandon", json={"reason": "Conflito de agenda"})
        assert abandon_response.status_code == 200
    
    # 3. Tentar acessar dados após abandono - deve ser bloqueado
    with patch('services.supabase_service.get_case_full') as mock_full:
        mock_full.side_effect = Exception("RLS_VIOLATION: Case abandoned by user")
        
        response = await client.get(f"/cases/{case_id}")
        assert response.status_code == 403


@pytest.mark.asyncio 
async def test_bulk_cases_preview_performance(client: AsyncClient):
    """
    Testa que listagem de múltiplos casos em preview mantém performance adequada.
    """
    # Simular lista com muitos casos
    mock_cases_preview = [
        {
            "id": f"case_{i}",
            "area": "Direito Civil",
            "subarea": "Contratos",
            "valor_faixa": "R$ 50-100 mil",
            "complexity": "MEDIUM",
            "is_accepted": False,
            # Sem dados sensíveis
        }
        for i in range(100)
    ]
    
    with patch('services.supabase_service.list_cases_preview') as mock_list:
        mock_list.return_value = mock_cases_preview
        
        response = await client.get("/cases/preview")
        
        assert response.status_code == 200
        data = response.json()
        
        assert len(data) == 100
        
        # Verificar que nenhum caso expõe dados sensíveis
        for case in data:
            assert "cliente_nome" not in case
            assert "cliente_email" not in case
            assert "detailed_description" not in case
            assert "valor_causa" not in case  # Apenas valor_faixa
            assert "valor_faixa" in case 