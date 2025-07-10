"""
Testes para o módulo de autenticação real
"""
import pytest
import os
from unittest.mock import Mock, patch, MagicMock
from fastapi import HTTPException
from backend.auth import get_current_user


@pytest.mark.asyncio
async def test_get_current_user_testing_mode():
    """Testa autenticação em modo de teste"""
    with patch.dict('os.environ', {'TESTING': 'true'}):
        # Recarregar o módulo para aplicar a variável de ambiente
        import importlib
        import backend.auth
        importlib.reload(backend.auth)
        
        user = await backend.auth.get_current_user(token='any-token')
        assert user['id'] == 'test-user-id'
        assert user['role'] == 'authenticated'


@pytest.mark.asyncio
async def test_get_current_user_valid_token():
    """Testa autenticação com token válido"""
    with patch.dict('os.environ', {'TESTING': 'false'}):
        # Mock do cliente Supabase
        mock_supabase = MagicMock()
        mock_response = MagicMock()
        mock_response.user = MagicMock()
        mock_response.user.id = 'user123'
        mock_response.user.email = 'test@example.com'
        mock_supabase.auth.get_user.return_value = mock_response
        
        with patch('backend.auth.get_supabase_client', return_value=mock_supabase):
            user = await get_current_user(token='valid-token')
            assert user['id'] == 'user123'
            assert user['email'] == 'test@example.com'
            mock_supabase.auth.get_user.assert_called_once_with('valid-token')


@pytest.mark.asyncio
async def test_get_current_user_no_user():
    """Testa autenticação com token inválido (sem usuário)"""
    with patch.dict('os.environ', {'TESTING': 'false'}):
        # Mock do cliente Supabase retornando None
        mock_supabase = MagicMock()
        mock_response = MagicMock()
        mock_response.user = None
        mock_supabase.auth.get_user.return_value = mock_response
        
        with patch('backend.auth.get_supabase_client', return_value=mock_supabase):
            with pytest.raises(HTTPException) as exc_info:
                await get_current_user(token='invalid-token')
            
            assert exc_info.value.status_code == 401
            assert exc_info.value.detail == "Could not validate credentials"


@pytest.mark.asyncio
async def test_get_current_user_auth_error():
    """Testa autenticação com erro no Supabase"""
    with patch.dict('os.environ', {'TESTING': 'false'}):
        # Mock do cliente Supabase lançando erro
        mock_supabase = MagicMock()
        # Criar um erro mock sem argumentos obrigatórios
        mock_error = Exception("Authentication error")
        mock_supabase.auth.get_user.side_effect = mock_error
        
        with patch('backend.auth.get_supabase_client', return_value=mock_supabase):
            with pytest.raises(HTTPException) as exc_info:
                await get_current_user(token='error-token')
            
            assert exc_info.value.status_code == 401


def test_supabase_client_creation():
    """Testa a criação do cliente Supabase"""
    with patch.dict('os.environ', {
        'SUPABASE_URL': 'https://test.supabase.co',
        'EXPO_PUBLIC_SUPABASE_ANON_KEY': 'test-key',
        'TESTING': 'false'
    }):
        # Importar o módulo para verificar se não há erros
        import importlib
        import backend.auth
        importlib.reload(backend.auth)
        
        assert backend.auth.SUPABASE_URL == 'https://test.supabase.co'
        assert backend.auth.SUPABASE_ANON_KEY == 'test-key'


def test_missing_env_vars():
    """Testa erro quando variáveis de ambiente estão faltando"""
    with patch.dict('os.environ', {
        'SUPABASE_URL': '',
        'EXPO_PUBLIC_SUPABASE_ANON_KEY': '',
        'TESTING': 'false'
    }, clear=True):
        # Deve lançar ValueError ao tentar importar
        with pytest.raises(ValueError) as exc_info:
            import importlib
            import backend.auth
            importlib.reload(backend.auth)
        
        assert "Variáveis de ambiente do Supabase" in str(exc_info.value) 