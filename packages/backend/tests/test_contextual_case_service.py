"""
Testes unitários para o serviço de casos contextuais
"""

import pytest
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime, timedelta
from uuid import uuid4

from services.contextual_case_service import ContextualCaseService, create_contextual_case_service

class TestContextualCaseService:
    """Testes para o ContextualCaseService"""
    
    @pytest.fixture
    def mock_supabase(self):
        """Mock do cliente Supabase"""
        mock = Mock()
        mock.table.return_value = mock
        mock.select.return_value = mock
        mock.eq.return_value = mock
        mock.single.return_value = mock
        mock.execute.return_value = mock
        return mock
    
    @pytest.fixture
    def service(self, mock_supabase):
        """Instância do serviço com Supabase mockado"""
        return ContextualCaseService(mock_supabase)
    
    @pytest.fixture
    def sample_case_data(self):
        """Dados de exemplo de um caso"""
        return {
            "id": str(uuid4()),
            "client_id": str(uuid4()),
            "lawyer_id": str(uuid4()),
            "title": "Caso de Teste",
            "status": "pending_assignment",
            "created_at": datetime.now().isoformat(),
            "allocation_type": "platform_match_direct",
            "match_score": 85.5,
            "context_metadata": {
                "distance": 10.5,
                "estimated_value": 5000,
                "conversion_rate": 90.0
            }
        }
    
    @pytest.fixture
    def sample_user_data(self):
        """Dados de exemplo de um usuário"""
        return {
            "id": str(uuid4()),
            "full_name": "João Silva",
            "specialization": "Direito Civil",
            "rating": 4.5
        }
    
    @pytest.mark.asyncio
    async def test_get_contextual_case_data_success(self, service, mock_supabase, sample_case_data):
        """Testa busca de dados contextuais com sucesso"""
        # Setup
        case_id = sample_case_data["id"]
        user_id = sample_case_data["client_id"]
        
        mock_supabase.data = sample_case_data
        
        # Mock dos métodos privados
        with patch.object(service, '_determine_user_role', return_value='client'), \
             patch.object(service, '_build_contextual_data', return_value=sample_case_data), \
             patch.object(service, '_generate_contextual_kpis', return_value=[
                 {"icon": "🎯", "label": "Match Score", "value": "85%"}
             ]), \
             patch.object(service, '_generate_contextual_actions', return_value={
                 "primary_action": {"label": "Aceitar Caso", "action": "accept_case"},
                 "secondary_actions": []
             }), \
             patch.object(service, '_generate_contextual_highlight', return_value={
                 "text": "🎯 Match direto para você",
                 "color": "blue"
             }):
            
            # Execute
            result = await service.get_contextual_case_data(case_id, user_id)
            
            # Assert
            assert result is not None
            assert result["case"] == sample_case_data
            assert result["user_role"] == "client"
            assert len(result["kpis"]) == 1
            assert result["kpis"][0]["icon"] == "🎯"
            assert result["actions"]["primary_action"]["label"] == "Aceitar Caso"
            assert result["highlight"]["text"] == "🎯 Match direto para você"
    
    @pytest.mark.asyncio
    async def test_get_contextual_case_data_case_not_found(self, service, mock_supabase):
        """Testa busca de dados contextuais com caso não encontrado"""
        # Setup
        case_id = str(uuid4())
        user_id = str(uuid4())
        
        mock_supabase.data = None
        
        # Execute & Assert
        with pytest.raises(ValueError, match="Caso não encontrado"):
            await service.get_contextual_case_data(case_id, user_id)
    
    def test_determine_user_role_client(self, service):
        """Testa determinação de papel do usuário como cliente"""
        # Setup
        case_data = {"client_id": "user123", "lawyer_id": "lawyer456"}
        user_id = "user123"
        
        # Execute
        result = service._determine_user_role(case_data, user_id)
        
        # Assert
        assert result == "client"
    
    def test_determine_user_role_lawyer(self, service):
        """Testa determinação de papel do usuário como advogado"""
        # Setup
        case_data = {"client_id": "client123", "lawyer_id": "user456"}
        user_id = "user456"
        
        # Execute
        result = service._determine_user_role(case_data, user_id)
        
        # Assert
        assert result == "lawyer"
    
    def test_determine_user_role_partner(self, service):
        """Testa determinação de papel do usuário como parceiro"""
        # Setup
        case_data = {"client_id": "client123", "lawyer_id": "lawyer456", "partner_id": "user789"}
        user_id = "user789"
        
        # Execute
        result = service._determine_user_role(case_data, user_id)
        
        # Assert
        assert result == "partner"
    
    def test_determine_user_role_delegator(self, service):
        """Testa determinação de papel do usuário como delegador"""
        # Setup
        case_data = {"client_id": "client123", "lawyer_id": "lawyer456", "delegated_by": "user789"}
        user_id = "user789"
        
        # Execute
        result = service._determine_user_role(case_data, user_id)
        
        # Assert
        assert result == "delegator"
    
    def test_determine_user_role_viewer(self, service):
        """Testa determinação de papel do usuário como visualizador"""
        # Setup
        case_data = {"client_id": "client123", "lawyer_id": "lawyer456"}
        user_id = "other_user"
        
        # Execute
        result = service._determine_user_role(case_data, user_id)
        
        # Assert
        assert result == "viewer"
    
    @pytest.mark.asyncio
    async def test_build_contextual_data_platform_match_direct(self, service):
        """Testa construção de dados contextuais para match direto"""
        # Setup
        case_data = {
            "allocation_type": "platform_match_direct",
            "match_score": 95.0,
            "response_deadline": "2025-01-31T18:00:00Z",
            "context_metadata": {
                "distance": 5.2,
                "estimated_value": 8500,
                "conversion_rate": 92.5
            }
        }
        user_role = "lawyer"
        
        # Mock do método _enrich_direct_match_data
        with patch.object(service, '_enrich_direct_match_data', return_value={
            "response_time_left": "2h 30min",
            "distance": 5.2,
            "estimated_value": 8500,
            "conversion_rate": 92.5
        }):
            
            # Execute
            result = await service._build_contextual_data(case_data, user_role)
            
            # Assert
            assert result["allocation_type"] == "platform_match_direct"
            assert result["match_score"] == 95.0
            assert result["response_time_left"] == "2h 30min"
            assert result["distance"] == 5.2
            assert result["estimated_value"] == 8500
            assert result["conversion_rate"] == 92.5
    
    @pytest.mark.asyncio
    async def test_enrich_direct_match_data(self, service):
        """Testa enriquecimento de dados para match direto"""
        # Setup
        case_data = {
            "response_deadline": (datetime.now() + timedelta(hours=2)).isoformat(),
            "context_metadata": {
                "distance": 12.5,
                "estimated_value": 10000,
                "conversion_rate": 88.0
            }
        }
        
        # Mock do método _calculate_response_time_left
        with patch.object(service, '_calculate_response_time_left', return_value="2h 0min"):
            
            # Execute
            result = await service._enrich_direct_match_data(case_data)
            
            # Assert
            assert result["response_time_left"] == "2h 0min"
            assert result["distance"] == 12.5
            assert result["estimated_value"] == 10000
            assert result["conversion_rate"] == 88.0
    
    def test_calculate_response_time_left_valid_deadline(self, service):
        """Testa cálculo de tempo restante com deadline válido"""
        # Setup
        deadline = (datetime.now() + timedelta(hours=2, minutes=30)).isoformat()
        
        # Execute
        result = service._calculate_response_time_left(deadline)
        
        # Assert
        assert "2h 30min" in result or "2h 29min" in result  # Margem para execução
    
    def test_calculate_response_time_left_expired(self, service):
        """Testa cálculo de tempo restante com deadline expirado"""
        # Setup
        deadline = (datetime.now() - timedelta(hours=1)).isoformat()
        
        # Execute
        result = service._calculate_response_time_left(deadline)
        
        # Assert
        assert result == "Expirado"
    
    def test_calculate_response_time_left_no_deadline(self, service):
        """Testa cálculo de tempo restante sem deadline"""
        # Setup
        deadline = None
        
        # Execute
        result = service._calculate_response_time_left(deadline)
        
        # Assert
        assert result == "Sem prazo"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_kpis_platform_match_direct(self, service):
        """Testa geração de KPIs para match direto"""
        # Setup
        case_data = {"status": "pending_assignment"}
        contextual_data = {
            "allocation_type": "platform_match_direct",
            "match_score": 94.0,
            "distance": 12.0,
            "estimated_value": 8500,
            "response_time_left": "2h 15min"
        }
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_kpis(case_data, contextual_data, user_role)
        
        # Assert
        assert len(result) == 4
        assert result[0]["icon"] == "🎯"
        assert result[0]["label"] == "Match Score"
        assert result[0]["value"] == "94.0%"
        assert result[1]["icon"] == "📍"
        assert result[1]["label"] == "Distância"
        assert result[1]["value"] == "12.0km"
        assert result[2]["icon"] == "💰"
        assert result[2]["label"] == "Valor"
        assert result[2]["value"] == "R$ 8.500,00"
        assert result[3]["icon"] == "⏱️"
        assert result[3]["label"] == "SLA"
        assert result[3]["value"] == "2h 15min"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_kpis_internal_delegation(self, service):
        """Testa geração de KPIs para delegação interna"""
        # Setup
        case_data = {"status": "assigned"}
        contextual_data = {
            "allocation_type": "internal_delegation",
            "delegated_by_name": "Dr. Silva",
            "deadline_days": 15,
            "hours_budgeted": 40,
            "hourly_rate": 150
        }
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_kpis(case_data, contextual_data, user_role)
        
        # Assert
        assert len(result) == 4
        assert result[0]["icon"] == "👨‍💼"
        assert result[0]["label"] == "Delegado por"
        assert result[0]["value"] == "Dr. Silva"
        assert result[1]["icon"] == "⏰"
        assert result[1]["label"] == "Prazo"
        assert result[1]["value"] == "15 dias"
        assert result[2]["icon"] == "📈"
        assert result[2]["label"] == "Horas Orçadas"
        assert result[2]["value"] == "40h"
        assert result[3]["icon"] == "💼"
        assert result[3]["label"] == "Valor/h"
        assert result[3]["value"] == "R$ 150"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_actions_platform_match_direct(self, service):
        """Testa geração de ações para match direto"""
        # Setup
        case_data = {"status": "pending_assignment"}
        contextual_data = {"allocation_type": "platform_match_direct"}
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_actions(case_data, contextual_data, user_role)
        
        # Assert
        assert result["primary_action"]["label"] == "Aceitar Caso"
        assert result["primary_action"]["action"] == "accept_case"
        assert len(result["secondary_actions"]) == 2
        assert result["secondary_actions"][0]["label"] == "Ver Perfil do Cliente"
        assert result["secondary_actions"][0]["action"] == "view_client_profile"
        assert result["secondary_actions"][1]["label"] == "Solicitar Informações"
        assert result["secondary_actions"][1]["action"] == "request_info"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_actions_internal_delegation(self, service):
        """Testa geração de ações para delegação interna"""
        # Setup
        case_data = {"status": "assigned"}
        contextual_data = {"allocation_type": "internal_delegation"}
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_actions(case_data, contextual_data, user_role)
        
        # Assert
        assert result["primary_action"]["label"] == "Registrar Horas"
        assert result["primary_action"]["action"] == "log_hours"
        assert len(result["secondary_actions"]) == 2
        assert result["secondary_actions"][0]["label"] == "Atualizar Status"
        assert result["secondary_actions"][0]["action"] == "update_status"
        assert result["secondary_actions"][1]["label"] == "Reportar Progresso"
        assert result["secondary_actions"][1]["action"] == "report_progress"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_highlight_platform_match_direct(self, service):
        """Testa geração de destaque para match direto"""
        # Setup
        case_data = {"status": "pending_assignment"}
        contextual_data = {"allocation_type": "platform_match_direct"}
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_highlight(case_data, contextual_data, user_role)
        
        # Assert
        assert result["text"] == "🎯 Match direto para você"
        assert result["color"] == "blue"
    
    @pytest.mark.asyncio
    async def test_generate_contextual_highlight_internal_delegation(self, service):
        """Testa geração de destaque para delegação interna"""
        # Setup
        case_data = {"status": "assigned"}
        contextual_data = {
            "allocation_type": "internal_delegation",
            "delegated_by_name": "Dr. Silva"
        }
        user_role = "lawyer"
        
        # Execute
        result = await service._generate_contextual_highlight(case_data, contextual_data, user_role)
        
        # Assert
        assert result["text"] == "👨‍💼 Delegado por Dr. Silva"
        assert result["color"] == "orange"
    
    @pytest.mark.asyncio
    async def test_set_case_allocation_platform_match_direct(self, service, mock_supabase):
        """Testa definição de alocação para match direto"""
        # Setup
        case_id = str(uuid4())
        allocation_type = "platform_match_direct"
        metadata = {
            "match_score": 95.0,
            "response_deadline": "2025-01-31T18:00:00Z",
            "distance": 10.5
        }
        
        mock_supabase.data = [{"id": case_id, "allocation_type": allocation_type}]
        
        # Execute
        result = await service.set_case_allocation(case_id, allocation_type, metadata)
        
        # Assert
        assert result["id"] == case_id
        assert result["allocation_type"] == allocation_type
        
        # Verificar se update foi chamado
        mock_supabase.table.assert_called_with("cases")
        mock_supabase.update.assert_called_once()
        mock_supabase.eq.assert_called_with("id", case_id)
    
    def test_create_contextual_case_service_factory(self):
        """Testa factory de criação do serviço"""
        # Execute
        service = create_contextual_case_service()
        
        # Assert
        assert isinstance(service, ContextualCaseService)
        assert service.supabase is not None


if __name__ == "__main__":
    pytest.main([__file__]) 