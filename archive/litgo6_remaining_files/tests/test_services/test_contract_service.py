"""
Testes para o ContractService (backend/services/contract_service.py)
"""
import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from datetime import datetime
from uuid import uuid4
import uuid

from backend.services.contract_service import ContractService
from backend.models import Contract, ContractStatus

@pytest.fixture
def mock_supabase_client():
    """Mock genérico para o cliente Supabase."""
    return MagicMock()

@pytest.fixture
def contract_service(mock_supabase_client):
    """
    Cria uma instância do ContractService e aplica patch no seu cliente supabase.
    """
    with patch('backend.services.contract_service.create_client', return_value=mock_supabase_client):
        service = ContractService()
    return service

@pytest.mark.asyncio
async def test_create_contract_success(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa a criação de um contrato com sucesso.
    """
    case_id = str(uuid4())
    lawyer_id = str(uuid4())
    client_id = str(uuid4())
    fee_model = {"type": "percentage", "value": 30}
    
    # Mock da resposta do insert
    mock_response = MagicMock()
    mock_response.error = None
    mock_response.data = [{
        "id": str(uuid4()),
        "case_id": case_id,
        "lawyer_id": lawyer_id,
        "client_id": client_id,
        "status": ContractStatus.PENDING_SIGNATURE.value,
        "fee_model": fee_model,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "signed_client": None,
        "signed_lawyer": None,
        "doc_url": None,
    }]
    mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_response

    new_contract = await contract_service.create_contract(case_id, lawyer_id, client_id, fee_model)
    
    assert isinstance(new_contract, Contract)
    assert new_contract.case_id == uuid.UUID(case_id)
    assert new_contract.status == ContractStatus.PENDING_SIGNATURE
    
    # Verifica a chamada ao Supabase
    insert_call = mock_supabase_client.table("contracts").insert.call_args
    assert insert_call.args[0]["case_id"] == case_id
    assert insert_call.args[0]["status"] == "pending_signature"

@pytest.mark.asyncio
async def test_get_contract_success(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa a busca de um contrato por ID com sucesso.
    """
    contract_id = str(uuid4())
    mock_response = MagicMock()
    mock_response.data = {
        "id": contract_id, "case_id": str(uuid4()), "lawyer_id": str(uuid4()), "client_id": str(uuid4()),
        "status": "pending_signature", "fee_model": {}, "created_at": datetime.now().isoformat(), "updated_at": datetime.now().isoformat()
    }
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_response

    contract = await contract_service.get_contract(contract_id)
    
    assert contract is not None
    assert contract.id == uuid.UUID(contract_id)

@pytest.mark.asyncio
async def test_get_contract_not_found(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa a busca de um contrato que não existe.
    """
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None
    
    contract = await contract_service.get_contract(str(uuid4()))
    assert contract is None

@pytest.mark.asyncio
async def test_get_user_contracts_success(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa a busca de contratos de um usuário.
    """
    user_id = str(uuid4())
    mock_response = MagicMock()
    mock_response.data = [
        {"id": str(uuid4()), "status": "active", "case_id": str(uuid4()), "lawyer_id": user_id, "client_id": str(uuid4()), "fee_model": {}, "created_at": datetime.now().isoformat(), "updated_at": datetime.now().isoformat()},
        {"id": str(uuid4()), "status": "pending_signature", "case_id": str(uuid4()), "lawyer_id": user_id, "client_id": str(uuid4()), "fee_model": {}, "created_at": datetime.now().isoformat(), "updated_at": datetime.now().isoformat()},
    ]
    mock_supabase_client.rpc.return_value.execute.return_value = mock_response
    
    contracts = await contract_service.get_user_contracts(user_id)
    
    assert len(contracts) == 2
    assert contracts[0].status == ContractStatus.ACTIVE

@pytest.mark.asyncio
async def test_sign_contract_both_parties(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa a assinatura do contrato por ambas as partes, o que deve mudar seu status para 'active'
    e disparar o log de auditoria 'won'.
    """
    contract_id = str(uuid4())
    case_id = str(uuid4())
    lawyer_id = str(uuid4())
    
    # Contrato antes da assinatura final
    contract_before = {
        "id": contract_id, "status": "pending_signature", "signed_client": datetime.now().isoformat(), "signed_lawyer": None,
        "case_id": case_id, "lawyer_id": lawyer_id, "client_id": str(uuid4()), "fee_model": {}, 
        "created_at": datetime.now().isoformat(), "updated_at": datetime.now().isoformat(), "doc_url": None
    }
    # Contrato após a assinatura do advogado
    contract_after = {**contract_before, "signed_lawyer": datetime.now().isoformat()}

    # Mock para a busca e o update
    mock_select_response = MagicMock(error=None, data=contract_before)
    mock_update_response = MagicMock(error=None, data=contract_after)
    
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_select_response
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.single.return_value.execute.return_value = mock_update_response
    
    with patch('backend.services.contract_service.AUDIT_LOGGER') as mock_audit_logger:
        result = await contract_service.sign_contract(contract_id, "lawyer")
        
        assert result.status == "active"
        assert result.signed_lawyer is not None
        
        # Verifica se o status foi atualizado para ACTIVE no banco
        update_calls = mock_supabase_client.table("contracts").update.call_args_list
        assert any(call.args[0].get("status") == ContractStatus.ACTIVE for call in update_calls)
        
        # Verifica o log de auditoria
        mock_audit_logger.info.assert_called_once_with("feedback", extra={"case": case_id, "lawyer": lawyer_id, "label": "won"})

@pytest.mark.asyncio
async def test_cancel_contract_success(contract_service: ContractService, mock_supabase_client: MagicMock):
    """
    Testa o cancelamento de um contrato e o log de auditoria 'lost'.
    """
    contract_id = str(uuid4())
    case_id = str(uuid4())
    lawyer_id = str(uuid4())
    
    contract_to_cancel = {
        "id": contract_id, "status": "active", "case_id": case_id, "lawyer_id": lawyer_id, "client_id": str(uuid4()),
        "fee_model": {}, "created_at": datetime.now().isoformat(), "updated_at": datetime.now().isoformat(), "doc_url": None
    }
    
    # Mock para a busca e o update
    mock_select_response = MagicMock(error=None, data=contract_to_cancel)
    # A resposta do update, mesmo com .single(), vem em uma lista
    mock_update_response = MagicMock(error=None, data=[{**contract_to_cancel, "status": "cancelled"}])

    mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_select_response
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.single.return_value.execute.return_value = mock_update_response

    with patch('backend.services.contract_service.AUDIT_LOGGER') as mock_audit_logger:
        await contract_service.cancel_contract(contract_id)
        
        # Verifica a chamada de update
        update_call = mock_supabase_client.table("contracts").update.call_args
        assert update_call.args[0]["status"] == ContractStatus.CANCELLED
        
        # Verifica o log de auditoria
        mock_audit_logger.info.assert_called_once_with("feedback", extra={"case": case_id, "lawyer": lawyer_id, "label": "lost"}) 