# tests/test_notify.py
import pytest
from unittest.mock import patch, AsyncMock
import os

from backend.services.notify_service import send_notifications_to_lawyers

@pytest.fixture
def mock_httpx_client():
    """Mock para o cliente HTTPX."""
    with patch('httpx.AsyncClient') as mock_client:
        mock_client.return_value.__aenter__.return_value.post = AsyncMock()
        yield mock_client

@pytest.mark.asyncio
async def test_send_notifications_success(mock_httpx_client):
    """
    Testa o envio de notificações com sucesso para advogados com push_token.
    """
    lawyer_ids = ["lawyer-1", "lawyer-2"]
    payload = {"case_id": "case-123", "headline": "Novo caso!"}
    
    mock_supabase_data = [
        {"id": "lawyer-1", "profile": {"push_token": "token-1", "email": "a@a.com"}},
        {"id": "lawyer-2", "profile": {"push_token": "token-2", "email": "b@b.com"}},
    ]

    # Mock das variáveis de ambiente do OneSignal
    with patch.dict(os.environ, {'ONESIGNAL_APP_ID': 'test-app-id', 'ONESIGNAL_API_KEY': 'test-api-key'}):
        with patch('backend.services.notify_service.get_supabase_client') as mock_get_supa:
            # Mock do cliente Supabase com estrutura correta
            mock_supa_client = mock_get_supa.return_value
            mock_table = mock_supa_client.table.return_value
            mock_select = mock_table.select.return_value
            mock_in = mock_select.in_.return_value
            mock_execute = mock_in.execute.return_value
            mock_execute.data = mock_supabase_data

            await send_notifications_to_lawyers(lawyer_ids, payload)

            # Verifica se o OneSignal foi chamado para ambos os tokens
            assert mock_httpx_client.return_value.__aenter__.return_value.post.call_count == 2

@pytest.mark.asyncio
async def test_send_notifications_email_fallback():
    """
    Testa o fallback para e-mail quando o push_token não está disponível.
    """
    lawyer_ids = ["lawyer-3"]
    payload = {"case_id": "case-456"}
    
    mock_supabase_data = [{"id": "lawyer-3", "profile": {"push_token": None, "email": "c@c.com"}}]

    # Mock das variáveis de ambiente do OneSignal
    with patch.dict(os.environ, {'ONESIGNAL_APP_ID': 'test-app-id', 'ONESIGNAL_API_KEY': 'test-api-key'}):
        with patch('backend.services.notify_service.get_supabase_client') as mock_get_supa:
            # Mock do cliente Supabase com estrutura correta
            mock_supa_client = mock_get_supa.return_value
            mock_table = mock_supa_client.table.return_value
            mock_select = mock_table.select.return_value
            mock_in = mock_select.in_.return_value
            mock_execute = mock_in.execute.return_value
            mock_execute.data = mock_supabase_data
            
            # Mock do envio de e-mail
            with patch('backend.services.notify_service._send_email_notification', new_callable=AsyncMock) as mock_send_email:
                await send_notifications_to_lawyers(lawyer_ids, payload)
                mock_send_email.assert_called_once()

@pytest.mark.asyncio
async def test_no_notifications_sent_if_no_ids():
    """
    Testa que nenhuma notificação é enviada se a lista de IDs de advogados estiver vazia.
    """
    with patch('backend.services.notify_service.get_supabase_client') as mock_get_supa:
        await send_notifications_to_lawyers([], {})
        mock_get_supa.assert_not_called()

@pytest.mark.asyncio
async def test_onesignal_api_error(mock_httpx_client):
    """
    Testa o tratamento de erro da API do OneSignal.
    """
    # Configura o mock para simular um erro HTTP
    mock_httpx_client.return_value.__aenter__.return_value.post.side_effect = Exception("OneSignal API Error")
    
    lawyer_ids = ["lawyer-1"]
    payload = {"case_id": "case-789"}
    mock_supabase_data = [{"id": "lawyer-1", "profile": {"push_token": "token-1"}}]
    
    with patch('backend.services.notify_service.get_supabase_client') as mock_get_supa:
        mock_supa_client = AsyncMock()
        mock_supa_client.table.return_value.select.return_value.in_.return_value.execute.return_value.data = mock_supabase_data
        mock_get_supa.return_value = mock_supa_client

        # O erro deve ser capturado e logado, não lançado
        await send_notifications_to_lawyers(lawyer_ids, payload) 