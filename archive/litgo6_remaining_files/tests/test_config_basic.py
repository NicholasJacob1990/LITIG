"""
Testes básicos para o módulo de configuração
"""
import pytest
import os
from unittest.mock import patch
from backend.config import Settings, get_settings


def test_settings_default_values():
    """Testa valores padrão das configurações"""
    settings = Settings()
    
    # Valores que devem ter padrões
    assert settings.app_name == "LITGO5 API"
    assert settings.environment in ["development", "staging", "production"]
    assert settings.debug in [True, False]
    assert settings.redis_url.startswith("redis://")


def test_settings_from_env_vars():
    """Testa carregamento de configurações de variáveis de ambiente"""
    with patch.dict(os.environ, {
        "APP_NAME": "Test API",
        "ENVIRONMENT": "test",
        "DEBUG": "false",
        "REDIS_URL": "redis://test:6379"
    }):
        settings = Settings()
        
        assert settings.app_name == "Test API"
        assert settings.environment == "test"
        assert settings.debug is False
        assert settings.redis_url == "redis://test:6379"


def test_get_settings_singleton():
    """Testa que get_settings retorna sempre a mesma instância"""
    settings1 = get_settings()
    settings2 = get_settings()
    
    assert settings1 is settings2
    assert isinstance(settings1, Settings)


def test_settings_required_fields():
    """Testa que campos obrigatórios estão presentes"""
    settings = Settings()
    
    # Campos que devem existir
    assert hasattr(settings, 'app_name')
    assert hasattr(settings, 'environment')
    assert hasattr(settings, 'debug')
    assert hasattr(settings, 'redis_url')


def test_settings_boolean_conversion():
    """Testa conversão de strings para boolean"""
    with patch.dict(os.environ, {"DEBUG": "true"}):
        settings = Settings()
        assert settings.debug is True
    
    with patch.dict(os.environ, {"DEBUG": "false"}):
        settings = Settings()
        assert settings.debug is False


def test_settings_string_fields():
    """Testa campos de string básicos"""
    settings = Settings()
    
    assert isinstance(settings.app_name, str)
    assert isinstance(settings.environment, str)
    assert isinstance(settings.redis_url, str)
    
    # Não devem estar vazios
    assert len(settings.app_name) > 0
    assert len(settings.environment) > 0
    assert len(settings.redis_url) > 0


def test_settings_validation():
    """Testa validação básica de configurações"""
    settings = Settings()
    
    # Environment deve ser um valor válido
    valid_envs = ["development", "staging", "production", "test"]
    assert settings.environment in valid_envs
    
    # Redis URL deve ter formato básico
    assert "redis://" in settings.redis_url


def test_settings_optional_fields():
    """Testa campos opcionais"""
    settings = Settings()
    
    # Estes campos podem estar None ou ter valores
    optional_fields = ['supabase_url', 'supabase_key', 'openai_api_key', 'anthropic_api_key']
    
    for field in optional_fields:
        if hasattr(settings, field):
            value = getattr(settings, field)
            # Se existe, deve ser string ou None
            assert value is None or isinstance(value, str) 