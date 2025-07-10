"""
Testes para as rotas de Casos (backend/routes/cases.py)
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi.testclient import TestClient

from backend.main import app

# Helper para criar um TestClient com mocks específicos para este módulo
def create_test_client_with_auth_override():
    from backend.auth import get_current_user
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-user-id"}
    return TestClient(app)

@pytest.fixture
def mock_case_service():
    """Mock para o CaseService."""
    service = MagicMock()
    service.get_user_cases = AsyncMock(return_value=[{"id": "case-1"}, {"id": "case-2"}])
    service.get_case_statistics = AsyncMock(return_value={"total": 5})
    service.update_case_status = AsyncMock(return_value={"id": "case-1", "status": "new_status"})
    service._enrich_case_data = AsyncMock(return_value={"id": "case-123", "enriched": True})
    return service

@pytest.fixture
def mock_supabase():
    """Mock para o Supabase client."""
    mock = MagicMock()
    execute_mock = MagicMock()
    mock.table.return_value.select.return_value.eq.return_value.single.return_value.execute = execute_mock
    return mock, execute_mock


# === Testes ===

def test_get_my_cases_success(mock_case_service):
    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.create_case_service', return_value=mock_case_service):
        response = client.get("/api/cases/my-cases")
        assert response.status_code == 200
        assert len(response.json()) == 2
    app.dependency_overrides = {}

def test_get_case_statistics_success(mock_case_service):
    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.create_case_service', return_value=mock_case_service):
        response = client.get("/api/cases/statistics")
        assert response.status_code == 200
        assert response.json() == {"total": 5}
    app.dependency_overrides = {}

def test_update_case_status_success(mock_case_service):
    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.create_case_service', return_value=mock_case_service):
        response = client.patch("/api/cases/case-1/status?new_status=new_status")
        assert response.status_code == 200
        assert response.json()["status"] == "new_status"
    app.dependency_overrides = {}

def test_get_case_details_success(mock_case_service, mock_supabase):
    supabase_mock, execute_mock = mock_supabase
    execute_mock.return_value.data = {"id": "case-123", "client_id": "test-user-id"}
    
    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.get_supabase_client', return_value=supabase_mock):
        with patch('backend.routes.cases.create_case_service', return_value=mock_case_service):
            response = client.get("/api/cases/case-123")
    
    assert response.status_code == 200
    assert response.json()["enriched"] is True
    app.dependency_overrides = {}

def test_get_case_details_not_found(mock_supabase):
    supabase_mock, execute_mock = mock_supabase
    execute_mock.return_value.data = None
    
    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.get_supabase_client', return_value=supabase_mock):
        response = client.get("/api/cases/not-found")
    
    assert response.status_code == 404
    app.dependency_overrides = {}

def test_get_case_details_forbidden(mock_supabase):
    supabase_mock, execute_mock = mock_supabase
    execute_mock.return_value.data = {"id": "case-456", "client_id": "another-user"}

    client = create_test_client_with_auth_override()
    with patch('backend.routes.cases.get_supabase_client', return_value=supabase_mock):
        response = client.get("/api/cases/case-456")

    assert response.status_code == 403
    app.dependency_overrides = {} 