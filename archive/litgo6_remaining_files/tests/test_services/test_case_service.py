"""
Testes para o CaseService (backend/services/case_service.py)
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from backend.services.case_service import CaseService, create_case_service

@pytest.fixture
def mock_supabase_client():
    """Fixture para mockar o cliente Supabase."""
    mock = MagicMock()
    # Configuração genérica para chamadas encadeadas
    mock.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {}
    mock.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
    return mock

@pytest.fixture
def case_service(mock_supabase_client):
    """Fixture para criar uma instância do CaseService com um cliente mockado."""
    return CaseService(mock_supabase_client)

@pytest.mark.asyncio
async def test_get_user_cases_as_client_success(case_service: CaseService, mock_supabase_client: MagicMock):
    """
    Testa o cenário de sucesso para buscar casos de um usuário (cliente).
    """
    user_id = "client-user-id"
    # Mock da resposta do perfil
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
        "id": user_id, "role": "client"
    }
    # Mock da resposta dos casos
    cases_data = [
        {"id": "case-1", "client_id": user_id, "created_at": "2023-01-01T12:00:00Z"},
        {"id": "case-2", "client_id": user_id, "created_at": "2023-01-02T12:00:00Z"},
    ]
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = cases_data
    
    # Mock para a função de enriquecimento para evitar complexidade
    with patch.object(case_service, '_enrich_case_data', new_callable=AsyncMock) as mock_enrich:
        mock_enrich.side_effect = lambda case, role: {**case, "enriched": True}
        
        # Chama a função a ser testada
        result = await case_service.get_user_cases(user_id)
        
        # Asserções
        assert len(result) == 2
        assert result[0]['id'] == 'case-2' # Verifica a ordenação
        assert result[1]['id'] == 'case-1'
        assert mock_enrich.call_count == 2
        
        # Verifica se tentou buscar o perfil do usuário
        mock_supabase_client.table("profiles").select("role").eq("id", user_id).single.return_value.execute.assert_called_once()
        # Verifica se tentou buscar os casos do cliente
        mock_supabase_client.table("cases").select("*").eq("client_id", user_id).execute.assert_called_once() 

@pytest.mark.asyncio
async def test_get_user_cases_cache_hit(case_service: CaseService):
    """
    Testa se o serviço retorna dados do cache quando disponíveis.
    """
    user_id = "cached-user-id"
    cache_key = f"user_cases:{user_id}"
    cached_data = [{"id": "case-cached", "enriched": True}]
    
    # Mock do cache_service para simular um cache hit
    with patch('backend.services.case_service.simple_cache_service', new_callable=MagicMock) as mock_cache:
        # Usar AsyncMock para o método que será awaited
        mock_cache.get = AsyncMock(return_value=cached_data)
        mock_cache._generate_key.return_value = cache_key
        
        result = await case_service.get_user_cases(user_id)
        
        # Asserções
        mock_cache.get.assert_called_once_with(cache_key)
        assert result == cached_data
        case_service.supabase.table.assert_not_called()

@pytest.mark.asyncio
async def test_get_user_cases_no_role(case_service: CaseService, mock_supabase_client: MagicMock):
    """
    Testa o comportamento quando o usuário não tem uma role definida.
    Deve retornar uma lista vazia e não buscar casos.
    """
    user_id = "no-role-user"
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {"id": user_id}
    
    result = await case_service.get_user_cases(user_id)
    
    assert result == []
    # A chamada para 'profiles' é esperada, mas 'cases' não.
    mock_supabase_client.table.assert_called_with("profiles")
    assert mock_supabase_client.table.call_count == 1

def test_calculate_case_progress(case_service: CaseService):
    """
    Testa a lógica de cálculo de progresso do caso para diferentes status.
    """
    assert case_service._calculate_case_progress({"status": "triagem"}) == 10
    assert case_service._calculate_case_progress({"status": "matching"}) == 30
    assert case_service._calculate_case_progress({"status": "contract_signed"}) == 70
    assert case_service._calculate_case_progress({"status": "completed"}) == 100
    assert case_service._calculate_case_progress({"status": "cancelled"}) == 0
    # Teste com ajuste
    assert case_service._calculate_case_progress({"status": "triagem", "lawyer_id": "123"}) == 30
    assert case_service._calculate_case_progress({"status": "matching", "contract_id": "456"}) == 60

@pytest.mark.parametrize("current_status, new_status, expected", [
    ("triagem", "summary_generated", True),
    ("triagem", "matching", False),
    ("contract_signed", "in_progress", True),
    ("contract_signed", "triagem", False),
    ("completed", "in_progress", False),
    ("cancelled", "in_progress", False),
])
def test_is_valid_status_transition(case_service: CaseService, current_status, new_status, expected):
    """
    Testa a lógica de validação de transição de status.
    """
    assert case_service._is_valid_status_transition(current_status, new_status) is expected 

@pytest.mark.asyncio
async def test_update_case_status_success(case_service: CaseService, mock_supabase_client: MagicMock):
    """
    Testa o sucesso ao atualizar o status de um caso.
    """
    case_id = "case-to-update"
    user_id = "user-updater"
    current_case = {"id": case_id, "status": "contract_signed"}
    updated_case = {"id": case_id, "status": "in_progress"}

    # Mock para a busca inicial do caso e para o update
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = current_case
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [updated_case]
    
    with patch.object(case_service, '_create_case_event', new_callable=AsyncMock) as mock_create_event:
        result = await case_service.update_case_status(case_id, "in_progress", user_id)
        
        assert result == updated_case
        # Verifica se o evento foi criado
        mock_create_event.assert_called_once()

@pytest.mark.asyncio
async def test_update_case_status_not_found(case_service: CaseService, mock_supabase_client: MagicMock):
    """
    Testa a falha ao tentar atualizar um caso que não existe.
    """
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None
    
    with pytest.raises(ValueError, match="Caso non-existent-case não encontrado"):
        await case_service.update_case_status("non-existent-case", "new_status", "user-id")

@pytest.mark.asyncio
async def test_get_case_statistics_success(case_service: CaseService):
    """
    Testa o cálculo de estatísticas de casos.
    """
    user_id = "stats-user"
    cases_data = [
        {"id": "case-1", "status": "completed", "area": "Civil", "estimated_cost": 1000},
        {"id": "case-2", "status": "in_progress", "area": "Civil", "estimated_cost": 2000},
        {"id": "case-3", "status": "cancelled", "area": "Trabalhista", "estimated_cost": 500},
    ]
    
    # Mock para a função que busca os casos, pois ela já é testada
    with patch.object(case_service, 'get_user_cases', new_callable=AsyncMock) as mock_get_cases:
        mock_get_cases.return_value = cases_data
        
        stats = await case_service.get_case_statistics(user_id)
        
        assert stats["total_cases"] == 3
        assert stats["active_cases"] == 1
        assert stats["completed_cases"] == 1
        assert stats["success_rate"] == 50.0
        assert stats["by_area"]["Civil"] == 2
        assert stats["total_value"] == 3500 