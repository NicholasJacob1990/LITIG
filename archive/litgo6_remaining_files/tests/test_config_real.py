"""
Testes para o módulo de configuração real
"""
import pytest
import os
from unittest.mock import patch, Mock
from backend.config import Settings, settings, get_settings, get_supabase_client


def test_settings_defaults():
    """Testa valores padrão das configurações"""
    with patch.dict('os.environ', {}, clear=True):
        s = Settings()
        assert s.ENVIRONMENT == "development"
        assert s.DEBUG is False
        assert s.USE_DOCUSIGN is False
        assert s.FRONTEND_URL == "http://localhost:3000"
        assert s.CELERY_BROKER_URL == "redis://localhost:6379"


def test_settings_from_env():
    """Testa configurações a partir de variáveis de ambiente"""
    with patch.dict('os.environ', {
        'ENVIRONMENT': 'production',
        'DEBUG': 'true',
        'USE_DOCUSIGN': 'true',
        'SUPABASE_URL': 'https://test.supabase.co',
        'SUPABASE_SERVICE_KEY': 'test-key',
        'OPENAI_API_KEY': 'sk-test',
        'FRONTEND_URL': 'https://app.test.com'
    }):
        s = Settings()
        assert s.ENVIRONMENT == 'production'
        assert s.DEBUG is True
        assert s.USE_DOCUSIGN is True
        assert s.SUPABASE_URL == 'https://test.supabase.co'
        assert s.SUPABASE_SERVICE_KEY == 'test-key'
        assert s.OPENAI_API_KEY == 'sk-test'
        assert s.FRONTEND_URL == 'https://app.test.com'


def test_validate_supabase_config():
    """Testa validação de configuração do Supabase"""
    # Configuração válida
    with patch.dict('os.environ', {
        'SUPABASE_URL': 'https://test.supabase.co',
        'SUPABASE_SERVICE_KEY': 'test-key'
    }):
        s = Settings()
        assert s.validate_supabase_config() is True
    
    # Configuração inválida - falta URL
    with patch.dict('os.environ', {
        'SUPABASE_URL': '',
        'SUPABASE_SERVICE_KEY': 'test-key'
    }):
        s = Settings()
        assert s.validate_supabase_config() is False
    
    # Configuração inválida - falta chave
    with patch.dict('os.environ', {
        'SUPABASE_URL': 'https://test.supabase.co',
        'SUPABASE_SERVICE_KEY': ''
    }):
        s = Settings()
        assert s.validate_supabase_config() is False


def test_validate_docusign_config():
    """Testa validação de configuração do DocuSign"""
    # DocuSign desabilitado
    with patch.dict('os.environ', {'USE_DOCUSIGN': 'false'}):
        s = Settings()
        assert s.validate_docusign_config() is True
    
    # DocuSign habilitado com configuração completa
    with patch.dict('os.environ', {
        'USE_DOCUSIGN': 'true',
        'DOCUSIGN_API_KEY': 'key',
        'DOCUSIGN_ACCOUNT_ID': 'account',
        'DOCUSIGN_USER_ID': 'user',
        'DOCUSIGN_PRIVATE_KEY': 'private'
    }):
        s = Settings()
        assert s.validate_docusign_config() is True
    
    # DocuSign habilitado com configuração incompleta
    with patch.dict('os.environ', {
        'USE_DOCUSIGN': 'true',
        'DOCUSIGN_API_KEY': 'key',
        'DOCUSIGN_ACCOUNT_ID': '',  # Faltando
        'DOCUSIGN_USER_ID': 'user',
        'DOCUSIGN_PRIVATE_KEY': 'private'
    }):
        s = Settings()
        assert s.validate_docusign_config() is False


def test_get_docusign_auth_url():
    """Testa obtenção da URL de autorização do DocuSign"""
    # Ambiente de produção
    with patch.dict('os.environ', {'ENVIRONMENT': 'production'}):
        s = Settings()
        assert s.get_docusign_auth_url() == "https://account.docusign.com"
    
    # Ambiente de desenvolvimento
    with patch.dict('os.environ', {'ENVIRONMENT': 'development'}):
        s = Settings()
        assert s.get_docusign_auth_url() == "https://account-d.docusign.com"


def test_get_settings():
    """Testa função get_settings"""
    result = get_settings()
    assert isinstance(result, Settings)
    assert result == settings  # Deve retornar a instância global


def test_get_supabase_client():
    """Testa obtenção do cliente Supabase"""
    with patch.dict('os.environ', {
        'SUPABASE_URL': 'https://test.supabase.co',
        'SUPABASE_SERVICE_KEY': 'test-key'
    }):
        # Mock do create_client
        with patch('backend.config.create_client') as mock_create:
            mock_client = Mock()
            mock_create.return_value = mock_client
            
            # Limpar o cache global
            import backend.config
            backend.config._supabase_client = None
            
            # Primeira chamada deve criar o cliente
            client1 = get_supabase_client()
            assert client1 == mock_client
            mock_create.assert_called_once_with(
                'https://test.supabase.co',
                'test-key'
            )
            
            # Segunda chamada deve retornar o mesmo cliente (singleton)
            client2 = get_supabase_client()
            assert client2 == client1
            assert mock_create.call_count == 1  # Não deve criar novo cliente


def test_get_supabase_client_invalid_config():
    """Testa erro ao obter cliente Supabase com configuração inválida"""
    with patch.dict('os.environ', {
        'SUPABASE_URL': '',
        'SUPABASE_SERVICE_KEY': ''
    }):
        # Limpar o cache global
        import backend.config
        backend.config._supabase_client = None
        
        with pytest.raises(ValueError) as exc_info:
            get_supabase_client()
        
        assert "Configurações do Supabase incompletas" in str(exc_info.value) 